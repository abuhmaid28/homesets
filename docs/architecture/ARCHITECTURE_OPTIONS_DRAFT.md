# HOMESETS — Architecture & Technical Options Draft (Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G6 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)
**Authority Reference:** `docs/MASTER_PROJECT_INITIALIZATION_PROMPT.txt` §9, `docs/DECISION_REGISTER.md` (D01, D02, D17, D18, GOV08)

---

## 1. Architectural Strategy: Clean Feature-First Layering

HOMESETS is structured using a strict **feature-first, layered architecture** designed for extreme testability, total offline autonomy, and isolation of core fitness progression logic from UI frameworks.

```text
lib/
├── core/
│   ├── theme/           # Design tokens, ThemeExtensions (Colors, Typography, Spacing)
│   ├── localization/    # Flutter gen-l10n (Arabic RTL default, English LTR)
│   ├── database/        # Local SQLite typed database layer & migrations
│   └── errors/          # Domain failure and exception definitions
│
├── domain/engine/       # PURE DART PLAN ENGINE (Zero Flutter / UI / DB dependencies)
│   ├── models/          # Exercise, Program, Session, SetLog, RecoveryRule
│   ├── progression/     # Double progression ladder & overload algorithms
│   ├── scheduling/      # Muscle recovery spacing (24-48h), rotation order
│   └── safety/          # Pain/injury exclusion filters, absence re-entry deload
│
├── features/            # Feature slices (Presentation + State Management)
│   ├── onboarding/      # Initial stats, equipment setup, avoid areas
│   ├── today/           # Next workout presentation, Lite mode CTA, consistency ring
│   ├── workout/         # Player screen, rest timer, one-handed rep stepper
│   ├── progress/        # Private photos, weight trend chart, strength curves, meals
│   └── settings/        # Backup/restore, reminders, language, theme, reset
│
└── app.dart             # Root MaterialApp.router configuration
```

---

## 2. Pure-Dart Workout Plan Engine (Core Isolation)

### 2.1 The Zero-Dependency Rule
The directory `lib/domain/engine/` is strictly prohibited from importing:
- `package:flutter/...`
- `package:drift/...` or `package:sqflite/...`
- Any platform channel or plugin.

### 2.2 Why This Matters
1. **100% Deterministic Execution:** Given a specific user profile (equipment, avoided joints, past set logs), the engine generates identical, verifiable workout structures.
2. **Lightning-Fast Pure Unit Tests:** Over 100+ unit test scenarios (double progression, fatigue deload, 7+ days absence volume reduction) run in < 2 seconds on developer workstations and CI runners without launching Flutter widget harnesses or Android emulators.

---

## 3. Local Persistence Evaluation: Drift vs. Sqflite

HOMESETS requires a local, zero-recurring-cost relational database that supports typed queries and rigorous schema migrations from day one.

| Criterion | Candidate A: Drift (`drift` + `drift_flutter`) | Candidate B: Sqflite (`sqflite`) | Analysis & Recommendation |
| :--- | :--- | :--- | :--- |
| **Type Safety** | Compile-time generated Dart classes from SQL or Dart DSL. | Untyped `Map<String, dynamic>` maps; runtime query validation. | **Drift wins**: Compile-time schema checking prevents typo crashes in column names. |
| **Reactive Streams** | Built-in `watch()` queries auto-updating UI when rows change. | Manual event bus or custom stream controllers required. | **Drift wins**: Effortless auto-updating for consistency ring and workout logs. |
| **Migration Tooling** | `drift_dev` schema verification tests against SQLite files. | Manual `onUpgrade` raw SQL scripts without automated schema diffing. | **Drift wins**: Robust migration verification tests protect user data across APK updates. |
| **License & Maintenance** | MIT License, active maintenance by Simon Binder. | BSD-2-Clause, mature maintenance by Alexandre Roux. | Both are open-source and free for commercial/private use. |
| **Recommendation** | **[Recommended Candidate for G6 Review]** | Fallback alternative if code-gen is avoided. | **Drift is recommended for its compile-time safety and migration testing.** |

