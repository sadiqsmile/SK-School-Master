# Backfill guide

This app uses **role-based Firestore Rules** that rely on a few normalized fields:

- `students.classKey`
- `teachers.assignmentKeys`
- `exams.classKey`
- `homework.classKey`

If you have older data created before these fields were added, you must backfill.

## In-app backfill (recommended)

1. Log in as **Super Admin**.
2. Go to **Super Admin Dashboard → Maintenance**.
3. Select a school.
4. Run the backfill toggles you need.

This uses the app’s own Firebase credentials + security rules, so you don’t need Admin SDK secrets.

## Important note about parents

Parent scoping requires:

- `students.parentUid == currentParentUid`

This field cannot be reliably backfilled automatically unless you already store a stable mapping (e.g., parent UID, email, or phone) on the student document.
