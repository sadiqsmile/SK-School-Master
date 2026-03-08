const admin = require("firebase-admin");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const crypto = require("crypto");

setGlobalOptions({
  region: "us-central1",
  // Use the App Engine default service account for Firebase workloads.
  // This can help avoid token signing permission issues seen with the default
  // compute service account on Gen 2.
  serviceAccount: "sk-school-master@appspot.gserviceaccount.com",
});

// IMPORTANT:
// Firestore triggers (Gen2/Eventarc) must be deployed in the same region as the
// Firestore database location. Your project is using a Firestore location in
// `asia-south1` (see deploy errors mentioning Eventarc triggers in asia-south1).
const FIRESTORE_REGION = "asia-south1";

admin.initializeApp();

function safeInt(input) {
  const n = Number(input);
  if (!Number.isFinite(n)) return 0;
  return Math.trunc(n);
}

function readAttendanceCounts(docData) {
  const empty = { present: 0, absent: 0, late: 0, leave: 0, total: 0 };
  if (!docData || typeof docData !== "object") return empty;
  const counts = docData.counts;
  if (!counts || typeof counts !== "object") return empty;
  return {
    present: safeInt(counts.present),
    absent: safeInt(counts.absent),
    late: safeInt(counts.late),
    leave: safeInt(counts.leave),
    total: safeInt(counts.total),
  };
}

function diffCounts(before, after) {
  return {
    present: safeInt(after.present) - safeInt(before.present),
    absent: safeInt(after.absent) - safeInt(before.absent),
    late: safeInt(after.late) - safeInt(before.late),
    leave: safeInt(after.leave) - safeInt(before.leave),
    total: safeInt(after.total) - safeInt(before.total),
  };
}

