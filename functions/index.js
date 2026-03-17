const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/// 🔥 RESET USER PASSWORD FUNCTION
exports.resetUserPassword = functions.https.onCall(async (data, context) => {
  try {
    const uid = data.uid;
    const newPassword = data.newPassword;

    if (!uid || !newPassword) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "UID and password required"
      );
    }

    await admin.auth().updateUser(uid, {
      password: newPassword,
    });

    return { success: true };

  } catch (error) {
    console.error("RESET ERROR:", error);

    throw new functions.https.HttpsError(
      "internal",
      error.message
    );
  }
});


exports.deleteSchoolCompletely = functions.https.onCall(async (data, context) => {
  const schoolId = data.schoolId;

  if (!schoolId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "School ID required"
    );
  }

  const db = admin.firestore();

  try {
    const schoolRef = db.collection("schools").doc(schoolId);

    /// 🔥 DELETE SUBCOLLECTIONS
    const collections = [
      "students",
      "teachers",
      "classes",
      "academicYears",
    ];

    for (const col of collections) {
      const snapshot = await schoolRef.collection(col).get();

      const batch = db.batch();

      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
    }

    /// 🔥 DELETE MAIN SCHOOL
    await schoolRef.delete();

    return { success: true };

  } catch (error) {
    console.error(error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});