/*
  Firestore bootstrap / seeding script for SK School Master.

  What it does (merge-safe):
  - Ensures a school doc exists:      schools/{schoolId}
  - Ensures module toggles doc exists: schools/{schoolId}/settings/modules
  - Ensures an admin user profile doc: users/{adminUid}
  - Ensures an academic year doc:     schools/{schoolId}/academicYears/{academicYearId}
  - Sets activeAcademicYearId on the school doc
  - Ensures a default grading system: schools/{schoolId}/gradingSystems/default

  SECURITY NOTE:
  - This script needs admin credentials. Do NOT commit service account keys.
  - Put your key JSON at: functions/.secrets/serviceAccountKey.json

  Example (PowerShell):
    $env:GOOGLE_APPLICATION_CREDENTIALS = "functions/.secrets/serviceAccountKey.json"
    node functions/scripts/seed_school.js --schoolId hong7xk2 --adminUid ydb1z... --schoolName "Hong Public School" --academicYearId 2025-2026
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

function hasFlag(name) {
  return process.argv.slice(2).includes(name);
}

function requireNonEmpty(value, label) {
  const v = String(value || "").trim();
  if (!v) {
    throw new Error(`Missing required ${label}.`);
  }
  return v;
}

function parseAcademicYear(academicYearId) {
  const parts = String(academicYearId || "").trim().split("-");
  if (parts.length !== 2) return { startYear: null, endYear: null };
  const startYear = Number.parseInt(parts[0], 10);
  const endYear = Number.parseInt(parts[1], 10);
  return {
    startYear: Number.isFinite(startYear) ? startYear : null,
    endYear: Number.isFinite(endYear) ? endYear : null,
  };
}

function defaultModules() {
  return {
    teachers: true,
    students: true,
    attendance: true,
    exams: true,
    parents: true,
    fees: true,
    homework: true,
    messages: true,
  };
}

function defaultGradingSystem() {
  return {
    name: "Default",
    passPercent: 33.0,
    bands: [
      { grade: "A+", minPercent: 90 },
      { grade: "A", minPercent: 80 },
      { grade: "B", minPercent: 70 },
      { grade: "C", minPercent: 60 },
      { grade: "D", minPercent: 50 },
      { grade: "F", minPercent: 0 },
    ],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function isAlreadyExistsError(err) {
  // Firestore gRPC status ALREADY_EXISTS = 6
  if (!err) return false;
  if (err.code === 6) return true;
  const msg = String(err.message || "");
  return msg.includes("ALREADY_EXISTS") || msg.toLowerCase().includes("already exists");
}

async function createOrMerge(ref, createData, mergeData) {
  try {
    await ref.create(createData);
    console.log("Created:", ref.path);
  } catch (err) {
    if (!isAlreadyExistsError(err)) throw err;
    await ref.set(mergeData, { merge: true });
    console.log("Updated:", ref.path);
  }
}

async function main() {
  const schoolId = requireNonEmpty(getArg("--schoolId"), "--schoolId");
  const adminUid = requireNonEmpty(getArg("--adminUid"), "--adminUid");

  const schoolNameRaw = getArg("--schoolName");
  const schoolName = String(schoolNameRaw || "").trim() || "School";

  const academicYearIdRaw = getArg("--academicYearId");
  const academicYearId = String(academicYearIdRaw || "").trim() || "2025-2026";

  const dryRun = hasFlag("--dryRun");

  const schoolPath = `schools/${schoolId}`;
  const modulesPath = `schools/${schoolId}/settings/modules`;
  const userPath = `users/${adminUid}`;
  const yearPath = `schools/${schoolId}/academicYears/${academicYearId}`;
  const gradingPath = `schools/${schoolId}/gradingSystems/default`;

  if (dryRun) {
    console.log("[dryRun] Would upsert the following documents:");
    console.log("-", schoolPath);
    console.log("-", modulesPath);
    console.log("-", userPath);
    console.log("-", yearPath);
    console.log("-", gradingPath);
    return;
  }

  // Credentials
  const credPathArg = getArg("--credentials");
  const credPathEnv = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const credPath = String(credPathArg || credPathEnv || "").trim();

  if (!credPath) {
    throw new Error(
      "Missing service account credentials. Set GOOGLE_APPLICATION_CREDENTIALS or pass --credentials <path-to-json>."
    );
  }

  const resolvedCredPath = path.isAbsolute(credPath)
    ? credPath
    : path.resolve(process.cwd(), credPath);

  if (!fs.existsSync(resolvedCredPath)) {
    throw new Error(`Service account file not found: ${resolvedCredPath}`);
  }

  const credJson = JSON.parse(fs.readFileSync(resolvedCredPath, "utf8"));

  admin.initializeApp({
    credential: admin.credential.cert(credJson),
  });

  const db = admin.firestore();

  const schoolRef = db.collection("schools").doc(schoolId);
  const modulesRef = schoolRef.collection("settings").doc("modules");
  const userRef = db.collection("users").doc(adminUid);
  const yearRef = schoolRef.collection("academicYears").doc(academicYearId);
  const gradingRef = schoolRef.collection("gradingSystems").doc("default");

  const { startYear, endYear } = parseAcademicYear(academicYearId);

  const now = admin.firestore.FieldValue.serverTimestamp();

  const schoolCreate = {
    name: schoolName,
    schoolId,
    activeAcademicYearId: academicYearId,
    activeAcademicYearUpdatedAt: now,
    createdAt: now,
    updatedAt: now,
  };
  const schoolMerge = {
    name: schoolName,
    schoolId,
    activeAcademicYearId: academicYearId,
    activeAcademicYearUpdatedAt: now,
    updatedAt: now,
  };

  const userCreate = {
    role: "admin",
    schoolId,
    createdAt: now,
    updatedAt: now,
  };
  const userMerge = {
    // Keep role/schoolId correct; merge-safe.
    role: "admin",
    schoolId,
    updatedAt: now,
  };

  const yearCreate = {
    id: academicYearId,
    ...(startYear == null ? null : { startYear }),
    ...(endYear == null ? null : { endYear }),
    createdAt: now,
  };
  const yearMerge = {
    id: academicYearId,
    ...(startYear == null ? null : { startYear }),
    ...(endYear == null ? null : { endYear }),
  };

  const modulesMerge = {
    ...defaultModules(),
    updatedAt: now,
  };

  const gradingMerge = defaultGradingSystem();

  await createOrMerge(schoolRef, schoolCreate, schoolMerge);
  await modulesRef.set(modulesMerge, { merge: true });
  console.log("Upserted:", modulesRef.path);

  await createOrMerge(userRef, userCreate, userMerge);
  await createOrMerge(yearRef, yearCreate, yearMerge);

  // Grading system: merge-safe so schools can customize later.
  await gradingRef.set(gradingMerge, { merge: true });
  console.log("Upserted:", gradingRef.path);

  console.log("\nDone. Core Firestore docs are now bootstrapped.");
}

main().catch((err) => {
  console.error("Seed failed:", err && err.message ? err.message : err);
  process.exitCode = 1;
});
