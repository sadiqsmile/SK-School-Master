const admin = require("firebase-admin");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const crypto = require("crypto");
const zlib = require("zlib");
const readline = require("readline");
const { once } = require("events");
const { finished } = require("stream/promises");
const {
  asCell,
  safeJson,
  getSheetsClient,
  ensureSheetTabs,
  writeTabValues,
} = require("./google_sheets_sync");

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

function dateKeyDaysAgoUtc(daysAgo) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - safeInt(daysAgo));
  const y = String(d.getUTCFullYear()).padStart(4, "0");
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
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

function readNum(v) {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string") {
    const n = Number(v);
    return Number.isFinite(n) ? n : 0;
  }
  return 0;
}

function prettyDateKey(dateKey) {
  // dateKey expected: YYYY-MM-DD
  const s = String(dateKey || "").trim();
  return s || "";
}

async function upsertParentNotification({
  parentUid,
  notificationId,
  payload,
  markUnread,
}) {
  const uid = String(parentUid || "").trim();
  const id = String(notificationId || "").trim();
  if (!uid || !id) return;

  const db = admin.firestore();
  const ref = db.collection("users").doc(uid).collection("notifications").doc(id);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);

    if (!snap.exists) {
      const base = {
        ...(payload || {}),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        readAt: null,
      };
      tx.set(ref, base, { merge: true });
      return;
    }

    const update = {
      ...(payload || {}),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(markUnread === true ? { readAt: null } : null),
    };
    tx.set(ref, update, { merge: true });
  });
}

function computeStudentRiskV1({
  attendancePercent30d,
  marksPercentLatest,
  feesPendingAmount,
}) {
  const attendance = readNum(attendancePercent30d);
  const marks = readNum(marksPercentLatest);
  const pending = readNum(feesPendingAmount);

  // Conditions
  const lowAttendance = attendance > 0 && attendance < 75;
  const lowMarks = marks > 0 && marks < 40;
  const feePending = pending > 0;

  const reasons = [];
  if (lowAttendance) reasons.push("low_attendance");
  if (lowMarks) reasons.push("low_marks");
  if (feePending) reasons.push("fee_pending");

  const conditions = reasons.length;

  // As requested: if 2–3 conditions are true → HIGH.
  const riskLevel = conditions >= 2 ? "HIGH" : conditions === 1 ? "MEDIUM" : "LOW";

  // Simple risk score (0–100) used for sorting.
  // (Not ML; deterministic heuristic.)
  let riskScore = 0;
  if (lowAttendance) riskScore += 40 + Math.min(30, Math.max(0, 75 - attendance));
  if (lowMarks) riskScore += 40 + Math.min(30, Math.max(0, 40 - marks));
  if (feePending) riskScore += 30;
  riskScore = Math.max(0, Math.min(100, Math.round(riskScore)));

  const topPerformer = marks >= 80 && attendance >= 90;

  return {
    riskLevel,
    riskScore,
    reasons,
    lowAttendance,
    lowMarks,
    feePending,
    topPerformer,
  };
}

async function authorizeSchoolAdminOrSuperAdmin({ request, schoolId }) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  const callerRole = String((callerDoc.data() || {}).role || "");
  const callerSchoolId = String((callerDoc.data() || {}).schoolId || "");

  const isSuperAdmin = callerRole === "superAdmin" || (request.auth.token && request.auth.token.superAdmin === true);

  if (!isSuperAdmin && callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admin/superAdmin can run analytics");
  }
  if (!isSuperAdmin && callerSchoolId !== schoolId) {
    throw new HttpsError("permission-denied", "Admin can only run analytics for their own school");
  }

  return { callerUid, callerRole, isSuperAdmin };
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

// Track number of schools on the platform dashboard.
// Note: this counts school root documents (not subcollections).
exports.onSchoolCreated = onDocumentCreated(
  { document: "schools/{schoolId}", region: FIRESTORE_REGION },
  async (_event) => {
    await incrementDoc(admin.firestore().collection("platform").doc("config"), {
      totalSchools: 1,
    });
  }
);

