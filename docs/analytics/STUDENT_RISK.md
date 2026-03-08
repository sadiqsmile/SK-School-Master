# Student Risk / Performance Prediction (v1)

This document defines the **Student Risk analytics** feature for SK School Master.

## Goal

Give principals and teachers **instant insights** (not tables) by computing risk signals automatically from:

- Attendance
- Exam marks
- Fees
- (Future) Homework completion

## Data model (Firestore)

All paths are under `schools/{schoolId}`.

### Per-student rolling inputs (system-managed)

#### Attendance rolling window (30 days)

`students/{studentId}/analytics/attendance_30d`

Fields:

- `windowDays`: `30`
- `days`: map of `{ "YYYY-MM-DD": "present|absent|late|leave" }`
- `lastDateKey`: string
- `updatedAt`: timestamp

> This doc is updated by Cloud Functions whenever attendance is marked.

#### Latest marks snapshot

`students/{studentId}/analytics/marks_latest`

Fields:

- `examId`: string
- `examTitle`: string (best-effort)
- `percent`: number (0–100)
- `updatedAt`: timestamp

#### Fees snapshot (best-effort)

`students/{studentId}/analytics/fees_latest`

Fields:

- `pendingAmount`: number
- `isPending`: bool
- `updatedAt`: timestamp

> If your fee documents later add `dueDate`, we can extend this to support "pending > 30 days".

### Risk index (fast query for dashboards)

`analytics/student_risk/students/{studentId}`

Fields:

- Identity:
  - `studentId`
  - `studentName`
  - `classId`, `sectionId`
  - `classKey`
- Metrics:
  - `attendancePercent30d`
  - `attendanceMarkedDays30d`
  - `marksPercentLatest`
  - `feesPendingAmount`
- Flags:
  - `lowAttendance`
  - `lowMarks`
  - `feePending`
  - `topPerformer`
- Risk:
  - `riskLevel`: `LOW | MEDIUM | HIGH`
  - `riskScore`: number (0–100)
  - `reasons`: array of strings
- Timestamps:
  - `createdAt`, `updatedAt`

### School summary (for principal cards)

`analytics/risk_summary`

Fields:

- `studentsHighRisk`
- `studentsMediumRisk`
- `studentsLowRisk`
- `feeDefaulters`
- `lowAttendance`
- `topPerformers`
- `updatedAt`

## Risk logic (v1)

Thresholds:

- Low attendance: `attendancePercent30d < 75`
- Low marks: `marksPercentLatest < 40`
- Fee pending: `feesPendingAmount > 0`

Risk level:

- If **2 or more** conditions are true → `HIGH`
- If **1** condition is true → `MEDIUM`
- If **0** conditions are true → `LOW`

Top performer (v1):

- `marksPercentLatest >= 80` AND `attendancePercent30d >= 90`

## Notes / limitations (v1)

- Homework “pending” is not yet tracked per student (no submission records). We can add this once homework submissions exist.
- The analytics docs are **system-managed** (Cloud Functions writes); clients should treat them as read-only.
