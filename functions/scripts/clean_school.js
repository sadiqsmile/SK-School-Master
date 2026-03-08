/*
  DANGEROUS: Deletes Firestore data for a school (and optionally Auth users).

  What it deletes (when --confirm is provided):
  1) schools/{schoolId}  (recursively, including ALL subcollections)
  2) users/{uid} documents where users.schoolId == schoolId (recursively, incl. users/{uid}/notifications/*)
  3) parentPhones/* mappings where parentPhones.schoolId == schoolId (optional, default ON)
  4) Firebase Auth users for the deleted user UIDs (optional)

  Why you might want this:
  - To wipe dummy/test data and start fresh.

  Safety:
  - By default, this runs in DRY RUN mode and prints what it would delete.
  - It will NOT delete anything unless you pass --confirm.
  - You can preserve specific UIDs using --preserveUids.

  Requirements:
    - Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON
      OR pass --credentials <path>

  Examples (PowerShell):
    $env:GOOGLE_APPLICATION_CREDENTIALS = "functions/.secrets/serviceAccountKey.json"

    # Dry run (recommended first)
    node functions/scripts/clean_school.js --schoolId hong7xk2

    # Actually delete Firestore school data + user docs for that school
    node functions/scripts/clean_school.js --schoolId hong7xk2 --confirm

    # Also delete the Auth accounts (teacher/parent accounts etc)
    node functions/scripts/clean_school.js --schoolId hong7xk2 --confirm --deleteAuthUsers

    # Preserve an admin UID (do not delete its /users doc or Auth account)
    node functions/scripts/clean_school.js --schoolId hong7xk2 --confirm --deleteAuthUsers --preserveUids ydb1zCU3yEUY0ZuMab0ye0MqMnp2
*/

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function getArg(name) {
  const argv = process.argv.slice(2);
  const idx = argv.indexOf(name);
  if (idx === -1) return undefined;
  const v = argv[idx + 1];
  if (!v || v.startsWith('--')) return '';
  return v;
}

function hasFlag(name) {
  return process.argv.slice(2).includes(name);
}

function requireNonEmpty(value, label) {
  const v = String(value || '').trim();
  if (!v) throw new Error(`Missing required ${label}.`);
  return v;
}

