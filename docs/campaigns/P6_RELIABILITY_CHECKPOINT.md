# HOMESETS Campaign P6 — Reliability Mega Campaign Checkpoint & Acceptance Ledger

**Campaign:** P6 (Reliability: Manual Backup/Restore & Local Reminders)  
**Date:** 2026-11-21  
**Master Issue:** [#17](https://github.com/abuhmaid28/homesets/issues/17)  
**Governance Authority:** Confirmed Decisions GOV23 & GOV24  
**Feature Branch:** `campaign/p6-reliability`  
**Base Commit on `main`:** `162854f7832626ba0a32d665796a32d1e9fec5a9`  
**Baseline CI Status:** [Run #44941791205 (SUCCESS)](https://github.com/abuhmaid28/homesets/actions/runs/44941791205)  
**Pull Request:** [Draft PR #18](https://github.com/abuhmaid28/homesets/pull/18) targeting `main`  
**Merge Policy:** GOV08 — Guarded merges only; PR #18 remains UNMERGED awaiting independent review.  

---

## 1. 20-WP Complete Execution Acceptance Matrix

| WP | Focus Area | Status | Deliverables & Verification Evidence |
| :--- | :--- | :--- | :--- |
| **WP01** | Baseline & Repo Preflight | **DONE** | Clean branch `campaign/p6-reliability` from verified `main` (`162854f`); baseline CI green (#44941791205); checkpoint established; Draft PR #18 opened. (Commit `6efb48c`) |
| **WP02** | Architecture & Threat Model | **DONE** | Authored `docs/architecture/BACKUP_RESTORE_THREAT_MODEL.md` documenting trust boundaries, zip-slip, decompression bombs, container layout, and rollback state machine. (Commit `36adee3`) |
| **WP03** | Dependency/License/Permission Packet | **DONE** | Authored `docs/proposals/P6_DEPENDENCY_AND_PERMISSION_PROPOSAL.md` evaluating `archive`, `crypto`, `flutter_local_notifications`, `POST_NOTIFICATIONS`; Option A (0 new deps, 0 permissions) implemented and documented. (Commit `36adee3`) |
| **WP04** | Full Data Snapshot Contract | **DONE** | Implemented `HomesetsDataSnapshot` in `lib/domain/backup/backup_models.dart` capturing all 9 SQLite tables; tested roundtrip and deserialization in `test/domain/backup_models_test.dart`. (Commit `eb4a997`) |
| **WP05** | Backup Manifest & Integrity Checks | **DONE** | Implemented `BackupManifest` & `BackupFileEntry` with schema version gating, record counts, and snapshot checksums in `lib/domain/backup/backup_models.dart`. (Commit `eb4a997`) |
| **WP06** | Bounded Archive Serialization | **DONE** | Implemented `BackupArchiveService` and zero-dependency standard `ZipCodec` (PKWARE Store & Deflate) in `lib/data/services/zip_codec.dart` with CRC-32 and quota bounds. (Commit `1fa9987`) |
| **WP07** | Private Photo Inclusion & Consistency | **DONE** | Bundled app-private progress photos (`progress_photos/<id>.jpg`) into archive with sha256 checksums, missing file tolerance/warnings in `BackupArchiveService`. Tested in `test/data/backup_archive_service_test.dart`. (Commit `1fa9987`) |
| **WP08** | Secure Local Export Staging | **DONE** | Implemented `BackupStagingManager` in `lib/data/services/backup_staging_manager.dart` managing isolated `.staging_restore` and `.backup` directories with atomic rollback. (Commit `1fa9987`) |
| **WP09** | Android Scoped SAF Document Picker | **DONE** | Implemented SAF platform channel in `android/app/src/main/kotlin/com/abuhmaid/homesets/MainActivity.kt` (`ACTION_CREATE_DOCUMENT` & `ACTION_OPEN_DOCUMENT`) and `BackupPlatformService` with 0 broad storage permissions. (Commit `45aa1f8`) |
| **WP10** | Export UI, Privacy Warning & Copy | **DONE** | Implemented Backup section in `lib/features/settings/settings_screen.dart` with localized privacy disclosures, Egyptian Arabic RTL & English LTR. (Commit `45aa1f8`) |
| **WP11** | Backup Import Selection & Validation | **DONE** | Implemented archive pre-flight validation in `BackupArchiveService.validateArchive` checking size quotas, zip-slip paths, and hash matching before user consent. (Commit `45aa1f8`) |
| **WP12** | Dry-Run Preview & Explicit Consent | **DONE** | Implemented `RestorePreviewDialog` in `lib/features/settings/widgets/restore_preview_dialog.dart` showing item counts, warning banner, and requiring explicit destructive confirmation. (Commit `45aa1f8`) |
| **WP13** | Transactional SQLite Restoration | **DONE** | Implemented `WorkoutRepository.restoreDataSnapshot` executing transactional restore across all tables with rollback on exception; zero data corruption. (Commit `45aa1f8`) |
| **WP14** | Recoverable Photo Restore & 2-Phase Commit | **DONE** | Implemented two-resource commit in `SettingsScreen` and `BackupStagingManager` swapping photos only after DB commit succeeds; restores from backup on filesystem error. (Commit `45aa1f8`) |
| **WP15** | Restore Failure & Corruption Exercises | **DONE** | Tested corrupt ZIP, tampered checksum, path traversal, future schema version, and cancelled preview in `test/features/settings_screen_test.dart`. (Commit `45aa1f8`) |
| **WP16** | Reminder Settings & Persistence | **DONE** | Implemented `ReminderSettings` domain model and SQLite table `reminder_settings` with default 15:30 schedule and shame-free Arabic/English copy. Tested in `test/domain/reminder_settings_test.dart`. (Commit `45aa1f8`) |
| **WP17** | Android Local Scheduling & Permissions | **DONE** | Implemented `AlarmManager.setInexactRepeating` platform channel in `MainActivity.kt` and `ReminderPlatformService`; handles system notification disabled state with UI banner. (Commit `45aa1f8`) |
| **WP18** | Timezone, Clock Changes & Limitations | **DONE** | Documented daily repeating inexact alarm mechanics, DST resiliency; documented Honor MagicOS 10 background killing as UNVERIFIED pending C9 phone test. (Commit `45aa1f8`) |
| **WP19** | Full UX, Accessibility & Responsiveness | **DONE** | Verified 360, 390, 412dp viewports, 1.5x font scale, and RTL layout in `test/features/settings_responsive_test.dart`; fixed text overflow in `RestorePreviewDialog`. (Commit `aecba9f`) |
| **WP20** | Two-Round Internal Review, QA & Delivery | **DONE** | Executed Hostile Threat Review (Pass A) and User Journey QA (Pass B); 117/117 tests pass; 0 analyzer issues; 4/4 Python checks pass; debug APK built cleanly; PR #18 updated. |

---

## 2. Technical & Privacy Boundaries (GOV24 & GOV25-PENDING)

1. **Zero Unapproved Dependencies:** Retained preauthorized lockfile (`intl: ^0.20.1`, `sqflite: ^2.4.6`, `path_provider: ^2.1.6`). All ZIP compression/decompression, checksums, and platform channels implemented with 0 new dependencies.
2. **Zero Unapproved Permissions:** Release `AndroidManifest.xml` retains 0 permissions. Android SAF requires 0 storage permissions; `AlarmManager.setInexactRepeating` requires 0 exact-alarm permissions.
3. **100% Offline Architecture:** Zero network calls, zero analytics SDKs, zero telemetry, zero cloud accounts.
4. **Manual-Only Backup:** Backups are 100% user-initiated via SAF; no background backup service.
5. **Informed Consent for Restore:** Explicit `RestorePreviewDialog` requires confirmation before replacing local state; cancels safely without altering existing database.
6. **Physical Phone Status:** Honor MagicOS 10 physical device testing remains explicitly **UNVERIFIED** until C9 final acceptance gate per GOV07/GOV22.

---

## 3. Two-Round Internal Review Passes

### Pass A: Security & Threat Boundary Verification

| Threat ID | Threat Description | Mitigation & Code Location | Verification Evidence |
| :--- | :--- | :--- | :--- |
| **THREAT-01** | Zip-Slip (Path Traversal) | `BackupArchiveService._validateEntryPath` rejects any path containing `..`, starting with `/` or `\`, or outside whitelist (`manifest.json`, `data.json`, `progress_photos/<id>.jpg`). | Verified in `test/data/backup_archive_service_test.dart` & `test/features/settings_screen_test.dart`. |
| **THREAT-02** | Decompression Bomb (OOM/DoS) | `BackupArchiveService` enforces strict bounds: max 250 MB archive, max 500 MB uncompressed, max 1000 files, max 100:1 ratio. | Verified in `test/data/backup_archive_service_test.dart`. |
| **THREAT-03** | Tampered Snapshot Data | 256-bit checksum generated over `data.json` and validated against `manifest.dataSnapshotChecksum`. Rejects modified payloads. | Verified in `test/data/backup_archive_service_test.dart` & `test/features/settings_screen_test.dart`. |
| **THREAT-04** | Incompatible Schema Version | Manifest format version gated to `<= 1`; database schema version gated to `<= 2`. Future versions rejected before any mutations. | Verified in `test/data/backup_archive_service_test.dart`. |
| **THREAT-05** | Photo Reference Orphan / Leak | All photos referenced in `snapshot.progressPhotos` verified against archive entries; missing files flagged as non-fatal warnings without aborting or leaking. | Verified in `test/data/backup_archive_service_test.dart`. |
| **THREAT-06** | Accidental Public Storage Leak | Android SAF streams directly through user-selected document URI via `ContentResolver`. Private photos never exposed to shared media store. | Verified in `MainActivity.kt` and `BackupPlatformService`. |
| **THREAT-07** | Restore Crash / Partial Mutation | Two-resource commit: photos staged in `.staging_restore`; SQLite restored in single transactional batch; directory swapped atomically with `.backup` fallback. | Verified in `BackupStagingManager` and `test/features/settings_screen_test.dart`. |
| **THREAT-08** | Inexact Alarm & Permission Fallback | Inexact repeating alarm avoids restricted `SCHEDULE_EXACT_ALARM`; `NotificationManagerCompat.areNotificationsEnabled()` checks system state and renders warning banner when notifications disabled. | Verified in `MainActivity.kt` and `test/features/settings_screen_test.dart`. |

---

### Pass B: User Journey, Failure Modes & Regressions

1. **Create Backup Flow:**
   - Navigating to Settings -> Backup -> Create Backup prompts SAF file creation with suggested timestamped filename (`homesets_backup_YYYYMMDD_HHMMSS.homesets`).
   - Archive packages `manifest.json`, `data.json` (all SQLite tables), and private photos.
   - Success snackbar displays exported archive size; zero crash or background leakage.
2. **Restore Backup (Happy Path):**
   - Navigating to Settings -> Backup -> Restore from Backup opens SAF document picker.
   - Archive pre-validated in dry-run mode; `RestorePreviewDialog` renders workout count, set count, photo count, and creation date.
   - Confirming replaces database transactionally and swaps photo directory; success snackbar shown and `onDataRestored` callback refreshes application state.
3. **Restore Backup (Cancel & Hostile Reject):**
   - Cancelling in `RestorePreviewDialog` aborts cleanly; database and photos untouched.
   - Corrupted archive or tampered hash triggers localized error dialog; existing database untouched.
4. **Daily Reminders Flow:**
   - Toggle switches daily local reminder on/off (default 15:30).
   - Time row opens time picker; selected time persists to SQLite and reschedules Android `AlarmManager`.
   - Shame-free Egyptian Arabic RTL and English LTR copy rendered consistently.
5. **P0–P5 Regression Verification:**
   - All 117 unit and widget tests pass covering workout rotation, exertion rating, pain STOP, crash recovery, progress photos, weight logging, and v1->v2 migration.

---

## 4. Verification Evidence & Test Execution Suite

| Verification Step | Command / Tool | Result | Details |
| :--- | :--- | :--- | :--- |
| **Dart Analyzer** | `flutter analyze --fatal-infos` | **PASS (0 issues)** | Zero errors, zero warnings, zero infos across all packages and test files. |
| **Unit & Widget Tests** | `flutter test` | **PASS (117/117)** | All 117 tests green across data, domain, and feature suites. |
| **Python Quality Suite** | `python tools/quality/run_all_checks.py` | **PASS (4/4 suites)** | Fixtures, links, secrets, media scan, and code fence hygiene verified. |
| **Android APK Build** | `flutter build apk --debug` | **PASS** | `build/app/outputs/flutter-apk/app-debug.apk` built cleanly in 36.5s. |
| **GitHub Actions CI** | Exact-Head Workflow | **MONITORED** | Triggered on push to `campaign/p6-reliability`. |

---

## 5. Commit History & PR Status

- **Draft PR:** [#18](https://github.com/abuhmaid28/homesets/pull/18) (Targeting `main`)
- **Status:** Complete, all 20 WPs delivered. Kept **UNMERGED** awaiting independent lead review under GOV08.
- **Commit Ledger:**
  - `6efb48c` docs(p6): WP01 preflight verification and 20-WP campaign acceptance ledger
  - `36adee3` docs(p6): WP02 backup threat model and WP03 dependency/permission decision packet
  - `eb4a997` feat(p6): WP04 data snapshot contract and WP05 backup manifest models
  - `1fa9987` feat(p6): WP06 archive serialization, WP07 photo packaging, WP08 staging and rollback
  - `45aa1f8` feat(p6): WP09-WP18 SAF backup-restore, preview dialog, local reminders, and UI integration
  - `aecba9f` test(p6): WP19 responsive layouts, text scale 1.5x, and RTL audit
  - `f46eea9` docs(p6): WP20 review passes and campaign checkpoint update
  - `a0d427b` fix(p6): await two-phase restore rollback and add fallback file copy on rename failure
