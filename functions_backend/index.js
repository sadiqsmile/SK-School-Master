const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

async function requireSuperAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();

  if (!callerDoc.exists) {
    throw new HttpsError("permission-denied", "Caller user document not found.");
  }

  const callerData = callerDoc.data() || {};
  if (callerData.role !== "superAdmin") {
    throw new HttpsError("permission-denied", "Only super admin can do this.");
  }
}

exports.createSchoolWithAdmin = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      await requireSuperAdmin(request);

      const data = request.data || {};

      const name = (data.name || "").toString().trim().toUpperCase();
      const email = (data.email || "").toString().trim().toLowerCase();
      const phone = (data.phone || "").toString().trim();
      const logo = (data.logo || "").toString().trim();
      const logoPath = (data.logoPath || "").toString().trim();
      const themeColorPrimary =
          (data.themeColorPrimary || "#4facfe").toString();
      const themeColorSecondary =
          (data.themeColorSecondary || "#00f2fe").toString();

      if (!name || !email || !phone || !email.includes("@")) {
        throw new HttpsError("invalid-argument", "Missing required fields.");
      }

      const defaultPassword =
  email.length >= 6 ? email.substring(0, 6) : email.padEnd(6, "0");

      let authUser;
      try {
        authUser = await admin.auth().getUserByEmail(email);
      } catch (_) {
        authUser = await admin.auth().createUser({
          email,
          password: defaultPassword,
          displayName: name,
        });
      }

      const schoolRef = await admin.firestore().collection("schools").add({
        name,
        email,
        phone,
        logo,
        logoPath,
        themeColorPrimary,
        themeColorSecondary,
        archived: false,
        mustChangePassword: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await admin.firestore().collection("users").doc(authUser.uid).set(
        {
          name,
          email,
          phone,
          role: "admin",
          schoolId: schoolRef.id,
          status: "active",
          mustChangePassword: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return {
        success: true,
        schoolId: schoolRef.id,
        uid: authUser.uid,
        email,
        tempPassword: defaultPassword,
      };
    } catch (error) {
      logger.error("createSchoolWithAdmin error", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Something went wrong.");
    }
  }
);
exports.resetSchoolAdminPassword = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      await requireSuperAdmin(request);

      const data = request.data || {};
      const schoolId = (data.schoolId || "").toString().trim();

      if (!schoolId) {
        throw new HttpsError("invalid-argument", "schoolId is required.");
      }

      const schoolDoc = await admin
        .firestore()
        .collection("schools")
        .doc(schoolId)
        .get();

      if (!schoolDoc.exists) {
        throw new HttpsError("not-found", "School not found.");
      }

      const schoolData = schoolDoc.data() || {};
      const adminEmail = (schoolData.email || "").toString().trim().toLowerCase();
      const schoolName = (schoolData.name || "School Admin").toString().trim();
      const phone = (schoolData.phone || "").toString().trim();

      if (!adminEmail || !adminEmail.includes("@")) {
        throw new HttpsError(
          "failed-precondition",
          "School admin email not found."
        );
      }

      const tempPassword =
        adminEmail.length >= 6 ? adminEmail.substring(0, 6) : adminEmail.padEnd(6, "0");

      let userRecord;

      try {
        userRecord = await admin.auth().getUserByEmail(adminEmail);
      } catch (_) {
        userRecord = await admin.auth().createUser({
          email: adminEmail,
          password: tempPassword,
          displayName: schoolName,
        });
      }

      await admin.auth().updateUser(userRecord.uid, {
        password: tempPassword,
      });

      await admin.firestore().collection("users").doc(userRecord.uid).set(
        {
          name: schoolName,
          email: adminEmail,
          phone,
          role: "admin",
          schoolId,
          status: "active",
          mustChangePassword: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await admin.firestore().collection("schools").doc(schoolId).update({
        mustChangePassword: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        email: adminEmail,
        tempPassword,
      };
    } catch (error) {
      logger.error("resetSchoolAdminPassword error", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Something went wrong.");
    }
  }
);


exports.deleteSchoolCompletely = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      await requireSuperAdmin(request);

      const data = request.data || {};
      const schoolId = (data.schoolId || "").toString().trim();

      if (!schoolId) {
        throw new HttpsError("invalid-argument", "schoolId is required.");
      }

      const schoolRef = admin.firestore().collection("schools").doc(schoolId);
      const schoolDoc = await schoolRef.get();

      if (!schoolDoc.exists) {
        throw new HttpsError("not-found", "School not found.");
      }

      const schoolData = schoolDoc.data() || {};
      const adminEmail = (schoolData.email || "").toString().trim().toLowerCase();
      const logoPath = (schoolData.logoPath || "").toString().trim();

      const usersSnap = await admin
        .firestore()
        .collection("users")
        .where("schoolId", "==", schoolId)
        .get();

      for (const userDoc of usersSnap.docs) {
        const userData = userDoc.data() || {};
        const role = (userData.role || "").toString();

        if (role !== "superAdmin") {
          try {
            await admin.auth().deleteUser(userDoc.id);
          } catch (e) {
            logger.warn("Auth delete by uid failed", { uid: userDoc.id, error: e.message });
          }

          try {
            await userDoc.ref.delete();
          } catch (e) {
            logger.warn("User doc delete failed", { uid: userDoc.id, error: e.message });
          }
        }
      }

      if (adminEmail) {
        try {
          const authUser = await admin.auth().getUserByEmail(adminEmail);
          try {
            await admin.auth().deleteUser(authUser.uid);
          } catch (e) {
            logger.warn("Auth delete by email user uid failed", {
              uid: authUser.uid,
              error: e.message,
            });
          }

          try {
            await admin.firestore().collection("users").doc(authUser.uid).delete();
          } catch (e) {
            logger.warn("Users doc delete by auth uid failed", {
              uid: authUser.uid,
              error: e.message,
            });
          }
        } catch (e) {
          logger.warn("No auth user found by admin email during delete", {
            adminEmail,
            error: e.message,
          });
        }
      }

      if (logoPath) {
        try {
          await admin.storage().bucket().file(logoPath).delete();
        } catch (e) {
          logger.warn("Logo delete failed", { logoPath, error: e.message });
        }
      }

      await schoolRef.delete();

      return {
        success: true,
        schoolId,
      };
    } catch (error) {
      logger.error("deleteSchoolCompletely error", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Something went wrong.");
    }
  }
);