function resolveCredPath() {
  const credPathArg = getArg('--credentials');
  const credPathEnv = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const credPath = String(credPathArg || credPathEnv || '').trim();
  if (!credPath) {
    throw new Error(
      'Missing service account credentials. Set GOOGLE_APPLICATION_CREDENTIALS or pass --credentials <path-to-json>.'
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

function parseCsv(raw) {
  const s = String(raw || '').trim();
  if (!s) return [];
  return s
    .split(',')
    .map((p) => p.trim())
    .filter(Boolean);
}

async function recursiveDelete(ref) {
  // firebase-admin v12+ exposes Firestore from @google-cloud/firestore.
  // In modern versions, recursiveDelete exists on the Firestore instance.
  const db = ref.firestore || admin.firestore();
  if (typeof db.recursiveDelete === 'function') {
    return db.recursiveDelete(ref);
  }

  throw new Error(
    'recursiveDelete() is not available in this firebase-admin version. ' +
      'Alternative: use Firebase CLI firestore delete, or upgrade firebase-admin.'
  );
}

async function deleteAuthUserIfExists(uid) {
  try {
    await admin.auth().deleteUser(uid);
    return { deleted: true };
  } catch (err) {
    if (err && err.code === 'auth/user-not-found') return { deleted: false };
    throw err;
  }
}

async function main() {
  const schoolId = requireNonEmpty(getArg('--schoolId'), '--schoolId');

  const confirm = hasFlag('--confirm');
  const deleteAuthUsers = hasFlag('--deleteAuthUsers');

  // Default ON; use --keepParentPhones to skip.
  const deleteParentPhones = !hasFlag('--keepParentPhones');

  const preserveUids = new Set(parseCsv(getArg('--preserveUids')));

  // Credentials + init
  const resolvedCredPath = resolveCredPath();
  const credJson = JSON.parse(fs.readFileSync(resolvedCredPath, 'utf8'));

  admin.initializeApp({
    credential: admin.credential.cert(credJson),
  });

  const db = admin.firestore();

  console.log('Target schoolId:', schoolId);
  console.log('Mode:', confirm ? 'DELETE (confirmed)' : 'DRY RUN (no changes)');
  console.log('Options:');
  console.log('- deleteAuthUsers:', deleteAuthUsers);
  console.log('- deleteParentPhones:', deleteParentPhones);
  console.log('- preserveUids:', preserveUids.size ? Array.from(preserveUids).join(', ') : '(none)');
  console.log('');

  // 1) Find users in this school
  const usersSnap = await db.collection('users').where('schoolId', '==', schoolId).get();
  const userUids = usersSnap.docs.map((d) => d.id);
  const deletableUserUids = userUids.filter((uid) => !preserveUids.has(uid));

  // 2) Find parentPhones mappings for this school
  let parentPhonesSnap = null;
  if (deleteParentPhones) {
    parentPhonesSnap = await db.collection('parentPhones').where('schoolId', '==', schoolId).get();
  }

  console.log('Would delete:');
  console.log(`- schools/${schoolId} (recursive)`);
  console.log(`- users (schoolId == ${schoolId}): ${deletableUserUids.length} doc(s) recursive`);
  if (deleteParentPhones) {
    console.log(`- parentPhones (schoolId == ${schoolId}): ${parentPhonesSnap.size} doc(s)`);
  } else {
    console.log('- parentPhones: (kept)');
  }
  if (deleteAuthUsers) {
    console.log(`- Firebase Auth users: ${deletableUserUids.length} uid(s)`);
  } else {
    console.log('- Firebase Auth users: (kept)');
  }

  if (!confirm) {
    console.log('\nDry run complete. Re-run with --confirm to actually delete.');
    return;
  }

  // DELETE PHASE
  // A) Delete school subtree
  console.log(`\nDeleting Firestore: schools/${schoolId} (recursive)...`);
  await recursiveDelete(db.collection('schools').doc(schoolId));
  console.log('Deleted school subtree.');

  // B) Delete user docs (and their subcollections)
  console.log(`\nDeleting Firestore: users/* for schoolId=${schoolId} ...`);
  for (const uid of deletableUserUids) {
    const userRef = db.collection('users').doc(uid);
    await recursiveDelete(userRef);
    process.stdout.write('.');
  }
  console.log(`\nDeleted ${deletableUserUids.length} user doc(s).`);

  // C) Delete parentPhones mappings
  if (deleteParentPhones) {
    console.log(`\nDeleting Firestore: parentPhones where schoolId=${schoolId} ...`);
    for (const doc of parentPhonesSnap.docs) {
      await doc.ref.delete();
      process.stdout.write('.');
    }
    console.log(`\nDeleted ${parentPhonesSnap.size} parentPhones mapping doc(s).`);
  }

  // D) Delete Auth users
  if (deleteAuthUsers) {
    console.log(`\nDeleting Firebase Auth users (${deletableUserUids.length}) ...`);
    let deletedCount = 0;
    let missingCount = 0;
    for (const uid of deletableUserUids) {
      const r = await deleteAuthUserIfExists(uid);
      if (r.deleted) deletedCount += 1;
      else missingCount += 1;
      process.stdout.write('.');
    }
    console.log(`\nAuth delete complete. deleted=${deletedCount}, notFound=${missingCount}`);
  }

  console.log('\nDone. Your Firebase data for this school has been cleaned.');
  console.log('Next: bootstrap core docs again using seed_school.js (or create a school from the Super Admin UI).');
}

main().catch((err) => {
  console.error('Clean school failed:', err && err.message ? err.message : err);
  process.exitCode = 1;
});
