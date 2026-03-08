/*
  Assign classes/sections to an existing teacher profile.

  Why this exists:
  - Teachers need `assignmentKeys` in their teacher profile doc for Firestore rules.
  - This script updates ONLY Firestore (no password resets).

  Requires admin credentials:
    $env:GOOGLE_APPLICATION_CREDENTIALS = "functions/.secrets/serviceAccountKey.json"

  Usage:
    node functions/scripts/assign_teacher.js --schoolId hong7xk2 --uid <teacherUid> --assign "8:A"

  Or lookup by email:
    node functions/scripts/assign_teacher.js --schoolId hong7xk2 --email "t@x.com" --assign "8:A,9:B"

  --assign format:
    "<classId>:<sectionId>,<classId>:<sectionId>"
*/

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function getArg(name) {
  const argv = process.argv.slice(2);
  const idx = argv.indexOf(name);
  if (idx === -1) return undefined;
  const v = argv[idx + 1];
  if (!v || v.startsWith("--")) return "";
  return v;
}

function requireNonEmpty(value, label) {
  const v = String(value || "").trim();
  if (!v) throw new Error(`Missing required ${label}.`);
  return v;
}

function normalizeEmail(input) {
  return String(input || "").trim().toLowerCase();
}

function sanitizeFirestoreId(input) {
  const trimmed = String(input || "").trim();
  if (!trimmed) return "";
  const safe = trimmed.replace(/[^a-zA-Z0-9]+/g, "_");
  return safe.replace(/_+/g, "_").replace(/^_+|_+$/g, "");
}

function classKeyFrom(classId, sectionId) {
  const c = sanitizeFirestoreId(classId);
  const s = sanitizeFirestoreId(sectionId);
  return `class_${c}_${s}`;
}

function parseAssignments(assignRaw) {
  const raw = String(assignRaw || "").trim();
  if (!raw) return [];

  const out = [];
  for (const part of raw.split(",")) {
    const p = part.trim();
    if (!p) continue;
    const [classIdRaw, sectionIdRaw] = p.split(":");
    const classId = String(classIdRaw || "").trim();
    const sectionId = String(sectionIdRaw || "").trim();
    if (!classId || !sectionId) continue;
    out.push({ classId, sectionId });
  }
  return out;
}

function resolveCredPath() {
  const credPathArg = getArg("--credentials");
  const credPathEnv = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const credPath = String(credPathArg || credPathEnv || "").trim();
  if (!credPath) {
    throw new Error(
      "Missing service account credentials. Set GOOGLE_APPLICATION_CREDENTIALS or pass --credentials <path-to-json>."
    );
  }

  const resolved = path.isAbsolute(credPath)
    ? credPath
    : path.resolve(process.cwd(), credPath);

  if (!fs.existsSync(resolved)) {
    throw new Error(`Service account file not found: ${resolved}`);
  }
  return resolved;
}

function normalizeExistingClasses(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const classId = String(item.classId || item.classID || item["classId"] || "").trim();
    const sectionId = String(item.sectionId || item.section || item["sectionId"] || item["section"] || "").trim();
    const className = String(item.className || "");
    const sectionName = String(item.sectionName || "");
    if (!classId && !sectionId && !className.trim() && !sectionName.trim()) continue;
    out.push({ classId, sectionId, className, sectionName });
  }
  return out;
}

async function tryFetchNames(db, schoolId, classId, sectionId) {
  try {
    const classRef = db.collection("schools").doc(schoolId).collection("classes").doc(classId);
    const sectionRef = classRef.collection("sections").doc(sectionId);

    const [classSnap, sectionSnap] = await Promise.all([classRef.get(), sectionRef.get()]);

    const className = classSnap.exists ? String((classSnap.data() || {}).name || "") : "";
    const sectionName = sectionSnap.exists ? String((sectionSnap.data() || {}).name || "") : "";

    return { className, sectionName };
  } catch (_) {
    return { className: "", sectionName: "" };
  }
}

async function main() {
  const schoolId = requireNonEmpty(getArg("--schoolId"), "--schoolId");
  const uidArg = String(getArg("--uid") || "").trim();
  const emailArg = normalizeEmail(getArg("--email"));

  const assignRaw = requireNonEmpty(getArg("--assign"), "--assign");
  const desiredPairs = parseAssignments(assignRaw);
  if (!desiredPairs.length) {
    throw new Error('No valid assignments parsed from --assign. Expected like "8:A,9:B"');
  }

  const resolvedCredPath = resolveCredPath();
  const credJson = JSON.parse(fs.readFileSync(resolvedCredPath, "utf8"));

  admin.initializeApp({
    credential: admin.credential.cert(credJson),
  });

  let uid = uidArg;
  if (!uid) {
    if (!emailArg) throw new Error("Provide --uid or --email");
    const user = await admin.auth().getUserByEmail(emailArg);
    uid = user.uid;
  }

  const db = admin.firestore();
  const teacherRef = db.collection("schools").doc(schoolId).collection("teachers").doc(uid);
  const snap = await teacherRef.get();
  const existing = snap.exists ? (snap.data() || {}) : {};

  const existingClasses = normalizeExistingClasses(existing.classes);

  // Build a map for quick dedupe.
  const seen = new Set(existingClasses.map((c) => `${c.classId}::${c.sectionId}`));

  for (const p of desiredPairs) {
    const key = `${p.classId}::${p.sectionId}`;
    if (seen.has(key)) continue;

    const { className, sectionName } = await tryFetchNames(db, schoolId, p.classId, p.sectionId);
    existingClasses.push({
      classId: p.classId,
      sectionId: p.sectionId,
      className,
      sectionName,
    });
    seen.add(key);
  }

  const assignmentKeys = Array.from(
    new Set(
      existingClasses
        .map((c) => classKeyFrom(c.classId, c.sectionId))
        .filter((k) => k && k !== "class__")
    )
  );

  const now = admin.firestore.FieldValue.serverTimestamp();

  await teacherRef.set(
    {
      teacherUid: uid,
      classes: existingClasses,
      assignmentKeys,
      updatedAt: now,
    },
    { merge: true }
  );

  console.log("Teacher assignments updated:");
  console.log("- teacherDoc:", teacherRef.path);
  console.log("- classesCount:", existingClasses.length);
  console.log("- assignmentKeys:", assignmentKeys);
}

main().catch((err) => {
  console.error("Assign teacher failed:", err && err.message ? err.message : err);
  process.exitCode = 1;
});
