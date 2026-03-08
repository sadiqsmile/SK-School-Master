# Deployment (Safest)

This repo contains:
- Flutter app (web/mobile)
- Firebase Hosting (web)
- Firebase Cloud Functions (Node 20)
- Firestore Security Rules
- Storage Security Rules

## Recommended release strategy

### Safest overall
1) **Deploy backend first**
   - Cloud Functions
   - Firestore rules (if changed)
2) **Then ship the client**
   - Hosting (web)
   - Mobile builds (Android/iOS)

Reason: the app UI can start calling new functions/routes immediately after release. If backend is not deployed yet, users will see errors.

### Even safer (when possible)
Use **two Firebase projects**:
- `staging` (auto-deploy on every merge to `main`)
- `production` (manual deploy with approvals)

This avoids testing risky rule/function changes directly in production.

## Local machine (Windows) safest deploy order

Always deploy with explicit `--project <projectId>` to avoid deploying to the wrong Firebase project.

1) Deploy Functions
- `firebase deploy --project <projectId> --only functions`

2) Deploy Firestore rules (only if you changed `firestore.rules`)
- `firebase deploy --project <projectId> --only firestore:rules`

2b) Deploy Storage rules (only after Storage is initialized)
- First-time only: Firebase Console → Storage → **Get started** (creates the default bucket)
- Then: `firebase deploy --project <projectId> --only storage`

3) Build and deploy Hosting
- `flutter build web --release`
- `firebase deploy --project <projectId> --only hosting`

## GitHub Actions (recommended)

This repo includes workflows:
- `.github/workflows/ci.yml` — analyze + test
- `.github/workflows/deploy-staging.yml` — deploy on `main` (staging)
- `.github/workflows/deploy-production.yml` — manual, requires typing `DEPLOY` and should be protected by GitHub Environment approvals

### Required GitHub secrets

Staging:
- `FIREBASE_PROJECT_ID_STAGING`

Production:
- `FIREBASE_PROJECT_ID_PROD`

Authentication (choose ONE option):

**Option A (preferred / safest): Workload Identity Federation (no long-lived key)**
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT_EMAIL`

**Option B (fallback): Service account JSON key**
- `GCP_SA_KEY`

### Optional GitHub variables
- `FLUTTER_VERSION` (pin Flutter for reproducible builds)
- `FIREBASE_TOOLS_VERSION` (pin firebase-tools)

## Operational safety for destructive actions

The backup/restore and reset tools require **Maintenance Mode**.

Recommended restore sequence:
1) Enable Maintenance Mode
2) Create a fresh backup (optional but recommended)
3) Restore
4) Verify app reads
5) Disable Maintenance Mode

> Note: Firestore backup/restore does not restore Firebase Auth users/passwords.

## App Check (recommended for production)

This app initializes **Firebase App Check**:
- Android (release): **Play Integrity**
- Android (debug): **Debug provider**

Cloud Functions callable endpoints are configured to **require App Check**.

### What to do in Firebase Console
1) Firebase Console → App Check → Register your Android app
2) Select **Play Integrity**
3) Turn on **enforcement** for:
   - Cloud Functions
   - Firestore (optional but recommended)

### Debug builds
If enforcement is enabled, debug builds must register a debug token (shown in logs) in Firebase Console → App Check.

## Google Sheets auto-sync (optional)

This repo includes a **Super Admin-only** Google Sheets export/sync feature.

### Is it enabled by default?
No. It is **disabled by default** because Google Sheets can easily become a data-leak vector (shared links, copied sheets, Drive permissions).

### Setup (one-time)
1) In Google Cloud Console for your Firebase project, **enable Google Sheets API**.
2) Create a spreadsheet in Google Drive.
3) Share the spreadsheet with your Cloud Functions service account email:
   - Typically: `<PROJECT_ID>@appspot.gserviceaccount.com`
4) In the app (Super Admin): open **Google Sheets Sync**, paste the spreadsheet ID, enable, and press **Sync now**.

Once enabled, the backend also runs a **daily auto-sync** (server-side) for all enabled schools.

### What gets exported
Tabs created/overwritten:
- `students`
- `teachers`
- `parents` (derived from student links; does not export `/users` auth fields)
- `fees`
- `marks`
- `attendance` (last N days; configurable; capped)

### Security notes
- Export runs **server-side** in Cloud Functions; no Google credentials are shipped in the APK.
- Callables require **App Check** and **Super Admin**.
- Attendance/marks exports are capped to avoid very large exports and accidental quota/latency spikes.

## Android (Play Store) releases

This repo is currently configured for **one Firebase project** (production) and **Android Play Store**.

### Release signing

Android release signing is configured in `android/app/build.gradle.kts`.

1) Create your upload keystore (or use an existing one).
2) Copy `android/key.properties.example` to `android/key.properties`.
3) Place the keystore under `android/` (for example: `android/upload-keystore.jks`).

`android/key.properties` is ignored by git (see `.gitignore`).

### Build the Play Store bundle (AAB)

Increment version in `pubspec.yaml` first (`version: x.y.z+build`).

Then build:
- `flutter build appbundle --release`

Output:
- `build/app/outputs/bundle/release/app-release.aab`

Upload the `.aab` to Play Console.

### Firebase deploy vs Play Store upload (important)

- **Firebase deploy** (Functions/Rules/Hosting) can be done independently of Play Store.
- Safest order when doing both for a release:
   1) Deploy backend (Functions, then Rules)
   2) Upload Android release to Play Store

### One Firebase project mode (today)

When you only have **one** Firebase project, avoid any "auto deploy on push" workflow.
This repo's staging workflow is manual-only for safety until you create a real staging project.
