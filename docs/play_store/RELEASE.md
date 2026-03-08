# Android release (AAB) checklist

## 1) Set a real Android applicationId

Current: `com.sk.schoolmaster`

Before Play Store you must ensure this is your unique package name.

Location:

- `android/app/build.gradle.kts` → `defaultConfig.applicationId`
- `android/app/build.gradle.kts` → `android.namespace` (should match)

Warning: Changing the applicationId creates a new app identity on Android.

## 2) Create upload keystore

Use Android Studio or `keytool` to generate a `.jks` keystore.

Place it in:

- `android/upload-keystore.jks` (or any path you prefer)

## 3) Configure `key.properties`

Create:

- `android/key.properties`

Example contents:

- `storePassword=...`
- `keyPassword=...`
- `keyAlias=...`
- `storeFile=../upload-keystore.jks`

Note: In this project, `storeFile` is resolved relative to `android/app/`,
so `../upload-keystore.jks` points to `android/upload-keystore.jks`.

This file is already ignored by git via `android/.gitignore`.

## 4) Build the App Bundle

Build output:

- `build/app/outputs/bundle/release/app-release.aab`

## 5) Versioning

Update `pubspec.yaml`:

- `version: x.y.z+NN`

Where `x.y.z` is the user-visible versionName, and `NN` is an incrementing versionCode.
