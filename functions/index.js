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


