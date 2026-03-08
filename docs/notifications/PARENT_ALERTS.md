# Parent alerts (design)

Parents should be notified when their child enters **HIGH risk**.

## Why this needs a separate feed

A school-wide notifications collection (e.g. `schools/{schoolId}/notifications`) cannot safely contain parent alerts because parents would be able to read alerts for other students.

Therefore parent alerts must be stored in a **per-parent** or **per-student** secured location.

## Recommended storage (v1)

### Option A — Per-user feed (recommended)

`users/{parentUid}/notifications/{notificationId}`

Security rules:

- read: only `uid == request.auth.uid`
- write: disallowed (Cloud Functions only)

Payload example:

- `type`: `child_high_risk`
- `title`: `Your child needs attention`
- `body`: `Attendance is low. Please contact the class teacher.`
- `schoolId`, `studentId`
- `createdAt`

### Option B — Per-student feed

`schools/{schoolId}/students/{studentId}/parentAlerts/{alertId}`

This requires new Firestore rules that allow **only the linked parent** (via `students/{studentId}.parentUid`) to read.

## Trigger logic

Cloud Function should:

- Detect risk transition: previous riskLevel != HIGH AND new riskLevel == HIGH
- Find `parentUid` from `schools/{schoolId}/students/{studentId}`
- Write a notification to the chosen path

## Delivery channels (future)

- In-app (push) using FCM
- WhatsApp / SMS via external provider

For WhatsApp/SMS you still keep a Firestore record of what was sent (for audit), but the actual delivery is out-of-band.
