/*
  Verify that the core Firestore docs required by security rules and app routing exist.

  Uses admin credentials (service account key).

  Example (PowerShell):
    $env:GOOGLE_APPLICATION_CREDENTIALS = "functions/.secrets/serviceAccountKey.json"
    node functions/scripts/verify_core_docs.js --schoolId hong7xk2 --adminUid ydb1z...
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

async function main() {
  const schoolId = requireNonEmpty(getArg("--schoolId"), "--schoolId");
  const adminUid = requireNonEmpty(getArg("--adminUid"), "--adminUid");

  const resolvedCredPath = resolveCredPath();
  const credJson = JSON.parse(fs.readFileSync(resolvedCredPath, "utf8"));

  admin.initializeApp({
    credential: admin.credential.cert(credJson),
  });

  const db = admin.firestore();

  const refs = {
    school: db.collection("schools").doc(schoolId),
    modules: db.collection("schools").doc(schoolId).collection("settings").doc("modules"),
    user: db.collection("users").doc(adminUid),
  };

  const [schoolSnap, modulesSnap, userSnap] = await Promise.all([
    refs.school.get(),
    refs.modules.get(),
    refs.user.get(),
  ]);

  const problems = [];

  if (!schoolSnap.exists) problems.push(`Missing: ${refs.school.path}`);
  if (!modulesSnap.exists) problems.push(`Missing: ${refs.modules.path}`);

  if (!userSnap.exists) {
    problems.push(`Missing: ${refs.user.path}`);
  } else {
    const data = userSnap.data() || {};
    const role = String(data.role || "");
    const userSchoolId = String(data.schoolId || "");
    if (role !== "admin") problems.push(`Expected users/{uid}.role == "admin" (got "${role}")`);
    if (userSchoolId !== schoolId) {
      problems.push(`Expected users/{uid}.schoolId == "${schoolId}" (got "${userSchoolId}")`);
    }
  }

  if (problems.length) {
    console.error("Core docs verification FAILED:\n- " + problems.join("\n- "));
    process.exitCode = 2;
    return;
  }

  console.log("Core docs verification OK:");
  console.log("-", refs.school.path);
  console.log("-", refs.modules.path);
  console.log("-", refs.user.path);
}

main().catch((err) => {
  console.error("Verify failed:", err && err.message ? err.message : err);
  process.exitCode = 1;
});
