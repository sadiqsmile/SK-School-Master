/*
  Create (or reset) a teacher account + Firestore teacher profile.

  This script mirrors the behavior of the deployed callable function
  `createOrResetTeacherAccount`, but runs directly using Admin SDK.

  Requires admin credentials:
    - Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON.

  Usage (PowerShell example):
    $env:GOOGLE_APPLICATION_CREDENTIALS = "functions/.secrets/serviceAccountKey.json"
    node functions/scripts/create_teacher.js --schoolId hong7xk2 --name "Ali" --email "ali@gmail.com" --phone "+91 9xxxx" --assign "5:A,6:B"

  Notes on assignments:
    --assign is optional.
    Format: "<classId>:<sectionId>,<classId>:<sectionId>"
    Example: "5:A,6:B" will create assignmentKeys ["class_5_A","class_6_B"].
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
  const e = String(input || "").trim().toLowerCase();
  return e;
}

function normalizePhone(input) {
  return String(input || "").replace(/[^0-9]/g, "");
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
  if (!raw) return { classes: [], assignmentKeys: [] };

  const classes = [];
  const keys = new Set();

  for (const part of raw.split(",")) {
    const p = part.trim();
    if (!p) continue;
    const [classIdRaw, sectionIdRaw] = p.split(":");
    const classId = String(classIdRaw || "").trim();
    const sectionId = String(sectionIdRaw || "").trim();
    if (!classId || !sectionId) continue;

    classes.push({ classId, sectionId, className: "", sectionName: "" });
    const k = classKeyFrom(classId, sectionId);
    if (k !== "class__") keys.add(k);
  }

  return { classes, assignmentKeys: Array.from(keys) };
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

function isAlreadyExistsError(err) {
  if (!err) return false;
  if (err.code === 6) return true; // gRPC ALREADY_EXISTS
  const msg = String(err.message || "");
  return msg.includes("ALREADY_EXISTS") || msg.toLowerCase().includes("already exists");
}

async function createOrMerge(ref, createData, mergeData) {
  try {
    await ref.create(createData);
    return { created: true };
  } catch (err) {
    if (!isAlreadyExistsError(err)) throw err;
    await ref.set(mergeData, { merge: true });
    return { created: false };
  }
}

async function main() {
  const schoolId = requireNonEmpty(getArg("--schoolId"), "--schoolId");
  const name = requireNonEmpty(getArg("--name"), "--name");
  const email = normalizeEmail(requireNonEmpty(getArg("--email"), "--email"));
  const phoneDigits = normalizePhone(getArg("--phone"));
  const subjectsRaw = String(getArg("--subjects") || "").trim();
  const assignRaw = getArg("--assign");

  const subjects = subjectsRaw
    ? subjectsRaw.split(",").map((s) => s.trim()).filter(Boolean)
    : [];

  const { classes, assignmentKeys } = parseAssignments(assignRaw);

  const resolvedCredPath = resolveCredPath();
  const credJson = JSON.parse(fs.readFileSync(resolvedCredPath, "utf8"));

  admin.initializeApp({
    credential: admin.credential.cert(credJson),
  });

  const now = admin.firestore.FieldValue.serverTimestamp();

  // Same temp password rule as callable function: first 6 chars of email.
  const emailSeed = (email || "") + "000000";
  const temporaryPassword = emailSeed.slice(0, 6);

  // Create or reset Auth user
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(userRecord.uid, {
      password: temporaryPassword,
      displayName: name || userRecord.displayName || undefined,
    });
  } catch (err) {
    if (err && err.code === "auth/user-not-found") {
      userRecord = await admin.auth().createUser({
        email,
        password: temporaryPassword,
        displayName: name || undefined,
      });
    } else {
      throw err;
    }
  }

  const uid = userRecord.uid;

  // Claims
  await admin.auth().setCustomUserClaims(uid, {
    role: "teacher",
    schoolId,
  });

  const db = admin.firestore();

  // users/{uid}
  const userRef = db.collection("users").doc(uid);
  await createOrMerge(
    userRef,
    {
      role: "teacher",
      schoolId,
      phone: phoneDigits,
      email,
      name,
      mustChangePassword: true,
      createdAt: now,
      updatedAt: now,
    },
    {
      role: "teacher",
      schoolId,
      phone: phoneDigits,
      email,
      name,
      mustChangePassword: true,
      updatedAt: now,
    }
  );

  // schools/{schoolId}/teachers/{uid}
  const teacherRef = db.collection("schools").doc(schoolId).collection("teachers").doc(uid);
  await teacherRef.set(
    {
      teacherUid: uid,
      name,
      nameLower: name.trim().toLowerCase(),
      email,
      emailLower: email.trim().toLowerCase(),
      phone: phoneDigits,
      subjects,
      classes,
      assignmentKeys,
      updatedAt: now,
      createdAt: now,
    },
    { merge: true }
  );

  console.log("Teacher created/updated:");
  console.log("- uid:", uid);
  console.log("- email:", email);
  console.log("- temporaryPassword:", temporaryPassword);
  console.log("- teacherDoc:", teacherRef.path);
  console.log("- assignmentKeys:", assignmentKeys);
}

main().catch((err) => {
  console.error("Create teacher failed:", err && err.message ? err.message : err);
  process.exitCode = 1;
});