exports.onSchoolDeleted = onDocumentDeleted(
  { document: "schools/{schoolId}", region: FIRESTORE_REGION },
  async (_event) => {
    await incrementDoc(admin.firestore().collection("platform").doc("config"), {
      totalSchools: -1,
    });
  }
);

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
    const { schoolId, dateKey, classKey } = event.params;

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

    // Emit an in-app notification when attendance is first marked for a class.
    // We intentionally only notify on CREATE (not on updates) to avoid spamming.
    if (!beforeExists && afterExists) {
      const afterData = event.data.after.data() || {};
      const markedBy = String(afterData.markedBy || "");

      const notifId = `attendance_${dateKey}_${classKey}`;
      const notifRef = admin
        .firestore()
        .collection("schools")
        .doc(schoolId)
        .collection("notifications")
        .doc(notifId);

      const bodyParts = [];
      if (afterCounts.present) bodyParts.push(`${afterCounts.present} present`);
      if (afterCounts.absent) bodyParts.push(`${afterCounts.absent} absent`);
      if (afterCounts.late) bodyParts.push(`${afterCounts.late} late`);
      if (afterCounts.leave) bodyParts.push(`${afterCounts.leave} leave`);
      const body = bodyParts.length ? bodyParts.join(", ") : "Attendance submitted";

      await notifRef.set(
        {
          type: "attendance_marked",
          title: "Attendance marked",
          body,
          schoolId,
          dateKey,
          classKey,
          markedBy: markedBy || null,
          counts: {
            present: afterCounts.present,
            absent: afterCounts.absent,
            late: afterCounts.late,
            leave: afterCounts.leave,
            total: afterCounts.total,
          },
          audience: {
            roles: ["admin", "teacher"],
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  }
);

// --------------------------------------------
// Student Risk / Performance analytics (v1)
// --------------------------------------------

async function upsertRiskAndSummary({
  schoolId,
  studentId,
  studentData,
  attendance,
  marks,
  fees,
}) {
  const db = admin.firestore();

  const studentName = String((studentData || {}).name || "");
  const classId = String((studentData || {}).classId || "");
  const sectionId = String((studentData || {}).section || "");
  const classKey = classKeyFrom(classId, sectionId);

  const attendancePercent30d = readNum(attendance.attendancePercent30d);
  const attendanceMarkedDays30d = safeInt(attendance.attendanceMarkedDays30d);
  const marksPercentLatest = marks.hasMarks ? readNum(marks.percent) : 0;
  const feesPendingAmount = readNum(fees.pendingAmount);

  const computed = computeStudentRiskV1({
    attendancePercent30d,
    marksPercentLatest,
    feesPendingAmount,
  });

  const riskDocRef = db
    .collection("schools")
    .doc(schoolId)
    .collection("analytics")
    .doc("student_risk")
    .collection("students")
    .doc(studentId);

  const summaryRef = db
    .collection("schools")
    .doc(schoolId)
    .collection("analytics")
    .doc("risk_summary");

  await db.runTransaction(async (tx) => {
    const prevSnap = await tx.get(riskDocRef);
    const prev = prevSnap.exists ? prevSnap.data() || {} : {};

    const prevLevel = String(prev.riskLevel || "");
    const prevFee = prev.feePending === true;
    const prevLowAttendance = prev.lowAttendance === true;
    const prevTop = prev.topPerformer === true;

    const newLevel = computed.riskLevel;
    const newFee = computed.feePending;
    const newLowAttendance = computed.lowAttendance;
    const newTop = computed.topPerformer;

    // Update per-student index.
    tx.set(
      riskDocRef,
      {
        studentId,
        studentName,
        classId,
        sectionId,
        classKey,

        attendancePercent30d,
        attendanceMarkedDays30d,
        marksPercentLatest,
        feesPendingAmount,

        lowAttendance: newLowAttendance,
        lowMarks: computed.lowMarks,
        feePending: newFee,
        topPerformer: newTop,

        riskLevel: newLevel,
        riskScore: computed.riskScore,
        reasons: computed.reasons,

        createdAt: prevSnap.exists ? prev.createdAt || admin.firestore.FieldValue.serverTimestamp() : admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Update school summary counts (delta-based).
    const inc = admin.firestore.FieldValue.increment;
    const summaryDelta = {};

    function bump(field, delta) {
      if (!delta) return;
      summaryDelta[field] = inc(delta);
    }

    function levelDelta(from, to, level, field) {
      const d = (from === level ? -1 : 0) + (to === level ? 1 : 0);
      bump(field, d);
    }

    levelDelta(prevLevel, newLevel, "HIGH", "studentsHighRisk");
    levelDelta(prevLevel, newLevel, "MEDIUM", "studentsMediumRisk");
    levelDelta(prevLevel, newLevel, "LOW", "studentsLowRisk");

    bump("feeDefaulters", (prevFee ? -1 : 0) + (newFee ? 1 : 0));
    bump("lowAttendance", (prevLowAttendance ? -1 : 0) + (newLowAttendance ? 1 : 0));
    bump("topPerformers", (prevTop ? -1 : 0) + (newTop ? 1 : 0));

    summaryDelta.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    tx.set(summaryRef, summaryDelta, { merge: true });
  });

  return computed;
}

exports.onAttendanceRecordCreated = onDocumentCreated(
  {
    document: "schools/{schoolId}/attendance/{dateKey}/{classKey}/{studentId}",
    region: FIRESTORE_REGION,
  },
  async (event) => {
    const { schoolId, dateKey, studentId } = event.params;
    const after = event.data.data() || {};

    const status = String(after.status || "").trim();
    if (!status) return;

    const db = admin.firestore();

    const studentRef = db.collection("schools").doc(schoolId).collection("students").doc(studentId);
    const attendanceRef = studentRef.collection("analytics").doc("attendance_30d");

    const windowDays = 30;
    const cutoffKey = dateKeyDaysAgoUtc(windowDays - 1);

    // Maintain a compact rolling map of days -> status.
    let mergedDays = {};
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(attendanceRef);
      const data = snap.data() || {};
      const days = (data.days && typeof data.days === "object") ? data.days : {};

      // Merge existing days into a plain object.
      mergedDays = { ...days };
      mergedDays[dateKey] = status;

      // Prune older than cutoff (lexicographic works for YYYY-MM-DD).
      for (const k of Object.keys(mergedDays)) {
        if (k.length === 10 && k < cutoffKey) {
          delete mergedDays[k];
        }
      }

      tx.set(
        attendanceRef,
        {
          windowDays,
          days: mergedDays,
          lastDateKey: dateKey,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    // Compute attendance percent from the rolling map.
    const values = Object.values(mergedDays);
    let presentEq = 0;
    let marked = 0;
    for (const v of values) {
      const s = String(v || "");
      if (!s) continue;
      marked += 1;
      if (s === "present" || s === "late" || s === "leave") {
        presentEq += 1;
      }
    }
    const attendancePercent30d = marked > 0 ? (presentEq / marked) * 100 : 0;

    // Read marks + fees snapshots (best-effort).
    const [studentSnap, marksSnap, feesSnap] = await Promise.all([
      studentRef.get(),
      studentRef.collection("analytics").doc("marks_latest").get(),
      studentRef.collection("analytics").doc("fees_latest").get(),
    ]);

    const studentData = studentSnap.data() || {};
    const marksData = marksSnap.data() || {};
    const feesData = feesSnap.data() || {};

    const marks = {
      hasMarks: marksSnap.exists && typeof marksData.percent === "number",
      percent: readNum(marksData.percent),
    };
    const fees = {
      pendingAmount: readNum(feesData.pendingAmount),
    };

    const computed = await upsertRiskAndSummary({
      schoolId,
      studentId,
      studentData,
      attendance: {
        attendancePercent30d,
        attendanceMarkedDays30d: marked,
      },
      marks,
      fees,
    });

    // If a student becomes HIGH risk, emit a lightweight staff notification.
    // (Parent alerts require a dedicated per-parent feed and are designed separately.)
    if (computed.riskLevel === "HIGH") {
      const notifRef = db
        .collection("schools")
        .doc(schoolId)
        .collection("notifications")
        .doc(`risk_high_${studentId}`);

      await notifRef.set(
        {
          type: "student_high_risk",
          title: "Student at high risk",
          body: `Student ${String(studentData.name || studentId)} needs attention`,
          schoolId,
          studentId,
          classId: String(studentData.classId || ""),
          sectionId: String(studentData.section || ""),
          riskScore: computed.riskScore,
          audience: { roles: ["admin", "teacher"] },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  }
);

exports.onExamMarksWritten = onDocumentWritten(
  {
    document: "schools/{schoolId}/exams/{examId}/marks/{studentId}",
    region: FIRESTORE_REGION,
  },
  async (event) => {
    const { schoolId, examId, studentId } = event.params;

    if (!event.data.after.exists) {
      return;
    }

    const db = admin.firestore();
    const examRef = db.collection("schools").doc(schoolId).collection("exams").doc(examId);
    const marksData = event.data.after.data() || {};

    const [examSnap, studentSnap, attendanceSnap, feesSnap] = await Promise.all([
      examRef.get(),
      db.collection("schools").doc(schoolId).collection("students").doc(studentId).get(),
      db
        .collection("schools")
        .doc(schoolId)
        .collection("students")
        .doc(studentId)
        .collection("analytics")
        .doc("attendance_30d")
        .get(),
      db
        .collection("schools")
        .doc(schoolId)
        .collection("students")
        .doc(studentId)
        .collection("analytics")
        .doc("fees_latest")
        .get(),
    ]);

    const exam = examSnap.data() || {};
    const subjectMarks = (marksData.subjectMarks && typeof marksData.subjectMarks === "object")
      ? marksData.subjectMarks
      : {};
    const subjectMaxMarks = (exam.subjectMaxMarks && typeof exam.subjectMaxMarks === "object")
      ? exam.subjectMaxMarks
      : {};

    let total = 0;
    let maxTotal = 0;
    for (const [subj, mark] of Object.entries(subjectMarks)) {
      const m = safeInt(mark);
      const mx = safeInt(subjectMaxMarks[subj]);
      if (mx <= 0) continue;
      total += Math.max(0, Math.min(m, mx));
      maxTotal += mx;
    }

    const percent = maxTotal > 0 ? (total / maxTotal) * 100 : 0;
    const titleParts = [];
    if (exam.examType) titleParts.push(String(exam.examType).trim());
    if (exam.examName) titleParts.push(String(exam.examName).trim());
    const examTitle = titleParts.filter(Boolean).join(" • ") || String(exam.name || examId);

    const studentRef = db.collection("schools").doc(schoolId).collection("students").doc(studentId);
    await studentRef
      .collection("analytics")
      .doc("marks_latest")
      .set(
        {
          examId,
          examTitle,
          percent,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    // Attendance percent from rolling map.
    const a = attendanceSnap.data() || {};
    const days = (a.days && typeof a.days === "object") ? a.days : {};
    const values = Object.values(days);
    let presentEq = 0;
    let marked = 0;
    for (const v of values) {
      const s = String(v || "");
      if (!s) continue;
      marked += 1;
      if (s === "present" || s === "late" || s === "leave") presentEq += 1;
    }
    const attendancePercent30d = marked > 0 ? (presentEq / marked) * 100 : 0;

    const feesData = feesSnap.data() || {};

    // Parent in-app notification (per-student).
    const studentData = studentSnap.data() || {};
    const parentUid = String(studentData.parentUid || "").trim();
    if (parentUid) {
      const studentName = String(studentData.name || studentId).trim() || studentId;
      const p = Math.round(percent);

      await upsertParentNotification({
        parentUid,
        notificationId: `exam_${examId}_${studentId}`,
        markUnread: true,
        payload: {
          type: "exam_marks_updated",
          title: "Exam result updated",
          body: `${studentName}: ${p}% (${examTitle})`,
          schoolId,
          studentId,
          examId,
          examTitle,
          percent: p,
        },
      });
    }

    await upsertRiskAndSummary({
      schoolId,
      studentId,
      studentData,
      attendance: { attendancePercent30d, attendanceMarkedDays30d: marked },
      marks: { hasMarks: true, percent },
      fees: { pendingAmount: readNum(feesData.pendingAmount) },
    });
  }
);

exports.onStudentFeesWritten = onDocumentWritten(
  {
    document: "schools/{schoolId}/studentFees/{feeDocId}",
    region: FIRESTORE_REGION,
  },
  async (event) => {
    const { schoolId } = event.params;
    const afterExists = event.data.after.exists;
    const data = afterExists ? (event.data.after.data() || {}) : {};
    const studentId = String(data.studentId || "");
    if (!studentId) return;

    const beforeExists = event.data.before.exists;
    const beforeData = beforeExists ? (event.data.before.data() || {}) : {};

    // Interpret fee doc (supports multiple shapes).
    const bal = data.balance ?? data.pendingAmount;
    let pending = readNum(bal);
    if (pending <= 0) {
      const status = String(data.status || "").toLowerCase().trim();
      const amount = readNum(data.amount);
      if (status === "pending" || status === "due") pending += amount;
    }

    // Compute previous pending (best-effort) to detect transitions.
    const beforeBal = beforeData.balance ?? beforeData.pendingAmount;
    let beforePending = readNum(beforeBal);
    if (beforePending <= 0) {
      const status = String(beforeData.status || "").toLowerCase().trim();
      const amount = readNum(beforeData.amount);
      if (status === "pending" || status === "due") beforePending += amount;
    }

    const db = admin.firestore();
    const studentRef = db.collection("schools").doc(schoolId).collection("students").doc(studentId);
    await studentRef
      .collection("analytics")
      .doc("fees_latest")
      .set(
        {
          pendingAmount: pending,
          isPending: pending > 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    const [studentSnap, attendanceSnap, marksSnap] = await Promise.all([
      studentRef.get(),
      studentRef.collection("analytics").doc("attendance_30d").get(),
      studentRef.collection("analytics").doc("marks_latest").get(),
    ]);

    // Parent notification: only when the student becomes a fee defaulter.
    if (beforePending <= 0 && pending > 0) {
      const studentData = studentSnap.data() || {};
      const parentUid = String(studentData.parentUid || "").trim();
      if (parentUid) {
        const studentName = String(studentData.name || studentId).trim() || studentId;
        const amt = Math.round(pending);

        await upsertParentNotification({
          parentUid,
          notificationId: `fee_pending_${studentId}`,
          markUnread: true,
          payload: {
            type: "fee_pending",
            title: "Fees pending",
            body: `${studentName}: ₹${amt} pending`,
            schoolId,
            studentId,
            pendingAmount: pending,
          },
        });
      }
    }

    const a = attendanceSnap.data() || {};
    const days = (a.days && typeof a.days === "object") ? a.days : {};
    const values = Object.values(days);
    let presentEq = 0;
    let marked = 0;
    for (const v of values) {
      const s = String(v || "");
      if (!s) continue;
      marked += 1;
      if (s === "present" || s === "late" || s === "leave") presentEq += 1;
    }
    const attendancePercent30d = marked > 0 ? (presentEq / marked) * 100 : 0;

    const m = marksSnap.data() || {};
    const marksPercentLatest = readNum(m.percent);

    await upsertRiskAndSummary({
      schoolId,
      studentId,
      studentData: studentSnap.data() || {},
      attendance: { attendancePercent30d, attendanceMarkedDays30d: marked },
      marks: { hasMarks: marksSnap.exists, percent: marksPercentLatest },
      fees: { pendingAmount: pending },
    });
  }
);

// --------------------------------------------
// Parent in-app notifications (v1)
// --------------------------------------------

exports.onHomeworkCreated = onDocumentCreated(
  {
    document: "schools/{schoolId}/homework/{homeworkId}",
    region: FIRESTORE_REGION,
  },
  async (event) => {
    const { schoolId, homeworkId } = event.params;
    const data = event.data?.data() || {};

    const classId = String(data.classId || "").trim();
    const section = String(data.section || "").trim();
    const classKey = String(data.classKey || "").trim() || classKeyFrom(classId, section);
    const subject = String(data.subject || "").trim();

    let dueDateLabel = "";
    const dueRaw = data.dueDate;
    if (dueRaw && typeof dueRaw.toDate === "function") {
      const d = dueRaw.toDate();
      dueDateLabel = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    const db = admin.firestore();
    if (!classKey) return;

    const studentsSnap = await db
      .collection("schools")
      .doc(schoolId)
      .collection("students")
      .where("classKey", "==", classKey)
      .get();

    const bw = db.bulkWriter();

    for (const s of studentsSnap.docs) {
      const sd = s.data() || {};
      const parentUid = String(sd.parentUid || "").trim();
      if (!parentUid) continue;

      const studentName = String(sd.name || s.id).trim() || s.id;

      const id = `homework_${homeworkId}_${s.id}`;
      const ref = db
        .collection("users")
        .doc(parentUid)
        .collection("notifications")
        .doc(id);

      bw.set(
        ref,
        {
          type: "homework_created",
          title: "New homework",
          body: `${studentName}: ${subject || "Homework"}${dueDateLabel ? ` (due ${dueDateLabel})` : ""}`,
          schoolId,
          studentId: s.id,
          homeworkId,
          classId,
          section,
          classKey,
          dueDate: data.dueDate || null,
          readAt: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    await bw.close();
  }
);

exports.onAnnouncementCreated = onDocumentCreated(
  {
    document: "schools/{schoolId}/announcements/{announcementId}",
    region: FIRESTORE_REGION,
  },
  async (event) => {
    const { schoolId, announcementId } = event.params;
    const data = event.data?.data() || {};

    const title = String(data.title || "").trim();
    const message = String(data.message || "").trim();
    const target = String(data.target || "").trim();

    // Only notify parents for targets that include parents.
    const shouldNotifyParents = target === "all" || target === "parents" || target.startsWith("class_");
    if (!shouldNotifyParents) return;

    const db = admin.firestore();
    const parentUids = new Set();

    if (target.startsWith("class_")) {
      // target format: class_{classId}_{section}
      const parts = target.split("_");
      if (parts.length >= 3) {
        const classId = String(parts[1] || "").trim();
        const section = String(parts.slice(2).join("_") || "").trim();
        const classKey = classKeyFrom(classId, section);

        const studentsSnap = await db
          .collection("schools")
          .doc(schoolId)
          .collection("students")
          .where("classKey", "==", classKey)
          .get();

        for (const s of studentsSnap.docs) {
          const sd = s.data() || {};
          const parentUid = String(sd.parentUid || "").trim();
          if (parentUid) parentUids.add(parentUid);
        }
      }
    } else {
      // Broadcast: notify all parent users in this school.
      const usersSnap = await db
        .collection("users")
        .where("schoolId", "==", schoolId)
        .get();

      for (const u of usersSnap.docs) {
        const ud = u.data() || {};
        if (String(ud.role || "") !== "parent") continue;
        parentUids.add(u.id);
      }
    }

    if (parentUids.size === 0) return;

    const bw = db.bulkWriter();
    const notifId = `announcement_${announcementId}`;
    for (const uid of parentUids) {
      const ref = db
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(notifId);

      bw.set(
        ref,
        {
          type: "announcement",
          title: title || "New announcement",
          body: message,
          schoolId,
          announcementId,
          target,
          readAt: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    await bw.close();
  }
);

exports.onAttendanceRecordCreated = onDocumentCreated(
  {
    document: "schools/{schoolId}/attendance/{dateKey}/{classKey}/{studentId}",
    region: FIRESTORE_REGION,
  },
  async (event) => {
    const { schoolId, dateKey, classKey, studentId } = event.params;
    const data = event.data?.data() || {};
    const status = String(data.status || data.studentStatus || "").trim().toLowerCase();

    // Smart alerts: only for non-present statuses.
    if (status !== "absent" && status !== "late" && status !== "leave") return;

    const db = admin.firestore();
    const studentSnap = await db
      .collection("schools")
      .doc(schoolId)
      .collection("students")
      .doc(studentId)
      .get();

    const student = studentSnap.data() || {};
    const parentUid = String(student.parentUid || "").trim();
    if (!parentUid) return;

    const studentName = String(student.name || studentId).trim() || studentId;
    const prettyDate = prettyDateKey(dateKey);

    await upsertParentNotification({
      parentUid,
      notificationId: `attendance_${dateKey}_${studentId}`,
      markUnread: true,
      payload: {
        type: "attendance_alert",
        title: `Attendance: ${status.toUpperCase()}`,
        body: `${studentName} marked ${status} on ${prettyDate}`,
        schoolId,
        studentId,
        dateKey,
        classKey,
        status,
      },
    });
  }
);

exports.recomputeStudentRisk = onCall({ enforceAppCheck: true }, async (request) => {
  const data = request.data || {};
  const schoolId = String(data.schoolId || "").trim();
  const classId = String(data.classId || "").trim();
  const sectionId = String(data.sectionId || "").trim();

  if (!schoolId) {
    throw new HttpsError("invalid-argument", "schoolId is required");
  }

  await authorizeSchoolAdminOrSuperAdmin({ request, schoolId });

  const db = admin.firestore();

  // Load fee docs once (best-effort) and map to studentId -> pendingAmount.
  const feeSnap = await db.collection("schools").doc(schoolId).collection("studentFees").get();
  const feeByStudent = new Map();
  for (const doc of feeSnap.docs) {
    const d = doc.data() || {};
    const sid = String(d.studentId || doc.id);
    if (!sid) continue;
    const bal = d.balance ?? d.pendingAmount;
    let pending = readNum(bal);
    if (pending <= 0) {
      const status = String(d.status || "").toLowerCase().trim();
      const amount = readNum(d.amount);
      if (status === "pending" || status === "due") pending += amount;
    }
    if (!pending) continue;
    feeByStudent.set(sid, (feeByStudent.get(sid) || 0) + pending);
  }

  let studentsQuery = db.collection("schools").doc(schoolId).collection("students");
  if (classId && sectionId) {
    studentsQuery = studentsQuery.where("classId", "==", classId).where("section", "==", sectionId);
  }

  const studentsSnap = await studentsQuery.get();

  // Recompute risk for each student.
  const summary = {
    studentsHighRisk: 0,
    studentsMediumRisk: 0,
    studentsLowRisk: 0,
    feeDefaulters: 0,
    lowAttendance: 0,
    topPerformers: 0,
  };

  for (const s of studentsSnap.docs) {
    const studentId = s.id;
    const studentData = s.data() || {};

    const attendanceSnap = await s.ref.collection("analytics").doc("attendance_30d").get();
    const a = attendanceSnap.data() || {};
    const days = (a.days && typeof a.days === "object") ? a.days : {};
    const values = Object.values(days);
    let presentEq = 0;
    let marked = 0;
    for (const v of values) {
      const st = String(v || "");
      if (!st) continue;
      marked += 1;
      if (st === "present" || st === "late" || st === "leave") presentEq += 1;
    }
    const attendancePercent30d = marked > 0 ? (presentEq / marked) * 100 : 0;

    const marksSnap = await s.ref.collection("analytics").doc("marks_latest").get();
    const marksData = marksSnap.data() || {};
    const marksPercentLatest = readNum(marksData.percent);

    const pending = readNum(feeByStudent.get(studentId) || 0);
    await s.ref
      .collection("analytics")
      .doc("fees_latest")
      .set(
        {
          pendingAmount: pending,
          isPending: pending > 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    const computed = await upsertRiskAndSummary({
      schoolId,
      studentId,
      studentData,
      attendance: { attendancePercent30d, attendanceMarkedDays30d: marked },
      marks: { hasMarks: marksSnap.exists, percent: marksPercentLatest },
      fees: { pendingAmount: pending },
    });

    // Track totals locally too.
    if (computed.riskLevel === "HIGH") summary.studentsHighRisk += 1;
    else if (computed.riskLevel === "MEDIUM") summary.studentsMediumRisk += 1;
    else summary.studentsLowRisk += 1;
    if (computed.feePending) summary.feeDefaulters += 1;
    if (computed.lowAttendance) summary.lowAttendance += 1;
    if (computed.topPerformer) summary.topPerformers += 1;
  }

  // Set the summary doc to the computed values (authoritative after recompute).
  await db
    .collection("schools")
    .doc(schoolId)
    .collection("analytics")
    .doc("risk_summary")
    .set(
      {
        ...summary,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  return {
    ok: true,
    schoolId,
    filter: classId && sectionId ? { classId, sectionId } : null,
    studentsScanned: studentsSnap.size,
    ...summary,
  };
});

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

function generateNumericPin(length = 6) {
  const n = crypto.randomInt(0, Math.pow(10, length));
  return String(n).padStart(length, "0");
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

exports.createOrResetParentAccount = onCall({ enforceAppCheck: true }, async (request) => {
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
  const initialPin = generateNumericPin(6);
  const pinSalt = crypto.randomBytes(16).toString("hex");
  const pinHash = hashPin(initialPin, pinSalt);

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
    initialPin,
    defaultPasswordHint: "random",
    mustChangePassword: true,
  };
});

exports.parentLogin = onCall({ enforceAppCheck: true }, async (request) => {
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

  const mappingSchoolId = String(mapping.schoolId || "");

  const userDocRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userDocRef.get();
  const userData = userDoc.data() || {};
  if (String(userData.role || "") !== "parent") {
    throw new HttpsError("permission-denied", "Not a parent account");
  }

  const userSchoolId = String(userData.schoolId || "");
  if (mappingSchoolId && userSchoolId && mappingSchoolId !== userSchoolId) {
    throw new HttpsError(
      "failed-precondition",
      "Parent login mapping is inconsistent. Contact school admin."
    );
  }

  const salt = String(userData.pinSalt || "");
  const expected = String(userData.pinHash || "");
  if (!salt || !expected) {
    throw new HttpsError("failed-precondition", "Parent PIN not initialized");
  }

  // Basic rate limiting / lockout (prevents brute force).
  const nowMs = Date.now();
  const lockUntil = userData.pinLockedUntil;
  if (lockUntil && typeof lockUntil.toMillis === "function" && lockUntil.toMillis() > nowMs) {
    throw new HttpsError("resource-exhausted", "Too many failed attempts. Try again later.");
  }

  const lastFailAt = userData.pinLastFailAt;
  const lastFailMs = lastFailAt && typeof lastFailAt.toMillis === "function" ? lastFailAt.toMillis() : 0;
  const windowMs = 10 * 60 * 1000;
  const baseFailCount = Number(userData.pinFailCount || 0);
  const failCount = lastFailMs > 0 && nowMs - lastFailMs <= windowMs ? baseFailCount : 0;

  const actual = hashPin(pin, salt);
  if (actual !== expected) {
    const newCount = failCount + 1;
    const maxAttempts = 8;
    const lockMs = 15 * 60 * 1000;

    const update = {
      pinFailCount: newCount,
      pinLastFailAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (newCount >= maxAttempts) {
      update.pinLockedUntil = admin.firestore.Timestamp.fromMillis(nowMs + lockMs);
    }

    await userDocRef.set(update, { merge: true });
    throw new HttpsError("permission-denied", "Invalid PIN");
  }

  const schoolId = userSchoolId;
  const mustChangePassword = (userData.mustChangePassword || false) === true;

  // Clear any previous lockout counters on success.
  if (failCount > 0 || (lockUntil && typeof lockUntil.toMillis === "function")) {
    await userDocRef.set(
      {
        pinFailCount: 0,
        pinLastFailAt: admin.firestore.FieldValue.delete(),
        pinLockedUntil: admin.firestore.FieldValue.delete(),
        lastParentLoginAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

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

exports.recomputeSchoolCounters = onCall({ enforceAppCheck: true }, async (request) => {
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

  const isSuper = callerRole === "superAdmin" || (request.auth.token && request.auth.token.superAdmin === true);
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

// ---------------------------------------------------------------------------
// Google Sheets sync/export (Super Admin only)
// ---------------------------------------------------------------------------

function clampInt(v, min, max) {
  const n = safeInt(v);
  if (n < min) return min;
  if (n > max) return max;
  return n;
}

async function getSheetsSyncConfig({ db, schoolId }) {
  const ref = db.collection("platformGoogleSheetsSync").doc(schoolId);
  const snap = await ref.get();
  if (!snap.exists) return { ref, config: null };
  return { ref, config: snap.data() || {} };
}

async function syncSchoolToGoogleSheetsInternal({
  db,
  schoolId,
  spreadsheetId,
  daysBack,
  maxRowsPerTab,
  actorUid,
  trigger,
}) {
  const cfgRef = db.collection("platformGoogleSheetsSync").doc(schoolId);
  const schoolRef = db.collection("schools").doc(schoolId);

  // Load core collections.
  const [studentsSnap, teachersSnap, feesSnap, examsSnap] = await Promise.all([
    schoolRef.collection("students").get(),
    schoolRef.collection("teachers").get(),
    schoolRef.collection("studentFees").get(),
    schoolRef.collection("exams").get(),
  ]);

  // Parents derived from students (safer than exporting /users which contains auth/PIN fields).
  const parentsByUid = new Map();

  const studentsRows = [
    [
      "studentId",
      "name",
      "admissionNo",
      "classId",
      "section",
      "classKey",
      "parentUid",
      "parentName",
      "parentPhone",
      "status",
      "createdAt",
      "updatedAt",
      "json",
    ],
  ];

  for (const doc of studentsSnap.docs.slice(0, maxRowsPerTab)) {
    const d = doc.data() || {};
    const parentUid = String(d.parentUid || "").trim();
    const parentPhone = String(d.parentPhone || "").trim();
    const parentName = String(d.parentName || "").trim();

    if (parentUid) {
      const entry = parentsByUid.get(parentUid) || {
        parentUid,
        parentName,
        parentPhone,
        studentIds: [],
        studentNames: [],
      };
      entry.parentName = entry.parentName || parentName;
      entry.parentPhone = entry.parentPhone || parentPhone;
      entry.studentIds.push(doc.id);
      entry.studentNames.push(String(d.name || "").trim());
      parentsByUid.set(parentUid, entry);
    }

    studentsRows.push([
      doc.id,
      asCell(d.name),
      asCell(d.admissionNo),
      asCell(d.classId),
      asCell(d.section),
      asCell(d.classKey),
      parentUid,
      parentName,
      parentPhone,
      asCell(d.status),
      asCell(d.createdAt),
      asCell(d.updatedAt),
      safeJson(d),
    ]);
  }

  const teachersRows = [
    [
      "teacherId",
      "name",
      "email",
      "phone",
      "assignmentKeys",
      "createdAt",
      "updatedAt",
      "json",
    ],
  ];

  for (const doc of teachersSnap.docs.slice(0, maxRowsPerTab)) {
    const d = doc.data() || {};
    const keys = Array.isArray(d.assignmentKeys) ? d.assignmentKeys.map(String) : [];
    teachersRows.push([
      doc.id,
      asCell(d.name),
      asCell(d.email),
      asCell(d.phone),
      keys.join("|"),
      asCell(d.createdAt),
      asCell(d.updatedAt),
      safeJson(d),
    ]);
  }

  const parentsRows = [
    [
      "parentUid",
      "parentName",
      "parentPhone",
      "childrenStudentIds",
      "childrenStudentNames",
    ],
  ];
  for (const p of parentsByUid.values()) {
    parentsRows.push([
      asCell(p.parentUid),
      asCell(p.parentName),
      asCell(p.parentPhone),
      asCell(p.studentIds.join(",")),
      asCell(p.studentNames.filter(Boolean).join(", ")),
    ]);
  }

  const feesRows = [
    [
      "feeDocId",
      "studentId",
      "amount",
      "balance",
      "status",
      "createdAt",
      "updatedAt",
      "json",
    ],
  ];
  for (const doc of feesSnap.docs.slice(0, maxRowsPerTab)) {
    const d = doc.data() || {};
    feesRows.push([
      doc.id,
      asCell(d.studentId || doc.id),
      asCell(d.amount),
      asCell(d.balance ?? d.pendingAmount),
      asCell(d.status),
      asCell(d.createdAt),
      asCell(d.updatedAt),
      safeJson(d),
    ]);
  }

  // Marks: flatten exams/*/marks/*
  const marksRows = [
    [
      "examId",
      "examName",
      "classKey",
      "studentId",
      "score",
      "total",
      "grade",
      "updatedAt",
      "json",
    ],
  ];
  let marksCount = 0;
  for (const examDoc of examsSnap.docs) {
    if (marksCount >= maxRowsPerTab) break;
    const exam = examDoc.data() || {};
    const examName = exam.title || exam.name || examDoc.id;
    const classKey = exam.classKey || "";

    const marksSnap = await examDoc.ref.collection("marks").get();
    for (const markDoc of marksSnap.docs) {
      if (marksCount >= maxRowsPerTab) break;
      const m = markDoc.data() || {};
      marksRows.push([
        examDoc.id,
        asCell(examName),
        asCell(classKey),
        markDoc.id,
        asCell(m.score ?? m.marks ?? m.value),
        asCell(m.total ?? m.max ?? m.outOf),
        asCell(m.grade),
        asCell(m.updatedAt),
        safeJson(m),
      ]);
      marksCount += 1;
    }
  }

  // Attendance: export recent per-student attendance rows from last N days.
  // NOTE: Attendance can be large; we cap rows to maxRowsPerTab.
  const attendanceRows = [
    [
      "dateKey",
      "classKey",
      "studentId",
      "status",
      "markedBy",
      "updatedAt",
      "json",
    ],
  ];
  let attendanceCount = 0;
  for (let i = 0; i < daysBack; i++) {
    if (attendanceCount >= maxRowsPerTab) break;
    const dateKey = dateKeyDaysAgoUtc(daysBack - 1 - i);
    const dateDocRef = schoolRef.collection("attendance").doc(dateKey);
    let cols = [];
    try {
      cols = await dateDocRef.listCollections();
    } catch (_) {
      cols = [];
    }

    for (const col of cols) {
      if (attendanceCount >= maxRowsPerTab) break;
      const classKey = String(col.id || "");
      if (!classKey || classKey === "meta") continue;

      const snap = await col.get();
      for (const aDoc of snap.docs) {
        if (attendanceCount >= maxRowsPerTab) break;
        const a = aDoc.data() || {};
        attendanceRows.push([
          dateKey,
          classKey,
          aDoc.id,
          asCell(a.status ?? a.studentStatus ?? (a.present === true ? "present" : "")),
          asCell(a.markedBy),
          asCell(a.updatedAt),
          safeJson(a),
        ]);
        attendanceCount += 1;
      }
    }
  }

  // Build sync info.
  const syncedAtIso = new Date().toISOString();
  const syncInfoRows = [
    ["key", "value"],
    ["schoolId", schoolId],
    ["spreadsheetId", spreadsheetId],
    ["daysBack", String(daysBack)],
    ["maxRowsPerTab", String(maxRowsPerTab)],
    ["syncTrigger", String(trigger || "manual")],
    ["syncedByUid", actorUid ? String(actorUid) : "system"],
    ["syncedAtUtc", syncedAtIso],
    ["studentsExported", String(studentsRows.length - 1)],
    ["teachersExported", String(teachersRows.length - 1)],
    ["parentsExported", String(parentsRows.length - 1)],
    ["feesExported", String(feesRows.length - 1)],
    ["marksExported", String(marksRows.length - 1)],
    ["attendanceExported", String(attendanceRows.length - 1)],
  ];

  const sheets = await getSheetsClient();
  const titles = [
    "sync_info",
    "students",
    "teachers",
    "parents",
    "fees",
    "marks",
    "attendance",
  ];
  await ensureSheetTabs({ sheets, spreadsheetId, titles });

  await writeTabValues({ sheets, spreadsheetId, title: "sync_info", values: syncInfoRows });
  await writeTabValues({ sheets, spreadsheetId, title: "students", values: studentsRows });
  await writeTabValues({ sheets, spreadsheetId, title: "teachers", values: teachersRows });
  await writeTabValues({ sheets, spreadsheetId, title: "parents", values: parentsRows });
  await writeTabValues({ sheets, spreadsheetId, title: "fees", values: feesRows });
  await writeTabValues({ sheets, spreadsheetId, title: "marks", values: marksRows });
  await writeTabValues({ sheets, spreadsheetId, title: "attendance", values: attendanceRows });

  const counts = {
    students: studentsRows.length - 1,
    teachers: teachersRows.length - 1,
    parents: parentsRows.length - 1,
    fees: feesRows.length - 1,
    marks: marksRows.length - 1,
    attendance: attendanceRows.length - 1,
  };

  // Persist last sync result.
  await cfgRef.set(
    {
      lastSyncAt: admin.firestore.FieldValue.serverTimestamp(),
      lastSyncByUid: actorUid ? String(actorUid) : "system",
      lastSyncTrigger: String(trigger || "manual"),
      lastSyncCounts: counts,
      lastSyncError: admin.firestore.FieldValue.delete(),
    },
    { merge: true }
  );

  // Audit log (server-side only; clients can't read it via rules).
  await db.collection("platformSyncLogs").add({
    type: "google_sheets_sync",
    trigger: String(trigger || "manual"),
    schoolId,
    spreadsheetId,
    daysBack,
    maxRowsPerTab,
    counts,
    actorUid: actorUid ? String(actorUid) : "system",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    schoolId,
    spreadsheetId,
    daysBack,
    maxRowsPerTab,
    counts,
  };
}

exports.setGoogleSheetsSyncConfig = onCall({ enforceAppCheck: true }, async (request) => {
  await requireSuperAdminCaller(request);

  const db = admin.firestore();
  const data = request.data || {};
  const schoolId = String(data.schoolId || "").trim();
  const spreadsheetId = String(data.spreadsheetId || "").trim();
  const enabled = normalizeBool(data.enabled);

  if (!schoolId) {
    throw new HttpsError("invalid-argument", "schoolId is required");
  }

  // spreadsheetId is required only when enabling.
  if (enabled && !spreadsheetId) {
    throw new HttpsError("invalid-argument", "spreadsheetId is required when enabled=true");
  }

  const daysBack = clampInt(data.daysBack ?? 30, 1, 120);
  const maxRowsPerTab = clampInt(data.maxRowsPerTab ?? 20000, 1000, 100000);

  const ref = db.collection("platformGoogleSheetsSync").doc(schoolId);
  await ref.set(
    {
      schoolId,
      enabled,
      spreadsheetId: spreadsheetId || admin.firestore.FieldValue.delete(),
      daysBack,
      maxRowsPerTab,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true, schoolId, enabled, daysBack, maxRowsPerTab };
});

exports.getGoogleSheetsSyncConfig = onCall({ enforceAppCheck: true }, async (request) => {
  await requireSuperAdminCaller(request);

  const db = admin.firestore();
  const data = request.data || {};
  const schoolId = String(data.schoolId || "").trim();
  if (!schoolId) {
    throw new HttpsError("invalid-argument", "schoolId is required");
  }

  const { config } = await getSheetsSyncConfig({ db, schoolId });
  return { ok: true, schoolId, config: config || null };
});

exports.syncSchoolToGoogleSheets = onCall(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
  },
  async (request) => {
    const { callerUid } = await requireSuperAdminCaller(request);

    const db = admin.firestore();
    const data = request.data || {};
    const schoolId = String(data.schoolId || "").trim();
    if (!schoolId) {
      throw new HttpsError("invalid-argument", "schoolId is required");
    }

    const { ref: cfgRef, config } = await getSheetsSyncConfig({ db, schoolId });
    if (!config || config.enabled !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Google Sheets sync is not enabled for this school. Call setGoogleSheetsSyncConfig first."
      );
    }

    const spreadsheetId = String(config.spreadsheetId || "").trim();
    if (!spreadsheetId) {
      throw new HttpsError("failed-precondition", "spreadsheetId is missing in config");
    }

    const daysBack = clampInt(data.daysBack ?? config.daysBack ?? 30, 1, 120);
    const maxRowsPerTab = clampInt(data.maxRowsPerTab ?? config.maxRowsPerTab ?? 20000, 1000, 100000);

    const result = await syncSchoolToGoogleSheetsInternal({
      db,
      schoolId,
      spreadsheetId,
      daysBack,
      maxRowsPerTab,
      actorUid: callerUid,
      trigger: "manual",
    });

    return {
      ok: true,
      ...result,
      note:
        "Sheets sync is super-admin only and does not export sensitive /users auth fields. Attendance is limited to recent daysBack and capped by maxRowsPerTab.",
    };
  }
);

// Daily auto-sync for all enabled schools.
// NOTE: This is server-side only and does not require App Check.
exports.autoSyncAllSchoolsToGoogleSheets = onSchedule(
  {
    schedule: "0 2 * * *",
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (_event) => {
    const db = admin.firestore();
    const snap = await db
      .collection("platformGoogleSheetsSync")
      .where("enabled", "==", true)
      .get();

    let okCount = 0;
    let errorCount = 0;

    // Sequential by default to be kind to Sheets API quotas.
    for (const doc of snap.docs) {
      const cfg = doc.data() || {};
      const schoolId = String(cfg.schoolId || doc.id || "").trim();
      const spreadsheetId = String(cfg.spreadsheetId || "").trim();
      if (!schoolId || !spreadsheetId) continue;

      const daysBack = clampInt(cfg.daysBack ?? 30, 1, 120);
      const maxRowsPerTab = clampInt(cfg.maxRowsPerTab ?? 20000, 1000, 100000);

      try {
        await syncSchoolToGoogleSheetsInternal({
          db,
          schoolId,
          spreadsheetId,
          daysBack,
          maxRowsPerTab,
          actorUid: null,
          trigger: "auto",
        });
        okCount += 1;
      } catch (e) {
        errorCount += 1;

        const msg = e && e.message ? String(e.message) : String(e);
        await doc.ref.set(
          {
            lastSyncAt: admin.firestore.FieldValue.serverTimestamp(),
            lastSyncByUid: "system",
            lastSyncTrigger: "auto",
            lastSyncError: msg.slice(0, 1000),
          },
          { merge: true }
        );
      }
    }

    return { ok: true, schoolsSynced: okCount, schoolsFailed: errorCount };
  }
);

// ---------------------------------------------------------------------------
// Danger Zone: Reset school data (Super Admin only)
// ---------------------------------------------------------------------------

async function requireSuperAdminCaller(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
  const callerRole = String((callerDoc.data() || {}).role || "");
  const isSuper =
    callerRole === "superAdmin" ||
    (request.auth.token && request.auth.token.superAdmin === true);

  if (!isSuper) {
    throw new HttpsError(
      "permission-denied",
      "Only superAdmin can perform data resets"
    );
  }

  return { callerUid, callerRole };
}

async function requireMaintenanceModeEnabled() {
  const statusSnap = await admin.firestore().collection("platform").doc("status").get();
  const enabled = (statusSnap.data() || {}).maintenanceMode === true;
  if (!enabled) {
    throw new HttpsError(
      "failed-precondition",
      "Maintenance Mode must be enabled before running a reset"
    );
  }
}

function normalizeBool(v) {
  return v === true || v === "true";
}

function normalizeStringArray(input) {
  if (!Array.isArray(input)) return [];
  const out = [];
  for (const v of input) {
    const s = String(v || "").trim();
    if (!s) continue;
    out.push(s);
  }
  return Array.from(new Set(out));
}

function chunkArray(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

async function resolveTargetSchoolIds({ db, schoolId, schoolIds, allSchools }) {
  if (allSchools === true) {
    const snap = await db.collection("schools").get();
    const ids = snap.docs.map((d) => d.id).filter(Boolean);
    if (ids.length === 0) {
      throw new HttpsError("failed-precondition", "No schools found to reset");
    }
    return { targetSchoolIds: ids, allSchools: true };
  }

  const ids = normalizeStringArray(schoolIds);
  const single = String(schoolId || "").trim();
  const target = ids.length > 0 ? ids : single ? [single] : [];
  if (target.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Provide schoolId, schoolIds[], or allSchools=true"
    );
  }
  return { targetSchoolIds: target, allSchools: false };
}

function expectedResetPhrase({ allSchools, targetSchoolIds }) {
  if (allSchools) return "DELETE ALL";
  if (targetSchoolIds.length === 1) return `DELETE ${targetSchoolIds[0]}`;
  return `DELETE ${targetSchoolIds.length} SCHOOLS`;
}

function expectedRestorePhrase({ restoreAll, targetSchoolIds }) {
  if (restoreAll) return "RESTORE ALL";
  if (targetSchoolIds.length === 1) return `RESTORE ${targetSchoolIds[0]}`;
  return `RESTORE ${targetSchoolIds.length} SCHOOLS`;
}

async function copyDocTree({ srcDocRef, dstDocRef, bw }) {
  const snap = await srcDocRef.get();
  if (!snap.exists) return;

  bw.set(dstDocRef, snap.data() || {}, { merge: false });

  const subcols = await srcDocRef.listCollections();
  for (const subcol of subcols) {
    const docsSnap = await subcol.get();
    for (const doc of docsSnap.docs) {
      await copyDocTree({
        srcDocRef: doc.ref,
        dstDocRef: dstDocRef.collection(subcol.id).doc(doc.id),
        bw,
      });
    }
  }
}

async function deleteDocTree({ db, docRef, bw }) {
  await db.recursiveDelete(docRef, bw);
}

function newBackupId() {
  const rand = crypto.randomBytes(8).toString("hex");
  return `backup_${Date.now()}_${rand}`;
}

async function requireCompletedBackup({ db, backupId, targetSchoolIds, allSchools }) {
  const id = String(backupId || "").trim();
  if (!id) {
    throw new HttpsError(
      "failed-precondition",
      "backupId is required. Create a backup snapshot before executing a reset."
    );
  }

  const ref = db.collection("platformBackups").doc(id);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "backupId not found");
  }

  const data = snap.data() || {};
  if (String(data.status || "") !== "COMPLETED") {
    throw new HttpsError(
      "failed-precondition",
      "Backup is not completed yet"
    );
  }

  // Safety: ensure backup matches the reset target.
  const backedUpSchoolIds = normalizeStringArray(data.schoolIds);
  const backupAll = data.allSchools === true;
  const targetSet = new Set(targetSchoolIds);
  const backupSet = new Set(backedUpSchoolIds);

  if (allSchools !== backupAll) {
    throw new HttpsError(
      "failed-precondition",
      "backupId does not match the reset scope (all vs selected)"
    );
  }

  for (const id2 of targetSet) {
    if (!backupSet.has(id2)) {
      throw new HttpsError(
        "failed-precondition",
        "backupId does not include all selected schools"
      );
    }
  }

  // Safety: require that backup is recent (within 6 hours).
  const createdAt = data.createdAt;
  const createdMs =
    createdAt && typeof createdAt.toMillis === "function" ? createdAt.toMillis() : 0;
  const ageMs = createdMs ? Date.now() - createdMs : Number.POSITIVE_INFINITY;
  const maxAgeMs = 6 * 60 * 60 * 1000;
  if (ageMs > maxAgeMs) {
    throw new HttpsError(
      "failed-precondition",
      "Backup is too old. Create a new backup snapshot before resetting."
    );
  }

  return { backupRef: ref, backupData: data };
}

exports.createDataBackup = onCall(
  {
    timeoutSeconds: 540,
    memory: "2GiB",
    enforceAppCheck: true,
  },
  async (request) => {
    const { callerUid } = await requireSuperAdminCaller(request);
    await requireMaintenanceModeEnabled();

    const db = admin.firestore();
    const data = request.data || {};
    const schoolId = String(data.schoolId || "").trim();
    const schoolIds = normalizeStringArray(data.schoolIds);
    const allSchools = normalizeBool(data.allSchools);

    const { targetSchoolIds, allSchools: resolvedAll } = await resolveTargetSchoolIds({
      db,
      schoolId,
      schoolIds,
      allSchools,
    });

    // Create a backup record first.
    const backupId = newBackupId();
    const backupRef = db.collection("platformBackups").doc(backupId);
    await backupRef.set(
      {
        backupId,
        status: "RUNNING",
        schoolIds: targetSchoolIds,
        allSchools: resolvedAll,
        createdByUid: callerUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const bw = db.bulkWriter();
    bw.onWriteError((err) => {
      console.error("BulkWriter error during createDataBackup", err);
      return err.failedAttempts < 5;
    });

    // Copy each selected school subtree.
    for (const sid of targetSchoolIds) {
      const src = db.collection("schools").doc(sid);
      const dst = backupRef.collection("schools").doc(sid);
      await copyDocTree({ srcDocRef: src, dstDocRef: dst, bw });
    }

    // Copy users (Firestore) for these schools.
    let totalUsers = 0;
    for (const chunk of chunkArray(targetSchoolIds, 10)) {
      const usersSnap = await db.collection("users").where("schoolId", "in", chunk).get();
      totalUsers += usersSnap.size;
      for (const userDoc of usersSnap.docs) {
        const src = userDoc.ref;
        const dst = backupRef.collection("users").doc(userDoc.id);
        await copyDocTree({ srcDocRef: src, dstDocRef: dst, bw });
      }
    }

    // Copy parent phone mappings.
    let totalPhones = 0;
    for (const chunk of chunkArray(targetSchoolIds, 10)) {
      const phonesSnap = await db.collection("parentPhones").where("schoolId", "in", chunk).get();
      totalPhones += phonesSnap.size;
      for (const doc of phonesSnap.docs) {
        bw.set(backupRef.collection("parentPhones").doc(doc.id), doc.data() || {}, { merge: false });
      }
    }

    await bw.close();

    await backupRef.set(
      {
        status: "COMPLETED",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        counts: {
          schools: targetSchoolIds.length,
          users: totalUsers,
          parentPhones: totalPhones,
        },
      },
      { merge: true }
    );

    return {
      ok: true,
      backupId,
      schoolIds: targetSchoolIds,
      allSchools: resolvedAll,
      counts: {
        schools: targetSchoolIds.length,
        users: totalUsers,
        parentPhones: totalPhones,
      },
      note:
        "This is an in-project Firestore snapshot to enable restore. For disaster recovery, also export to Cloud Storage.",
    };
  }
);

exports.listDataBackups = onCall({ enforceAppCheck: true }, async (request) => {
  await requireSuperAdminCaller(request);
  const db = admin.firestore();

  const snap = await db
    .collection("platformBackups")
    .orderBy("createdAt", "desc")
    .limit(25)
    .get();

  const backups = snap.docs.map((d) => {
    const data = d.data() || {};
    return {
      backupId: d.id,
      status: data.status || null,
      allSchools: data.allSchools === true,
      schoolIds: normalizeStringArray(data.schoolIds),
      counts: data.counts || null,
      createdByUid: data.createdByUid || null,
      createdAt: data.createdAt || null,
      completedAt: data.completedAt || null,
    };
  });

  return { ok: true, backups };
});

exports.restoreDataBackup = onCall(
  {
    timeoutSeconds: 540,
    memory: "2GiB",
    enforceAppCheck: true,
  },
  async (request) => {
    const { callerUid } = await requireSuperAdminCaller(request);
    await requireMaintenanceModeEnabled();

    const db = admin.firestore();
    const data = request.data || {};

    const backupId = String(data.backupId || "").trim();
    const restoreAll = normalizeBool(data.restoreAll);
    const schoolIds = normalizeStringArray(data.schoolIds);
    const confirmPhrase = String(data.confirmPhrase || "").trim();
    const overwriteConfirmed = normalizeBool(data.overwriteConfirmed);

    if (!backupId) {
      throw new HttpsError("invalid-argument", "backupId is required");
    }
    if (!overwriteConfirmed) {
      throw new HttpsError(
        "failed-precondition",
        "overwriteConfirmed is required"
      );
    }

    const backupRef = db.collection("platformBackups").doc(backupId);
    const backupSnap = await backupRef.get();
    if (!backupSnap.exists) {
      throw new HttpsError("not-found", "Backup not found");
    }
    const backupData = backupSnap.data() || {};
    if (String(backupData.status || "") !== "COMPLETED") {
      throw new HttpsError("failed-precondition", "Backup is not completed");
    }

    const backupSchoolIds = normalizeStringArray(backupData.schoolIds);
    const targetSchoolIds = restoreAll ? backupSchoolIds : schoolIds;
    if (targetSchoolIds.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Provide schoolIds[] or restoreAll=true"
      );
    }

    const expected = expectedRestorePhrase({ restoreAll, targetSchoolIds }).toUpperCase();
    if (confirmPhrase.toUpperCase() !== expected) {
      throw new HttpsError(
        "failed-precondition",
        `Type the exact confirmation phrase: ${expected}`
      );
    }

    await db.collection("platformResetLogs").add({
      type: "restoreDataBackup",
      backupId,
      restoreAll,
      schoolIds: targetSchoolIds,
      requestedByUid: callerUid,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const bw = db.bulkWriter();
    bw.onWriteError((err) => {
      console.error("BulkWriter error during restoreDataBackup", err);
      return err.failedAttempts < 5;
    });

    // Restore schools.
    for (const sid of targetSchoolIds) {
      const src = backupRef.collection("schools").doc(sid);
      const dst = db.collection("schools").doc(sid);

      // Replace existing data.
      await deleteDocTree({ db, docRef: dst, bw });
      await copyDocTree({ srcDocRef: src, dstDocRef: dst, bw });
    }

    // Restore users + parentPhones.
    // Delete then restore users per school to avoid stale data.
    for (const sid of targetSchoolIds) {
      const existingUsersSnap = await db.collection("users").where("schoolId", "==", sid).get();
      for (const doc of existingUsersSnap.docs) {
        const role = String((doc.data() || {}).role || "");
        if (role === "superAdmin") continue;
        await deleteDocTree({ db, docRef: doc.ref, bw });
      }

      const backupUsersSnap = await backupRef.collection("users").where("schoolId", "==", sid).get();
      for (const doc of backupUsersSnap.docs) {
        const role = String((doc.data() || {}).role || "");
        if (role === "superAdmin") continue;
        const src = doc.ref;
        const dst = db.collection("users").doc(doc.id);
        await copyDocTree({ srcDocRef: src, dstDocRef: dst, bw });
      }

      const existingPhonesSnap = await db.collection("parentPhones").where("schoolId", "==", sid).get();
      for (const doc of existingPhonesSnap.docs) {
        bw.delete(doc.ref);
      }
      const backupPhonesSnap = await backupRef.collection("parentPhones").where("schoolId", "==", sid).get();
      for (const doc of backupPhonesSnap.docs) {
        bw.set(db.collection("parentPhones").doc(doc.id), doc.data() || {}, { merge: false });
      }
    }

    await bw.close();

    return {
      ok: true,
      backupId,
      restored: {
        schools: targetSchoolIds.length,
      },
      warning:
        "Restore copies Firestore data only. Firebase Auth users/passwords are not restored automatically.",
    };
  }
);

// ---------------------------------------------------------------------------
// Super Admin: Single-file backups (Cloud Storage) + restore
// ---------------------------------------------------------------------------

function newFileBackupId() {
  const rand = crypto.randomBytes(8).toString("hex");
  return `filebackup_${Date.now()}_${rand}`;
}

function isPlainObject(v) {
  return v && typeof v === "object" && v.constructor === Object;
}

function encodeFirestoreValue(v) {
  if (v == null) return v;

  // Timestamp
  if (v instanceof admin.firestore.Timestamp) {
    return {
      __skType: "timestamp",
      seconds: v.seconds,
      nanoseconds: v.nanoseconds,
    };
  }

  // GeoPoint
  if (v instanceof admin.firestore.GeoPoint) {
    return {
      __skType: "geopoint",
      latitude: v.latitude,
      longitude: v.longitude,
    };
  }

  // Bytes (Buffer)
  if (Buffer.isBuffer(v)) {
    return {
      __skType: "bytes",
      base64: v.toString("base64"),
    };
  }

  if (Array.isArray(v)) {
    return v.map(encodeFirestoreValue);
  }

  if (isPlainObject(v)) {
    const out = {};
    for (const [k, vv] of Object.entries(v)) {
      out[k] = encodeFirestoreValue(vv);
    }
    return out;
  }

  return v;
}

function decodeFirestoreValue(db, v) {
  if (v == null) return v;
  if (Array.isArray(v)) return v.map((x) => decodeFirestoreValue(db, x));

  if (isPlainObject(v) && typeof v.__skType === "string") {
    if (v.__skType === "timestamp") {
      const s = safeInt(v.seconds);
      const ns = safeInt(v.nanoseconds);
      return new admin.firestore.Timestamp(s, ns);
    }
    if (v.__skType === "geopoint") {
      return new admin.firestore.GeoPoint(readNum(v.latitude), readNum(v.longitude));
    }
    if (v.__skType === "bytes") {
      const b64 = String(v.base64 || "");
      return Buffer.from(b64, "base64");
    }
  }

  if (isPlainObject(v)) {
    const out = {};
    for (const [k, vv] of Object.entries(v)) {
      out[k] = decodeFirestoreValue(db, vv);
    }
    return out;
  }

  return v;
}

async function writeJsonLine(stream, obj) {
  const line = JSON.stringify(obj) + "\n";
  if (!stream.write(line)) {
    await once(stream, "drain");
  }
}

async function writeDocTreeToStream({ docRef, stream, counts }) {
  const snap = await docRef.get();
  if (!snap.exists) return;

  const data = snap.data() || {};
  await writeJsonLine(stream, {
    type: "doc",
    path: docRef.path,
    data: encodeFirestoreValue(data),
  });
  counts.docs++;

  const subcols = await docRef.listCollections();
  for (const subcol of subcols) {
    const docsSnap = await subcol.get();
    for (const doc of docsSnap.docs) {
      await writeDocTreeToStream({
        docRef: doc.ref,
        stream,
        counts,
      });
    }
  }
}

exports.createFileBackup = onCall(
  {
    timeoutSeconds: 540,
    memory: "2GiB",
    enforceAppCheck: true,
  },
  async (request) => {
    const { callerUid } = await requireSuperAdminCaller(request);
    await requireMaintenanceModeEnabled();

    const db = admin.firestore();
    const data = request.data || {};
    const schoolId = String(data.schoolId || "").trim();
    const schoolIds = normalizeStringArray(data.schoolIds);
    const allSchools = normalizeBool(data.allSchools);

    const { targetSchoolIds, allSchools: resolvedAll } = await resolveTargetSchoolIds({
      db,
      schoolId,
      schoolIds,
      allSchools,
    });

    const backupFileId = newFileBackupId();
    const objectPath = `platform_backups/${backupFileId}.jsonl.gz`;

    const metaRef = db.collection("platformFileBackups").doc(backupFileId);
    await metaRef.set(
      {
        backupFileId,
        objectPath,
        status: "RUNNING",
        schoolIds: targetSchoolIds,
        allSchools: resolvedAll,
        createdByUid: callerUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const bucket = admin.storage().bucket();
    const file = bucket.file(objectPath);
    const gzip = zlib.createGzip();
    const writeStream = file.createWriteStream({
      resumable: false,
      metadata: {
        contentType: "application/gzip",
        cacheControl: "private, max-age=0, no-transform",
      },
    });

    gzip.pipe(writeStream);

    const counts = { docs: 0, schools: 0, users: 0, parentPhones: 0 };

    try {
      await writeJsonLine(gzip, {
        type: "meta",
        format: "sk_school_master.jsonl.gz",
        version: 1,
        createdAtMs: Date.now(),
        schoolIds: targetSchoolIds,
        allSchools: resolvedAll,
      });

      // Schools tree
      for (const sid of targetSchoolIds) {
        await writeDocTreeToStream({
          docRef: db.collection("schools").doc(sid),
          stream: gzip,
          counts,
        });
        counts.schools++;
      }

      // Users + subcollections (Firestore)
      for (const chunk of chunkArray(targetSchoolIds, 10)) {
        const usersSnap = await db
          .collection("users")
          .where("schoolId", "in", chunk)
          .get();
        for (const userDoc of usersSnap.docs) {
          await writeDocTreeToStream({
            docRef: userDoc.ref,
            stream: gzip,
            counts,
          });
          counts.users++;
        }
      }

      // Parent phone mappings
      for (const chunk of chunkArray(targetSchoolIds, 10)) {
        const phonesSnap = await db
          .collection("parentPhones")
          .where("schoolId", "in", chunk)
          .get();
        for (const doc of phonesSnap.docs) {
          await writeJsonLine(gzip, {
            type: "doc",
            path: doc.ref.path,
            data: encodeFirestoreValue(doc.data() || {}),
          });
          counts.docs++;
          counts.parentPhones++;
        }
      }

      gzip.end();
      await finished(writeStream);

      await metaRef.set(
        {
          status: "COMPLETED",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          counts,
          note:
            "Single-file Firestore backup (JSONL.GZ). Firebase Auth users/passwords are not included.",
        },
        { merge: true }
      );

      return {
        ok: true,
        backupFileId,
        objectPath,
        schoolIds: targetSchoolIds,
        allSchools: resolvedAll,
        counts,
      };
    } catch (e) {
      console.error("createFileBackup failed", e);
      try {
        gzip.destroy();
        writeStream.destroy();
      } catch (_) {}

      await metaRef.set(
        {
          status: "FAILED",
          error: String(e && e.message ? e.message : e),
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      throw e;
    }
  }
);

exports.listFileBackups = onCall({ enforceAppCheck: true }, async (request) => {
  await requireSuperAdminCaller(request);
  const db = admin.firestore();

  const snap = await db
    .collection("platformFileBackups")
    .orderBy("createdAt", "desc")
    .limit(25)
    .get();

  const backups = snap.docs.map((d) => {
    const data = d.data() || {};
    const createdAt = data.createdAt;
    const createdAtIso =
      createdAt && typeof createdAt.toDate === "function"
        ? createdAt.toDate().toISOString()
        : null;

    return {
      backupFileId: d.id,
      status: data.status || null,
      allSchools: data.allSchools === true,
      schoolIds: normalizeStringArray(data.schoolIds),
      objectPath: data.objectPath || null,
      counts: data.counts || null,
      createdByUid: data.createdByUid || null,
      createdAtIso,
      note: data.note || null,
    };
  });

  return { ok: true, backups };
});

exports.getFileBackupDownloadUrl = onCall({ enforceAppCheck: true }, async (request) => {
  await requireSuperAdminCaller(request);
  const db = admin.firestore();
  const data = request.data || {};
  const backupFileId = String(data.backupFileId || "").trim();
  if (!backupFileId) {
    throw new HttpsError("invalid-argument", "backupFileId is required");
  }

  const metaSnap = await db.collection("platformFileBackups").doc(backupFileId).get();
  if (!metaSnap.exists) {
    throw new HttpsError("not-found", "backupFileId not found");
  }
  const meta = metaSnap.data() || {};
  if (String(meta.status || "") !== "COMPLETED") {
    throw new HttpsError("failed-precondition", "Backup is not completed");
  }

  const objectPath = String(meta.objectPath || "").trim();
  if (!objectPath) {
    throw new HttpsError("failed-precondition", "Backup objectPath missing");
  }

  const bucket = admin.storage().bucket();
  const [url] = await bucket.file(objectPath).getSignedUrl({
    version: "v4",
    action: "read",
    expires: Date.now() + 15 * 60 * 1000,
  });

  return { ok: true, url, expiresInSeconds: 900 };
});

exports.restoreFileBackup = onCall(
  {
    timeoutSeconds: 540,
    memory: "2GiB",
    enforceAppCheck: true,
  },
  async (request) => {
    const { callerUid } = await requireSuperAdminCaller(request);
    await requireMaintenanceModeEnabled();

    const db = admin.firestore();
    const data = request.data || {};

    const backupFileId = String(data.backupFileId || "").trim();
    const restoreAll = normalizeBool(data.restoreAll);
    const schoolIds = normalizeStringArray(data.schoolIds);
    const confirmPhrase = String(data.confirmPhrase || "").trim();
    const overwriteConfirmed = normalizeBool(data.overwriteConfirmed);

    if (!backupFileId) {
      throw new HttpsError("invalid-argument", "backupFileId is required");
    }
    if (!overwriteConfirmed) {
      throw new HttpsError("failed-precondition", "overwriteConfirmed is required");
    }

    const metaRef = db.collection("platformFileBackups").doc(backupFileId);
    const metaSnap = await metaRef.get();
    if (!metaSnap.exists) {
      throw new HttpsError("not-found", "Backup not found");
    }
    const meta = metaSnap.data() || {};
    if (String(meta.status || "") !== "COMPLETED") {
      throw new HttpsError("failed-precondition", "Backup is not completed");
    }

    const backupSchoolIds = normalizeStringArray(meta.schoolIds);
    const targetSchoolIds = restoreAll ? backupSchoolIds : schoolIds;
    if (targetSchoolIds.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Provide schoolIds[] or restoreAll=true"
      );
    }

    const expected = expectedRestorePhrase({ restoreAll, targetSchoolIds }).toUpperCase();
    if (confirmPhrase.toUpperCase() !== expected) {
      throw new HttpsError(
        "failed-precondition",
        `Type the exact confirmation phrase: ${expected}`
      );
    }

    const objectPath = String(meta.objectPath || "").trim();
    if (!objectPath) {
      throw new HttpsError("failed-precondition", "Backup objectPath missing");
    }

    await db.collection("platformResetLogs").add({
      type: "restoreFileBackup",
      backupFileId,
      restoreAll,
      schoolIds: targetSchoolIds,
      requestedByUid: callerUid,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const targetSet = new Set(targetSchoolIds);

    const bw = db.bulkWriter();
    bw.onWriteError((err) => {
      console.error("BulkWriter error during restoreFileBackup", err);
      return err.failedAttempts < 5;
    });

    // 1) Delete existing data for target scope.
    for (const sid of targetSchoolIds) {
      const schoolRef = db.collection("schools").doc(sid);
      await deleteDocTree({ db, docRef: schoolRef, bw });

      const existingUsersSnap = await db
        .collection("users")
        .where("schoolId", "==", sid)
        .get();
      for (const doc of existingUsersSnap.docs) {
        const role = String((doc.data() || {}).role || "");
        if (role === "superAdmin") continue;
        await deleteDocTree({ db, docRef: doc.ref, bw });
      }

      const existingPhonesSnap = await db
        .collection("parentPhones")
        .where("schoolId", "==", sid)
        .get();
      for (const doc of existingPhonesSnap.docs) {
        bw.delete(doc.ref);
      }
    }

    // 2) Stream restore from JSONL.GZ.
    const bucket = admin.storage().bucket();
    const file = bucket.file(objectPath);

    const rl = readline.createInterface({
      input: file.createReadStream().pipe(zlib.createGunzip()),
      crlfDelay: Infinity,
    });

    const userSchoolByUid = new Map();
    let restoredDocs = 0;

    for await (const line of rl) {
      const trimmed = String(line || "").trim();
      if (!trimmed) continue;

      let obj;
      try {
        obj = JSON.parse(trimmed);
      } catch (_) {
        continue;
      }

      if (!obj || obj.type !== "doc") continue;
      const path = String(obj.path || "");
      if (!path) continue;

      const segments = path.split("/").filter(Boolean);
      if (segments.length < 2) continue;

      const top = segments[0];
      const id = segments[1];

      if (top === "schools") {
        if (!targetSet.has(id)) continue;
        const decoded = decodeFirestoreValue(db, obj.data || {});
        bw.set(db.doc(path), decoded, { merge: false });
        restoredDocs++;
        continue;
      }

      if (top === "users") {
        const uid = id;
        // Root doc first, then subcollections.
        if (segments.length === 2) {
          const decoded = decodeFirestoreValue(db, obj.data || {});
          const sid = String((decoded || {}).schoolId || "");
          if (!targetSet.has(sid)) {
            userSchoolByUid.set(uid, null);
            continue;
          }
          userSchoolByUid.set(uid, sid);
          bw.set(db.doc(path), decoded, { merge: false });
          restoredDocs++;
          continue;
        }

        const sid = userSchoolByUid.get(uid);
        if (!sid || !targetSet.has(sid)) continue;
        const decoded = decodeFirestoreValue(db, obj.data || {});
        bw.set(db.doc(path), decoded, { merge: false });
        restoredDocs++;
        continue;
      }

      if (top === "parentPhones") {
        const decoded = decodeFirestoreValue(db, obj.data || {});
        const sid = String((decoded || {}).schoolId || "");
        if (!targetSet.has(sid)) continue;
        bw.set(db.doc(path), decoded, { merge: false });
        restoredDocs++;
        continue;
      }
    }

    await bw.close();

    return {
      ok: true,
      backupFileId,
      restored: {
        schools: targetSchoolIds.length,
        docs: restoredDocs,
      },
      warning:
        "Restore copies Firestore data only. Firebase Auth users/passwords are not restored automatically.",
    };
  }
);

exports.resetSchoolData = onCall(
  {
    timeoutSeconds: 540,
    memory: "2GiB",
    enforceAppCheck: true,
  },
  async (request) => {
    const { callerUid } = await requireSuperAdminCaller(request);
    await requireMaintenanceModeEnabled();

    const data = request.data || {};
    const schoolId = String(data.schoolId || "").trim();
    const schoolIds = normalizeStringArray(data.schoolIds);
    const allSchools = normalizeBool(data.allSchools);
    const confirmPhrase = String(data.confirmPhrase || "").trim();
    const backupConfirmed = normalizeBool(data.backupConfirmed);
    const backupId = String(data.backupId || "").trim();
    const execute = normalizeBool(data.execute);
    const deleteAuthUsers = normalizeBool(data.deleteAuthUsers);

    const db = admin.firestore();
    const resolved = await resolveTargetSchoolIds({
      db,
      schoolId,
      schoolIds,
      allSchools,
    });
    const targetSchoolIds = resolved.targetSchoolIds;
    const isAll = resolved.allSchools;

    if (!backupConfirmed) {
      throw new HttpsError(
        "failed-precondition",
        "Backup confirmation is required"
      );
    }

    const expectedPhrase = expectedResetPhrase({ allSchools: isAll, targetSchoolIds }).toUpperCase();
    if (confirmPhrase.toUpperCase() !== expectedPhrase) {
      throw new HttpsError(
        "failed-precondition",
        `Type the exact confirmation phrase: ${expectedPhrase}`
      );
    }

    // Validate school existence (for selected schools).
    for (const sid of targetSchoolIds) {
      const schoolSnap = await db.collection("schools").doc(sid).get();
      if (!schoolSnap.exists) {
        throw new HttpsError("not-found", `School not found: ${sid}`);
      }
    }

    // Collect related docs for reporting / optional Auth deletion.
    let usersDocs = [];
    let phonesDocs = [];
    if (isAll) {
      const [u, p] = await Promise.all([
        db.collection("users").get(),
        db.collection("parentPhones").get(),
      ]);
      usersDocs = u.docs;
      phonesDocs = p.docs;
    } else {
      for (const chunk of chunkArray(targetSchoolIds, 10)) {
        const [u, p] = await Promise.all([
          db.collection("users").where("schoolId", "in", chunk).get(),
          db.collection("parentPhones").where("schoolId", "in", chunk).get(),
        ]);
        usersDocs.push(...u.docs);
        phonesDocs.push(...p.docs);
      }
    }

    // Never delete the caller and never delete superAdmin user docs.
    const affectedUserDocs = usersDocs.filter((d) => {
      if (d.id === callerUid) return false;
      const role = String((d.data() || {}).role || "");
      if (role === "superAdmin") return false;
      return true;
    });

    const affectedUserUids = affectedUserDocs
      .map((d) => d.id)
      .filter((uid) => uid && uid !== callerUid);

    // Preview mode (safe default). Returns the planned deletes.
    if (!execute) {
      return {
        ok: true,
        mode: "preview",
        allSchools: isAll,
        schoolIds: targetSchoolIds,
        willDelete: {
          schools: targetSchoolIds.length,
          userDocs: affectedUserDocs.length,
          parentPhoneMappings: phonesDocs.length,
          authUsers: deleteAuthUsers ? affectedUserUids.length : 0,
        },
        note:
          "Set execute=true to perform the reset. This action is destructive and cannot be undone.",
      };
    }

    // Enforce that a completed backup exists before executing.
    await requireCompletedBackup({
      db,
      backupId,
      targetSchoolIds,
      allSchools: isAll,
    });

    // Write an audit log (Admin SDK bypasses rules; client read not required).
    await db.collection("platformResetLogs").add({
      type: "resetSchoolData",
      schoolIds: targetSchoolIds,
      allSchools: isAll,
      backupId,
      backupConfirmed: true,
      deleteAuthUsers,
      requestedByUid: callerUid,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Perform deletes using BulkWriter + recursiveDelete.
    const bw = db.bulkWriter();
    bw.onWriteError((err) => {
      console.error("BulkWriter error during resetSchoolData", err);
      return err.failedAttempts < 5;
    });

    // Delete school subtrees.
    for (const sid of targetSchoolIds) {
      await db.recursiveDelete(db.collection("schools").doc(sid), bw);
    }

    // Delete users (and subcollections like notifications).
    for (const doc of affectedUserDocs) {
      await db.recursiveDelete(doc.ref, bw);
    }

    // Delete phone mappings.
    for (const doc of phonesDocs) {
      bw.delete(doc.ref);
    }

    await bw.close();

    // Optionally delete Auth users (never delete the caller).
    const authDeleteResults = [];
    if (deleteAuthUsers) {
      for (const uid of affectedUserUids) {
        try {
          await admin.auth().deleteUser(uid);
          authDeleteResults.push({ uid, ok: true });
        } catch (e) {
          // Auth deletion is best-effort. Firestore was already deleted above.
          authDeleteResults.push({ uid, ok: false, error: String(e) });
        }
      }
    }

    return {
      ok: true,
      mode: "execute",
      allSchools: isAll,
      schoolIds: targetSchoolIds,
      deleted: {
        schools: targetSchoolIds.length,
        userDocs: affectedUserDocs.length,
        parentPhoneMappings: phonesDocs.length,
        authUsersAttempted: deleteAuthUsers ? affectedUserUids.length : 0,
        authUsersDeleted: authDeleteResults.filter((r) => r.ok).length,
      },
      authUserDeleteFailures: authDeleteResults.filter((r) => !r.ok).slice(0, 25),
      warning:
        "Reset completed. If you deleted Auth users, some may fail if already removed or protected by provider. See authUserDeleteFailures.",
    };
  }
);

exports.changeParentPin = onCall({ enforceAppCheck: true }, async (request) => {
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

exports.createOrResetTeacherAccount = onCall({ enforceAppCheck: true }, async (request) => {
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
