# Firestore schema (production)

This document describes the intended Firestore layout for **SK School Master**.

## Top-level collections

### `users/{uid}`

Authentication profile for a user.

Suggested fields:

- `role`: `super_admin | admin | teacher | parent`
- `schoolId`: string (not required for `super_admin`)
- `email`: string (optional)
- `mustChangePassword`: bool (teacher/parent onboarding)
- `createdAt`, `updatedAt`: timestamps

### `schools/{schoolId}`

Tenant root document. Subcollections hold tenant data.

Common fields:

- `name` / `schoolName`
- `subscriptionPlan`
- `createdAt`

## Tenant subcollections

All paths below are under `schools/{schoolId}/…`

### `students/{studentId}`

Key fields used by rules and queries:

- `name`
- `admissionNo`
- `classId`
- `section`
- `classKey` (required for strict teacher scoping)
- `parentUid` (required for parent scoping)

`classKey` should be generated using the shared helper:

- `classKeyFrom(classId, section)` → `class_{sanitizedClassId}_{sanitizedSection}`

### `teachers/{teacherId}`

Key fields:

- `name`
- `email`, `phone` (optional)
- `classes`: array of `{ classId, sectionId/section, className?, sectionName? }`
- `assignmentKeys`: array of strings (`classKeyFrom(classId, sectionId)` for each assignment)

### `attendance/{dateKey}`

Date document: `dateKey` is `YYYY-MM-DD`.

- `meta/{classKey}`: lock + counts (prevents duplicate submission)
- `{classKey}/{studentId}`: per-student attendance docs

### `homework/{homeworkId}`

Key fields:

- `classId`, `section`, `classKey`
- `subject`, `description`, `dueDate`
- `teacherId`

### `exams/{examId}`

Key fields:

- `examType`, `examName` (+ legacy `name` for backward compatibility)
- `classId`, `section`, `classKey`
- `subjectMaxMarks`: `{ subjectKey: maxMarks }`
- `createdAt`

Subcollection:

- `marks/{studentId}`: `{ subjectMarks: { subjectKey: mark }, updatedAt }`

### `studentFees/{feeDocId}`

Key fields:

- `studentId`
- `amount`, `paidAmount`, `balance` (or `pendingAmount`)
- `status`

### `announcements/{announcementId}`

Key fields:

- `title`, `message`
- `target`: `all | teachers | class_{classId}_{sectionId}`
- `createdBy`, `createdAt`

## Platform collection

### `platform/config`

Super-admin only.

Example fields:

- `totalSchools`
- `totalStudents`

## Aggregated / indexed data (performance layer)

To keep dashboards fast at scale, we maintain **pre-aggregated counters and summaries**.

### Per-school counters (stored on the school doc)

On: `schools/{schoolId}`

- `totalStudents`: number (maintained by Cloud Functions)
- `totalTeachers`: number (maintained by Cloud Functions)
- `totalClasses`: number (maintained by Cloud Functions)

### Latest attendance summary (stored on the school doc)

On: `schools/{schoolId}`

- `attendanceLatestDateKey`: `YYYY-MM-DD`
- `attendanceLatest`: object
	- `dateKey`
	- `present`, `absent`, `late`, `leave`, `total`
	- `classesMarked`

This is updated whenever an attendance meta-lock is written under:

`schools/{schoolId}/attendance/{dateKey}/meta/{classKey}`

### Historical attendance daily totals (optional)

`schools/{schoolId}/analytics/attendance_daily/days/{dateKey}`

Fields:

- `dateKey`
- `present`, `absent`, `late`, `leave`, `total`
- `classesMarked`
- `updatedAt`
