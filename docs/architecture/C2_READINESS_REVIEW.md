# HOMESETS — Architecture & Technical Readiness Review (C2 Preflight)

**Document Status:** [Final Preflight]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-14  
**Target Milestone:** Campaign C2 (Plan Engine & Database Foundation)  
**Authority Reference:** `docs/MASTER_PROJECT_INITIALIZATION_PROMPT.txt` §9, `docs/DECISION_REGISTER.md` (D01, D02, D17, D18, GOV08)  

---

## 1. Executive Summary

This readiness review establishes the technical boundaries, storage rules, dependency candidates, and safety invariants required before initializing **Campaign C2 (Pure-Dart Workout Plan Engine & Local Database Foundation)**. 

No Flutter production code or runtime dependencies are introduced in this phase. This document serves as the binding technical blueprint for the subsequent implementation campaign.

---

## 2. Staged Restore & Database Transactional Boundaries

In accordance with Product Rule §2 (Offline & Privacy) and Decision D02 (Encrypted Local Backups), database restore operations must never perform an in-place destructive overwrite without isolated pre-flight verification.

```text
[ Backup File (.hsbk / .zip) ]
          │
          ▼
┌────────────────────────────────────────┐
│  Phase 1: Temp Staging Sandbox         │
│  - Extract to cacheDir/restore_staging │
│  - Check SHA-256 header checksum       │
│  - Verify schema version compatibility │
└───────────────────┬────────────────────┘
                    │ Valid
                    ▼
┌────────────────────────────────────────┐
│  Phase 2: Database Integrity Check     │
│  - Open staging DB in read-only mode   │
│  - Execute PRAGMA integrity_check      │
│  - Query core tables (users, sets, etc)│
└───────────────────┬────────────────────┘
                    │ Valid
                    ▼
┌────────────────────────────────────────┐
│  Phase 3: Atomic Database Swap         │
│  - Close active Drift database pool    │
│  - Rename active DB -> active.db.bak   │
│  - Move staging DB -> active.db        │
│  - Reconnect connection pool           │
│  - On success: delete active.db.bak    │
│  - On failure: rollback to .bak        │
└────────────────────────────────────────┘
```

### 2.1 Failure Safeguards
- If checksum validation or `PRAGMA integrity_check` fails, the active database remains 100% untouched.
- Staging artifacts are purged immediately.
- The user is notified with an actionable error modal (Modeled in `design/ux/edge_states_wireframe.html`).

---

## 3. Android 12+ / Android 16 Storage & Extraction Policy

To protect user physique photos and workout history from unauthorized extraction:

1. **Manifest Backup Suppression:**
   ```xml
   android:allowBackup="false"
   android:fullBackupContent="false"
   ```
   Prevents unencrypted Android Cloud ADB / Google Drive auto-backups from extracting local files without the user's manual password-protected export.

2. **Scoped App-Private Directory:**
   - All private physique photos and local SQLite files must reside strictly inside:
     `Context.getFilesDir()` (mapped via `path_provider` to `getApplicationDocumentsDirectory()`).
   - Photos must **never** be written to public media stores (`MediaStore.Images`, `DCIM`, `Pictures`, or external shared storage).
   - Media stored within app-private directories is completely inaccessible to third-party applications on non-rooted devices and excluded from OS gallery scrapers.

---

## 4. pub.dev Candidate Version Locking (Nov 2026 Compatibility)

The following packages are pre-evaluated candidates for Campaign C2. In compliance with Campaign Rules, **no dependencies are added to `pubspec.yaml` in this commit**. These versions are locked for Product Owner review:

| Package Name | Candidate Version | Purpose in C2 | Justification & Offline Suitability |
| :--- | :--- | :--- | :--- |
| `drift` | `^2.24.0` | Relational SQLite ORM | Compile-time SQL verification, type-safe queries, zero runtime network dependencies. |
| `drift_flutter` | `^0.2.0` | Drift Flutter integration | Official Flutter package for database connection and file management. |
| `sqlite3_flutter_libs` | `^0.5.24` | Bundled SQLite C binaries | Embeds latest native SQLite3 across Android ABIs (arm64-v8a, armeabi-v7a, x86_64). |
| `path_provider` | `^2.1.5` | Platform file paths | Accesses app-private storage directory safely across Android versions. |
| `uuid` | `^4.5.1` | Entity ID Generation | Offline deterministic RFC-4122 UUID v4 generation for sessions and sets. |
| `crypto` | `^3.0.6` | Backup Checksums | Pure-Dart SHA-256 calculation for backup verification and integrity checks. |
| `intl` | `^0.20.1` | Date & BiDi Formatting | Standard Flutter localization and number/currency/date formatting. |

---

## 5. Pure-Dart Plan Engine Architectural Boundary

To guarantee sub-second execution of test suites and eliminate UI coupling, the workout plan engine lives in `lib/domain/engine/`:

```text
lib/domain/engine/
├── models/             # Immutable data records (Exercise, WorkoutRoutine, SetLog)
├── progression/        # Double progression algorithms (reps bracket, load increment)
├── fatigue/            # Fatigue tracking, RPE/exertion feedback processing
├── scheduling/         # Muscle recovery spacing (24-48h), rotation order
└── safety/             # Pain stop filters, joint avoidance rules, deload on absence
```

### Architectural Guardrail:
- **Zero Flutter Imports:** Files in `lib/domain/engine/` must not import `package:flutter/...` or `dart:ui`.
- **Zero Database Imports:** Files in `lib/domain/engine/` must receive pure Dart entity models, returning pure calculated domain structures.
- **Verification Rule:** CI Step 2 will enforce this boundary via custom static analysis or directory-level lint checks.
