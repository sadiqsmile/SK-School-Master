# Setup on a second PC (School PC)

This repo is a Flutter + Firebase app. The goal is that **both PCs always have the exact same working code**.

## 0) Decide which branch you will use

- **Recommended for daily work:** `dev`
- **Production / stable:** `main`
- **Historical snapshot (do not develop here):** `webhosting-1` (tag: `webhosting-1-clean`)

If you are unsure: use **`dev`**.

## 1) Install prerequisites (once per PC)

1. **Git** (Windows)
2. **Flutter SDK** (stable channel)
3. (Optional) **Android Studio** + Android SDK (only if building Android)
4. (Optional) **Node.js 20** (only if you develop Firebase Functions under `functions/`)
  - This repo includes a `.nvmrc` pinned to Node 20 to match CI.

## 2) Clone the repo (once per PC)

Open PowerShell in the folder where you want the project:

- Clone
- Open the folder in VS Code

## 3) Get the exact same code as the other PC

In PowerShell, inside the repo:

- Fetch latest branches
- Checkout the branch you’re using (`dev` recommended)
- Pull

## 4) Install Flutter packages

From the repo root:

- Run `flutter pub get`

## 5) Run the app (Chrome)

- Run `flutter run -d chrome`

If you only need a web build:

- Run `flutter build web --release`

## 6) Firebase Hosting (optional)

This project uses Firebase Hosting (see `firebase.json`).

Typical flow:

1. Build Flutter web (`flutter build web --release`)
2. Deploy Hosting (`firebase deploy --only hosting`)

> Note: hosting deploy requires Firebase CLI login on that PC.

## 7) Golden rules so it never gets “mixed up” again

- Do **not** commit directly to `main`.
- Do work on `dev` (or a feature branch), then merge via PR.
- If you ever want to return to the exact historic snapshot:
  - checkout tag `webhosting-1-clean` (read-only)

## Troubleshooting

### I pulled but I still see the old UI

- Confirm you’re on the correct branch (`dev` or `main`).
- Do a hard refresh in Chrome (Ctrl+Shift+R).
- If running from hosting: open the site in an Incognito window.

### Flutter build complains about generated plugin registrants

Those are generated files. If they show as modified, it’s usually safe to discard local changes and continue.

### `npm ci` warns about unsupported Node engine

The Functions project expects **Node 20**. If you use a newer Node (e.g. Node 24), you may see warnings locally.
Use Node 20 for `functions/` to match CI and Firebase Functions runtime.
