# Temporary reports (generated files) — design

This is the intended design for **reports as temporary generated files**, not permanently stored records.

## Goals

- Generate reports on-demand (PDF/Excel/CSV) for admins.
- Avoid permanent “report documents” in Firestore.
- Keep large exports out of the mobile client to prevent crashes/timeouts.

## Recommended approach

### 1) Request report generation (callable)

Use a Cloud Function callable like:

- `generateReport` (callable)
  - inputs: `schoolId`, `type`, `filters`, `format`
  - validates: caller role + school scoping

The function should:

- Query Firestore for source data (ideally using aggregated/indexed paths where possible).
- Generate a file (PDF/Excel) server-side.

### 2) Store the file temporarily

Use **Cloud Storage** as the temporary file store:

- Bucket path: `tmpReports/{schoolId}/{uid}/{reportId}.{ext}`
- Save metadata as **custom metadata** (createdAt, expiresAt, type), or in Firestore under a temp collection.

Important: Storage objects are not “permanent app data” — they can be automatically deleted.

### 3) Return a download URL

Return either:

- a short-lived signed URL, or
- a Storage download token URL (less ideal), or
- a Firebase Hosting endpoint that streams the file.

For signed URLs, prefer short expiry (e.g. 5–30 minutes).

### 4) Auto-cleanup (TTL)

Cleanup options:

- **GCS lifecycle rule**: delete objects under `tmpReports/` older than N days/hours (recommended).
- Scheduled function: scan and delete expired objects.

## Data minimization

- Only include fields needed for the report.
- Avoid exporting sensitive columns by default (phone numbers, etc.).
- Add an explicit “include sensitive data” toggle that only super admins can use.

## Suggested report types (initial)

- Attendance summary (day / range)
- Student list (class/section)
- Fee status (paid vs due)
- Homework summary

## Notes for the Flutter app

- Client triggers generation and shows progress.
- Once URL returned, open download / share intent.
- Do not try to generate Excel/PDF on the phone for large datasets.
