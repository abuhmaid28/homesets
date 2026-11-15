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
2. **Sub-Second Test Execution:** Because it has zero Flutter or database dependencies, the entire unit test suite executes rapidly on developer workstations and CI runners without launching Flutter widget harnesses or Android emulators.

---

## 3. Local Persistence Evaluation: Drift vs. Sqflite

HOMESETS requires a local, zero-recurring-cost relational database that supports typed queries and rigorous schema migrations from day one.

| Criterion | Candidate A: Drift (`drift` + `drift_flutter`) | Candidate B: Sqflite (`sqflite`) | Analysis & Recommendation |
| :--- | :--- | :--- | :--- |
| **Type Safety** | Compile-time generated Dart classes from SQL or Dart DSL. | Untyped `Map<String, dynamic>` maps; runtime query validation. | **Drift wins**: Compile-time schema checking prevents typo crashes in column names. |
| **Reactive Streams** | Built-in `watch()` queries auto-updating UI when rows change. | Manual event bus or custom stream controllers required. | **Drift wins**: Effortless auto-updating for consistency ring and workout logs. |
| **Migration Tooling** | `drift_dev` schema verification tests against SQLite files. | Manual `onUpgrade` raw SQL scripts without automated schema diffing. | **Drift wins**: Robust migration verification tests protect user data across APK updates. |
| **License & Maintenance** | MIT License, active maintenance by Simon Binder (v2.35.x on pub.dev, 2026). | BSD-2-Clause, mature maintenance by Alexandre Roux. | Both are open-source and free for commercial/private use. |
| **Recommendation** | **[Recommended Candidate for G6 Review]** | Fallback alternative if code-gen is avoided. | **Drift is recommended for its compile-time safety and migration testing.** |

*Note:* No package will be added to `pubspec.yaml` until formal PO approval at Gate G6.

---

## 4. Private Progress Photo Storage & Android Backup Architecture

### 4.1 Threat Model & Privacy Constraint [D13, D18]
Ahmed's physique progress photos are highly personal. They must **never leak to Google Photos, the Honor Gallery, automated cloud backup, or public storage**.

### 4.2 Storage Implementation
- **Directory Path:** Photos are saved strictly in the application sandbox internal directory:
  `Context.getFilesDir() / "private_photos" / "{uuid}.png"`.
- **MediaStore Isolation:** Never written to `Environment.getExternalStoragePublicDirectory()` or `DCIM/`. This ensures the images are hidden from all gallery apps and third-party file scanners.
- **Lifecycle & Cleanup:** When a photo entry is deleted from the database by the user, the underlying file on disk is immediately deleted (`file.deleteSync()`).

### 4.3 Android 12+ and Android 16 Backup Architecture (`data_extraction_rules.xml`)
On Android 12+ (API 31+) and the Honor X9e Pro (Android 16 / MagicOS 10), Android differentiates between **Cloud Backup** (Google Drive auto-backup) and **Device-to-Device Transfer** via `android:dataExtractionRules`. For older devices, `android:fullBackupContent` is maintained.

```xml
<!-- android/app/src/main/res/xml/data_extraction_rules.xml -->
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <!-- STRICT PRIVACY: Completely exclude private photos and database from Google Drive cloud backup -->
        <exclude path="private_photos/" />
        <exclude path="databases/" />
        <exclude path="shared_prefs/" />
    </cloud-backup>
    <device-transfer>
        <!-- Device-to-device migration (e.g. Cable/Wi-Fi switch to new phone): exclude unencrypted photos by default -->
        <exclude path="private_photos/" />
    </device-transfer>
</data-extraction-rules>
```

```xml
<!-- android/app/src/main/res/xml/backup_rules.xml (Fallback for API < 31) -->
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="file" path="private_photos" />
    <exclude domain="database" path="." />
</full-backup-content>
```

In `AndroidManifest.xml`:
```xml
<application
    android:allowBackup="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="@xml/backup_rules"
    ... >
```
Setting `android:allowBackup="false"` or enforcing total cloud-backup exclusion ensures that personal training history and photos are never uploaded silently to Google cloud services.

---

## 5. Single-File Manual Backup, Integrity & Multi-Layer Restore Architecture

### 5.1 Archive Specification (`.homesets`)
The backup file is a compressed ZIP archive with extension `.homesets`:
```text
homesets_backup_20261114_153000.homesets (ZIP Archive)
├── manifest.json        # Schema version, export timestamp, app version, content SHA-256 hashes
├── database_dump.json   # Relational table records exported in versioned JSON format
└── photos/              # Compressed private progress photo PNG binaries
      ├── photo_uuid_1.png
      └── photo_uuid_2.png
```