function todayKeyUtc() {
  const d = new Date();
  const y = String(d.getUTCFullYear()).padStart(4, "0");
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

async function incrementDoc(ref, delta) {
  // Helper for compact increment updates.
  const inc = admin.firestore.FieldValue.increment;
  const payload = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  for (const [k, v] of Object.entries(delta || {})) {
    if (!v) continue;
    payload[k] = inc(v);
  }

  await ref.set(payload, { merge: true });
}

// ----------------------------
// Aggregated / indexed counters
// ----------------------------

exports.onStudentCreated = onDocumentCreated(
  { document: "schools/{schoolId}/students/{studentId}", region: FIRESTORE_REGION },
  async (event) => {
    const { schoolId } = event.params;
    const schoolRef = admin.firestore().collection("schools").doc(schoolId);

    await Promise.all([
      incrementDoc(schoolRef, { totalStudents: 1 }),
      incrementDoc(admin.firestore().collection("platform").doc("config"), {
        totalStudents: 1,
      }),
    ]);
  }
);

exports.onStudentDeleted = onDocumentDeleted(
  { document: "schools/{schoolId}/students/{studentId}", region: FIRESTORE_REGION },
  async (event) => {
    const { schoolId } = event.params;
    const schoolRef = admin.firestore().collection("schools").doc(schoolId);

    await Promise.all([
      incrementDoc(schoolRef, { totalStudents: -1 }),
      incrementDoc(admin.firestore().collection("platform").doc("config"), {
        totalStudents: -1,
      }),
    ]);
  }
);

exports.onTeacherCreated = onDocumentCreated(
  { document: "schools/{schoolId}/teachers/{teacherId}", region: FIRESTORE_REGION },
  async (event) => {
    const { schoolId } = event.params;
    const schoolRef = admin.firestore().collection("schools").doc(schoolId);
    await incrementDoc(schoolRef, { totalTeachers: 1 });
  }
);

exports.onTeacherDeleted = onDocumentDeleted(
  { document: "schools/{schoolId}/teachers/{teacherId}", region: FIRESTORE_REGION },
  async (event) => {
    const { schoolId } = event.params;
    const schoolRef = admin.firestore().collection("schools").doc(schoolId);
    await incrementDoc(schoolRef, { totalTeachers: -1 });
  }
);

exports.onClassCreated = onDocumentCreated(
  { document: "schools/{schoolId}/classes/{classId}", region: FIRESTORE_REGION },
  async (event) => {
    const { schoolId } = event.params;
    const schoolRef = admin.firestore().collection("schools").doc(schoolId);
    await incrementDoc(schoolRef, { totalClasses: 1 });
  }
);

exports.onClassDeleted = onDocumentDeleted(
  { document: "schools/{schoolId}/classes/{classId}", region: FIRESTORE_REGION },
  async (event) => {
    const { schoolId } = event.params;
    const schoolRef = admin.firestore().collection("schools").doc(schoolId);
    await incrementDoc(schoolRef, { totalClasses: -1 });
  }
);

// ----------------------------
// Attendance summary index
// ----------------------------

// Updates a school-level "latest attendance summary" whenever a class meta lock
// is written under:
// schools/{schoolId}/attendance/{dateKey}/meta/{classKey}
//
// We index the totals onto the school doc so dashboards can load quickly.
exports.onAttendanceMetaWritten = onDocumentWritten(
  { document: "schools/{schoolId}/attendance/{dateKey}/meta/{classKey}", region: FIRESTORE_REGION },
  async (event) => {
    const { schoolId, dateKey } = event.params;

    const beforeExists = event.data.before.exists;
    const afterExists = event.data.after.exists;

    const beforeCounts = beforeExists
      ? readAttendanceCounts(event.data.before.data())
      : { present: 0, absent: 0, late: 0, leave: 0, total: 0 };
    const afterCounts = afterExists
      ? readAttendanceCounts(event.data.after.data())
      : { present: 0, absent: 0, late: 0, leave: 0, total: 0 };

    const delta = diffCounts(beforeCounts, afterCounts);
    const classDelta = !beforeExists && afterExists ? 1 : beforeExists && !afterExists ? -1 : 0;

    // If nothing changed, do nothing.
    if (
      !delta.present &&
      !delta.absent &&
      !delta.late &&
      !delta.leave &&
      !delta.total &&
      !classDelta
    ) {
      return;
    }

    const schoolRef = admin.firestore().collection("schools").doc(schoolId);

    // Keep the "latest" attendance summary on the school doc.
    // We only mutate the school doc for:
    // - the same dateKey as currently stored
    // - OR a newer dateKey (lexicographic compare works for YYYY-MM-DD)
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(schoolRef);
      const data = snap.data() || {};

      const currentKey = String(data.attendanceLatestDateKey || "");
      const hasKey = currentKey.length === 10;

      const shouldStartNew = !hasKey || dateKey > currentKey;
      const shouldUpdateSame = hasKey && dateKey === currentKey;

      if (!shouldStartNew && !shouldUpdateSame) {
        // Older date update; ignore to keep dashboard focused on the latest day.
        return;
      }

      if (shouldStartNew) {
        // Initialize with this class' counts (and then future writes for same date will add deltas).
        if (!afterExists) {
          // Newer date but deletion event (shouldn't happen in normal flow); ignore.
          return;
        }

        tx.set(
          schoolRef,
          {
            attendanceLatestDateKey: dateKey,
            attendanceLatest: {
              dateKey,
              present: afterCounts.present,
              absent: afterCounts.absent,
              late: afterCounts.late,
              leave: afterCounts.leave,
              total: afterCounts.total,
              classesMarked: 1,
            },
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        return;
      }

      // Same dateKey: apply deltas with atomic increments.
      const inc = admin.firestore.FieldValue.increment;
      tx.set(
        schoolRef,
        {
          attendanceLatest: {
            dateKey,
            present: inc(delta.present),
            absent: inc(delta.absent),
            late: inc(delta.late),
            leave: inc(delta.leave),
            total: inc(delta.total),
            classesMarked: inc(classDelta),
          },
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    // Optional: persist per-day totals doc for historical reporting.
    // This is safe and cheap: 1 doc per day per school.
    const dailyRef = admin
      .firestore()
      .collection("schools")
      .doc(schoolId)
      .collection("analytics")
      .doc("attendance_daily")
      .collection("days")
      .doc(dateKey);

    const dailyDelta = {
      present: delta.present,
      absent: delta.absent,
      late: delta.late,
      leave: delta.leave,
      total: delta.total,
      classesMarked: classDelta,
    };

    await dailyRef.set(
      {
        dateKey,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...Object.fromEntries(
          Object.entries(dailyDelta).map(([k, v]) => [k, admin.firestore.FieldValue.increment(v)])
        ),
      },
      { merge: true }
    );

    // If the day is "today" in UTC, also write a convenient pointer doc.
    // This can be used by clients who want a stable path.
    const todayKey = todayKeyUtc();
    if (dateKey === todayKey) {
      const todayRef = admin
        .firestore()
        .collection("schools")
        .doc(schoolId)
        .collection("analytics")
        .doc("attendance_today");

      await todayRef.set(
        {
          dateKey,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  }
);

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

function normalizeEmail(input) {
  const email = String(input || "").trim().toLowerCase();
  // Simple sanity check (Auth will validate further).
  if (!email.includes("@") || email.length < 6) {
    throw new HttpsError("invalid-argument", "Invalid email");
  }
  return email;
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

// ----------------------------
// Maintenance: recompute counters
// ----------------------------

exports.recomputeSchoolCounters = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const data = request.data || {};
  const schoolId = String(data.schoolId || "").trim();
  if (!schoolId) {
    throw new HttpsError("invalid-argument", "schoolId is required");
  }

  // Authorize caller: superAdmin only.
  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  const callerRole = String((callerDoc.data() || {}).role || "");
  const callerEmail = String((request.auth.token && request.auth.token.email) || "").toLowerCase();

  const isSuper = callerRole === "superAdmin" || callerEmail === "sadiq.smile@gmail.com";
  if (!isSuper) {
    throw new HttpsError("permission-denied", "Only superAdmin can run maintenance");
  }

  const schoolRef = admin.firestore().collection("schools").doc(schoolId);
  const studentsCol = schoolRef.collection("students");
  const teachersCol = schoolRef.collection("teachers");
  const classesCol = schoolRef.collection("classes");

  async function countCol(colRef) {
    // Prefer server-side count aggregation when available.
    try {
      const agg = await colRef.count().get();
      return safeInt(agg.data().count);
    } catch (_) {
      const snap = await colRef.get();
      return safeInt(snap.size);
    }
  }

  const [students, teachers, classes] = await Promise.all([
    countCol(studentsCol),
    countCol(teachersCol),
    countCol(classesCol),
  ]);

  await schoolRef.set(
    {
      totalStudents: students,
      totalTeachers: teachers,
      totalClasses: classes,
      countersRecomputedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    schoolId,
    totalStudents: students,
    totalTeachers: teachers,
    totalClasses: classes,
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

// ---------------------------------------------------------------------------
// Teacher Accounts (email/password)
// ---------------------------------------------------------------------------

exports.createOrResetTeacherAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const data = request.data || {};
  const schoolId = String(data.schoolId || "").trim();
  const action = String(data.action || "create").trim(); // create | reset
  const teacherName = String(data.teacherName || "").trim();
  const email = normalizeEmail(data.email);
  const phoneDigits = normalizePhone(data.phone);
  const teacherId = data.teacherId ? String(data.teacherId) : "";

  if (!schoolId) {
    throw new HttpsError("invalid-argument", "schoolId is required");
  }

  // Authorize caller.
  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  const callerRole = String((callerDoc.data() || {}).role || "");
  const callerSchoolId = String((callerDoc.data() || {}).schoolId || "");

  if (callerRole !== "admin" && callerRole !== "superAdmin") {
    throw new HttpsError(
      "permission-denied",
      "Only admin/superAdmin can manage teacher accounts"
    );
  }

  if (callerRole === "admin" && callerSchoolId !== schoolId) {
    throw new HttpsError(
      "permission-denied",
      "Admin can only manage teachers for their own school"
    );
  }

  // Temporary password rule: first 6 characters of the email.
  // Example: skschool@gmail.com -> skscho
  // Firebase Auth requires >= 6 chars.
  const emailSeed = (email || "") + "000000";
  const temporaryPassword = emailSeed.slice(0, 6);

  // Create or reset the Auth user.
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
    if (action === "reset" || action === "create") {
      await admin.auth().updateUser(userRecord.uid, {
        password: temporaryPassword,
        displayName: teacherName || userRecord.displayName || undefined,
      });
    }
  } catch (err) {
    if (err && err.code === "auth/user-not-found") {
      userRecord = await admin.auth().createUser({
        email,
        password: temporaryPassword,
        displayName: teacherName || undefined,
      });
    } else {
      throw err;
    }
  }

  // Claims + user doc.
  await admin.auth().setCustomUserClaims(userRecord.uid, {
    role: "teacher",
    schoolId,
  });

  await admin.firestore().collection("users").doc(userRecord.uid).set(
    {
      role: "teacher",
      schoolId,
      phone: phoneDigits,
      email,
      name: teacherName,
      mustChangePassword: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // Optionally link to teacher profile doc.
  if (teacherId) {
    await admin
      .firestore()
      .collection("schools")
      .doc(schoolId)
      .collection("teachers")
      .doc(teacherId)
      .set(
        {
          teacherUid: userRecord.uid,
          name: teacherName,
          email,
          phone: phoneDigits,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
  }

  return {
    uid: userRecord.uid,
    mustChangePassword: true,
    temporaryPassword,
  };
});
