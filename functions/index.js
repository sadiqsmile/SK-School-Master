const admin = require("firebase-admin");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const crypto = require("crypto");

setGlobalOptions({
  region: "us-central1",
  // Use the App Engine default service account for Firebase workloads.
  // This can help avoid token signing permission issues seen with the default
  // compute service account on Gen 2.
  serviceAccount: "sk-school-master@appspot.gserviceaccount.com",
});

admin.initializeApp();

function normalizePhone(input) {
  const digits = String(input || "").replace(/[^0-9]/g, "");
  if (digits.length < 10) {
    throw new HttpsError("invalid-argument", "Invalid phone number");
  }
  return digits;
}

function parentEmailFromPhoneDigits(digits) {
  // Deterministic email from phone digits.
  return `p${digits}@parents.schoolapp.local`;
}

function randomPassword() {
  // Firebase Auth email/password requires >= 6 chars. We don't use this for login
  // in the parent flow (we use custom token), but the user must exist in Auth.
  return crypto.randomBytes(24).toString("base64url");
}

function normalizePin(input) {
  const pin = String(input || "").trim();
  if (!/^[0-9]{4,12}$/.test(pin)) {
    throw new HttpsError("invalid-argument", "PIN must be 4 to 12 digits");
  }
  return pin;
}

function hashPin(pin, salt) {
  return crypto.createHash("sha256").update(`${salt}:${pin}`).digest("hex");
}

exports.createOrResetParentAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const data = request.data || {};
  const schoolId = String(data.schoolId || "").trim();
  const action = String(data.action || "create").trim(); // create | reset
  const parentName = String(data.parentName || "").trim();
  const phoneDigits = normalizePhone(data.phone);
  const studentId = data.studentId ? String(data.studentId) : "";

  if (!schoolId) {
    throw new HttpsError("invalid-argument", "schoolId is required");
  }

  // Authorize caller.
  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  const callerRole = String((callerDoc.data() || {}).role || "");
  const callerSchoolId = String((callerDoc.data() || {}).schoolId || "");

  if (callerRole !== "admin" && callerRole !== "superAdmin") {
    throw new HttpsError("permission-denied", "Only admin/superAdmin can manage parent accounts");
  }

  if (callerRole === "admin" && callerSchoolId !== schoolId) {
    throw new HttpsError("permission-denied", "Admin can only manage parents for their own school");
  }

  const email = parentEmailFromPhoneDigits(phoneDigits);
  const defaultPin = phoneDigits.slice(-4);
  const pinSalt = crypto.randomBytes(16).toString("hex");
  const pinHash = hashPin(defaultPin, pinSalt);

  // Create or reset the Auth user.
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);

    if (action === "reset" || action === "create") {
      // Keep an unguessable password (parent doesn't use email/password login).
      await admin.auth().updateUser(userRecord.uid, {
        password: randomPassword(),
        displayName: parentName || userRecord.displayName || undefined,
      });
    }
  } catch (err) {
    if (err && err.code === "auth/user-not-found") {
      userRecord = await admin.auth().createUser({
        email,
        password: randomPassword(),
        displayName: parentName || undefined,
      });
    } else {
      throw err;
    }
  }

  // Ensure claims and profile doc exist.
  await admin.auth().setCustomUserClaims(userRecord.uid, {
    role: "parent",
    schoolId,
  });

  await admin.firestore().collection("users").doc(userRecord.uid).set(
    {
      role: "parent",
      schoolId,
      phone: phoneDigits,
      name: parentName,
      mustChangePassword: true,
      pinSalt,
      pinHash,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // Fast lookup for parent login by phone.
  await admin
    .firestore()
    .collection("parentPhones")
    .doc(phoneDigits)
    .set(
      {
        uid: userRecord.uid,
        schoolId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  // Optionally link student to parent.
  if (studentId) {
    await admin
      .firestore()
      .collection("schools")
      .doc(schoolId)
      .collection("students")
      .doc(studentId)
      .set(
        {
          parentUid: userRecord.uid,
          parentPhone: phoneDigits,
          parentName,
        },
        { merge: true }
      );
  }

  return {
    uid: userRecord.uid,
    email,
    defaultPasswordHint: "last4",
    mustChangePassword: true,
  };
});

exports.parentLogin = onCall(async (request) => {
  const data = request.data || {};
  const phoneDigits = normalizePhone(data.phone);
  const pin = normalizePin(data.pin);

  // Lookup uid by phone.
  const mappingDoc = await admin
    .firestore()
    .collection("parentPhones")
    .doc(phoneDigits)
    .get();
  const mapping = mappingDoc.data() || {};
  const uid = String(mapping.uid || "");
  if (!uid) {
    throw new HttpsError("not-found", "Parent account not found");
  }

  const userDoc = await admin.firestore().collection("users").doc(uid).get();
  const userData = userDoc.data() || {};
  if (String(userData.role || "") !== "parent") {
    throw new HttpsError("permission-denied", "Not a parent account");
  }

  const salt = String(userData.pinSalt || "");
  const expected = String(userData.pinHash || "");
  if (!salt || !expected) {
    throw new HttpsError("failed-precondition", "Parent PIN not initialized");
  }

  const actual = hashPin(pin, salt);
  if (actual !== expected) {
    throw new HttpsError("permission-denied", "Invalid PIN");
  }

  const schoolId = String(userData.schoolId || "");
  const mustChangePassword = (userData.mustChangePassword || false) === true;

  let token;
  try {
    token = await admin.auth().createCustomToken(uid, {
      role: "parent",
      schoolId,
    });
  } catch (err) {
    // Common Gen2 misconfiguration: missing iam.serviceAccounts.signBlob.
    const msg = String((err && err.message) || err || "");
    if (msg.includes("iam.serviceAccounts.signBlob") || msg.includes("signBlob")) {
      throw new HttpsError(
        "failed-precondition",
        "Server is not configured for parent login yet. Please contact the app admin."
      );
    }
    throw err;
  }

  return {
    token,
    mustChangePassword,
  };
});

exports.changeParentPin = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const data = request.data || {};
  const newPin = normalizePin(data.newPin);

  const uid = request.auth.uid;
  const userDocRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userDocRef.get();
  const userData = userDoc.data() || {};

  if (String(userData.role || "") !== "parent") {
    throw new HttpsError("permission-denied", "Only parents can change PIN here");
  }

  const pinSalt = crypto.randomBytes(16).toString("hex");
  const pinHash = hashPin(newPin, pinSalt);

  await userDocRef.set(
    {
      pinSalt,
      pinHash,
      mustChangePassword: false,
      passwordChangedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true };
});