*Note:* No package will be added to `pubspec.yaml` until formal PO approval at Gate G6.

---

## 4. Private Progress Photo Storage Architecture

### 4.1 Threat Model & Privacy Constraint [D13, D18]
Ahmed's physique progress photos are highly personal. They must **never leak to Google Photos, the Honor Gallery, cloud backup, or public storage**.

### 4.2 Storage Implementation
- **Directory Path:** Photos are saved strictly in the application sandbox internal directory:
  `Context.getFilesDir() / "private_photos" / "{uuid}.png"`.
- **MediaStore Isolation:** Never written to `Environment.getExternalStoragePublicDirectory()` or `DCIM/`.
- **Android Backup Exclusion:** In `android/app/src/main/res/xml/backup_rules.xml`, explicitly exclude `private_photos/` from automatic Google Drive / Android Cloud backup to ensure zero cloud sync:
  ```xml
  <exclude path="private_photos/" />
  ```
- **Lifecycle & Cleanup:** When a photo entry is deleted from the database by the user, the underlying file on disk is immediately deleted (`file.deleteSync()`).

---

## 5. Single-File Manual Backup & Restore Architecture

### 5.1 Archive Specification (`.homesets`)
The backup file is a standard compressed ZIP archive with extension `.homesets`:
```text
homesets_backup_20261114_153000.homesets (ZIP Archive)
├── manifest.json        # Schema version, export timestamp, app version, SHA-256 hash
├── database_dump.json   # Relational table records exported in versioned JSON format
└── photos/              # Compressed private progress photo PNG binaries
      ├── photo_uuid_1.png
      └── photo_uuid_2.png
```

### 5.2 Validated Restore Pipeline
Before touching the active SQLite database during an import:
1. **Unzip to Temp Sandbox:** Decompress into an isolated cache directory.
2. **Validate Manifest & Checksum:** Verify manifest presence, check SHA-256 hash against payload.
3. **Schema Compatibility Check:**
   - If `manifest.schema_version > app.current_schema_version`: Abort with error ("Backup created by newer app version. Please update the app").
   - If `manifest.schema_version <= app.current_schema_version`: Proceed with forward migration.
4. **Atomic Transaction:** Replace active database within a single SQLite transaction. If any photo or table record fails integrity check, rollback to existing state completely.

---

## 6. Android 16 & MagicOS 10 Platform Constraints

Ahmed's target device is the **Honor X9e Pro running MagicOS 10 based on Android 16**.

### 6.1 Local Reminder Scheduling (`flutter_local_notifications`)
1. **Notification Runtime Permission:** On Android 13+ (API 33+), the app must request `POST_NOTIFICATIONS` at runtime before scheduling.
2. **Exact Alarms (`SCHEDULE_EXACT_ALARM`):** MagicOS aggressively throttles background alarms to preserve battery.
   - For a daily 3:30 PM reminder, inexact repeating alarms (`AndroidAlarmManager` or `WorkManager`) with a $\pm 15$ min window are preferred to prevent permission rejections.
   - App settings must display a friendly help link guiding Ahmed to set HOMESETS to "Manual Launch / Ignore Battery Optimization" in MagicOS settings if notifications are delayed.

### 6.2 Zero-Network Constraint
The `AndroidManifest.xml` file will **completely omit `android.permission.INTERNET`**.
- This provides an absolute, operating-system-level cryptographic guarantee that the application cannot send telemetry, photos, or logs to any external server.

---

## 7. Private Release APK Signing Strategy

### 7.1 Keystore Security Rules
- The production signing keystore (`homesets-release.jks`) must **never be committed to Git**.
- Keystore properties (`keyAlias`, `password`) are passed via local developer environment variables or a local untracked `key.properties`.
- A secure offline backup of the release key must be preserved by Ahmed. If the release key is lost, new APKs cannot be updated over installed versions without losing all local workout data.
