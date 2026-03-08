# Notifications schema (draft)

This document describes the **in-app notifications feed** for SK School Master.

## Goals

- Provide a fast, per-school notification stream for admins/teachers (and later parents).
- Keep it tenant-scoped (no cross-school access).
- System-managed writes (Cloud Functions / Admin SDK), read-only for clients.

## Firestore paths

All paths are under:

`schools/{schoolId}/notifications/{notificationId}`

## Recommended fields

Common fields:

- `type`: string (e.g. `attendance_marked`, `fee_overdue`, `homework_posted`)
- `title`: string
- `body`: string
- `audience`: object
  - `roles`: array of strings, e.g. `["admin", "teacher"]`
  - (future) `classKeys`: array of strings, for teacher-targeted class notifications
  - (future) `userIds`: array of UIDs, for direct notifications
- `createdAt`: timestamp
- `updatedAt`: timestamp

Optional fields (per type):

- `dateKey`: `YYYY-MM-DD`
- `classKey`: string
- `markedBy`: uid
- `counts`: map
  - `present`, `absent`, `late`, `leave`, `total`

## Client query patterns

Typical feed query:

- Order by `createdAt desc`
- Limit 50
- Filter by role on the client (since audience logic may evolve)

## Security rules

- **Read**: any school member (or super admin).
- **Write**: disallowed (clients cannot write).

Cloud Functions (Admin SDK) can write regardless of rules.