### 5.2 Privacy Warning on Manual Export
When the user taps "Export Backup", the file is generated locally. Before invoking the Android system Sharesheet (which allows sharing to Google Drive, Telegram, email, etc.), the app displays a mandatory privacy advisory:
> **"تنبيه خصوصية: ملف النسخة الاحتياطية يحتوي على صورك وسجلاتك الشخصية غير مشفرة. احرص على حفظه في مكان آمن وخاص بك وتجنب مشاركته في أماكن عامة."**

### 5.3 Archive Security & Decompression Safeguards (Zip-Bomb & Path Traversal)
Before extracting any entries from an untrusted user-supplied `.homesets` archive:
1. **Path Traversal Check:** Every ZIP entry name is sanitized. Any entry containing directory traversal sequences (`..`), leading slashes (`/`, `\`), or absolute drive letters is immediately rejected.
2. **Resource Limits:**
   - Maximum uncompressed total size limit: 500 MB.
   - Maximum total file entry count: 500 entries.
   - Maximum compression ratio threshold: 100:1 (rejects zip-bombs).
3. **Integrity Validation:** SHA-256 hashes inside `manifest.json` are computed against extracted payloads to detect accidental file corruption. *(Note: SHA-256 detects corruption; it does not constitute cryptographic digital signature authentication of an untrusted file.)*

### 5.4 Two-Phase Staged Restore with Rollback Snapshot
**Critical Architecture Principle:** A SQLite database transaction CANNOT roll back filesystem file modifications! If photo extraction fails midway, the database transaction aborts but partially extracted photos remain on disk, causing state inconsistency.

Therefore, restore follows a **Two-Phase Staged Pipeline with Snapshot Rollback**:
```text
[ Step 1: Staging ]
Extract archive into isolated temporary directory: `cache/restore_staging/`.
Validate manifest schema version (manifest.schema_version <= app.schema_version).
Verify all referenced photo files exist and are valid PNG headers.

[ Step 2: Pre-Restore Snapshot ]
Copy active `databases/homesets.db` and active `files/private_photos/`
into temporary rollback directory: `cache/pre_restore_snapshot/`.

[ Step 3: Atomic Application ]
Open SQLite database: execute table imports inside a single transaction.
Atomically swap photo directories (move staging photos into `files/private_photos/`).
Commit database transaction.

[ Step 4: Failure Handling & Recovery ]
IF any error occurs in Step 3 (IO failure, DB constraint, schema error):
    - Abort and roll back SQLite transaction.
    - Restore original photos from `cache/pre_restore_snapshot/`.
    - Delete `cache/restore_staging/`.
    - Present detailed error to user without modifying prior state.

[ Step 5: Clean-up ]
On verified success, delete `cache/restore_staging/` and `cache/pre_restore_snapshot/`.
Reload application state and display success confirmation.
```

---

## 6. Android 16 & MagicOS 10 Platform Constraints

Ahmed's target device is the **Honor X9e Pro running MagicOS 10 based on Android 16**.

### 6.1 Local Reminder Scheduling (`flutter_local_notifications`)
1. **Notification Runtime Permission:** On Android 13+ (API 33+) and Android 16, the app must request `POST_NOTIFICATIONS` at runtime before scheduling.
2. **Exact Alarms (`SCHEDULE_EXACT_ALARM`):** MagicOS aggressively throttles background alarms to preserve battery.
   - For a daily 3:30 PM reminder, inexact repeating alarms (`AndroidAlarmManager` or `WorkManager`) with a $\pm 15$ min window are preferred to prevent permission rejections.
   - App settings must display a friendly help dialog explaining MagicOS battery management ("Manual Launch / Ignore Battery Optimization") so the reminder fires reliably.

### 6.2 Zero-Network Constraint (OS-Level Socket Sandbox)
The `AndroidManifest.xml` file will **completely omit `android.permission.INTERNET`**.
- **Scope & Limitations:** Omitting `android.permission.INTERNET` instructs the Android OS Linux kernel to block the application process from opening outbound TCP/UDP network sockets. This prevents any third-party SDK or app code from transmitting data over Wi-Fi or cellular networks. It does not provide cryptographic at-rest storage encryption or protect against external malicious apps on rooted devices.

---

## 7. Private Release APK Signing Strategy

### 7.1 Keystore Security Rules
- The production signing keystore (`homesets-release.jks`) must **never be committed to Git**.
- Keystore properties (`keyAlias`, `password`) are passed via local developer environment variables or a local untracked `key.properties`.
- A secure offline backup of the release key must be preserved by Ahmed. If the release key is lost, new APKs cannot be updated over installed versions without losing all local workout data.
