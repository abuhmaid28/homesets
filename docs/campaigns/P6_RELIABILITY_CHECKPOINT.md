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

## 4. P6-R Review Corrections Matrix (P6-R01 to P6-R07)

| Item ID | Severity | Finding & Defect Description | Resolution & Architectural Hardening | Verification Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **P6-R01** | **CRITICAL** | Photos omitted from Settings export due to relative path resolution; missing photos skipped silently. | Resolved `photo.filePath` against `appDocsDir` in `SettingsScreen`. Enforced fatal `BackupValidationException` if any tracked photo is missing on disk; no normal success with partial backup. | `test/data/p6_review_hardening_test.dart` & `test/features/settings_screen_test.dart`. |
| **P6-R02** | **CRITICAL** | Eager uncompressed `ZLibDecoder` prior to limit checks (vulnerable to zip-bombs, duplicate entries, zip-slip). | Implemented pre-decompression limit checks in `ZipCodec.decode` (max file count 1000, max uncompressed 500MB, max entry 250MB, max ratio 100:1, duplicate path rejection, path traversal rejection) and streaming chunked decompression bounds. | `test/data/p6_review_hardening_test.dart` (5 tests pass). |
| **P6-R03** | **HIGH** | Rolling hash falsely documented as SHA-256 in manifest. | Explicitly declared `manifest.checksumAlgorithm = "homesets-v1-digest"` and formatted hash output as unsigned 64-hex chars. Grouped official `crypto` package proposal into GOV25 packet. | `lib/data/services/backup_hash_provider.dart` & `test/data/p6_review_hardening_test.dart`. |
| **P6-R04** | **CRITICAL/HIGH** | Two-resource restore lacked crash safety; rollback dir purged on next restore; false rollback claims on failure. | Implemented persistent `.restore_journal.json` tracking phase state (`PHOTOS_PRESERVED` -> `DB_COMMITTED`); cold startup `recoverPendingJournal()` rolls back photos if interrupted pre-commit and finalizes post-commit. Handled no-original-photos cleanly. | `test/data/p6_review_hardening_test.dart` (3 cold recovery tests pass). |
| **P6-R05** | **HIGH** | Reminders used `PendingIntent.getActivity(MainActivity)` opening app on alarm; no notification broadcast receiver; Settings saved before scheduling. | Replaced `getActivity` with `HomesetsReminderReceiver` broadcast receiver; checks notification permission and prevents unauthorized posting; Settings reverts toggle and displays error if platform scheduling fails. | `HomesetsReminderReceiver.kt`, `MainActivity.kt`, and `settings_screen.dart`. |
| **P6-R06** | **MEDIUM/HIGH** | Lax backup manifest checks (permitted version 0, allowed missing photos as warnings, count discrepancies). | Added strict version boundaries (`formatVersion == 1`, `schemaVersion in [1, 2]`), exact `recordCounts` match across all 9 tables, and strict bidirectional photo file verification. | `lib/data/services/backup_archive_service.dart` & `test/data/p6_review_hardening_test.dart`. |
| **P6-R07** | **MEDIUM** | Settings restore lacked full round-trip verification and error resilience. | Validated end-to-end Settings -> SAF mock export -> SAF mock import -> dry-run preview -> confirmation -> refreshed app state with verified SQLite data. | `test/features/settings_screen_test.dart` (7 tests pass). |

---

## 5. P6 Final Durability & Security Hardening Matrix (P6-FINAL-01 to P6-FINAL-07)

| Finding ID | Severity | Finding & Defect Description | Resolution & Architectural Implementation | Verification Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **P6-FINAL-01** | **CRITICAL** | Interruption between moving photos and SQLite commit or during rollback destroys original photos or orphans staging. Pre-rename crash deleted photos dir without backup existing. | Implemented 6-phase two-resource restore journal with SQLite `restoreToken` in `app_metadata` table. Pre-rename crash only deletes `photosDir` if `photosBackupDir` exists. If SQLite transaction rolls back, restored from backup. If SQLite commits, token confirms commit and photos are kept. | `lib/data/services/backup_staging_manager.dart`, `lib/data/repositories/workout_repository.dart`, and `test/data/p6_final_durability_test.dart` (Boundaries 1–10). |
| **P6-FINAL-02** | **CRITICAL** | Startup recovery not invoked in `lib/main.dart` before normal app flow; profile and inventory read inconsistent state. | Initialized `BackupStagingManager` in `lib/main.dart` and executed `recoverPendingJournal(repository: widget.repository)` before reading user profile and before orphan photo sweeping. Added user-facing recovery failure screen with retry button blocking DB writes if rollback is incomplete. | `lib/main.dart` and `test/data/p6_final_durability_test.dart`. |
| **P6-FINAL-03** | **CRITICAL** | Unbounded memory consumption during archive creation and extraction; reads whole files into heap. | Implemented streaming file-to-file ZIP creation (`createArchiveFileStream`) and extraction (`extractArchiveFileStream`) in `ZipCodec` streaming 64KB chunks directly between disk files with zero whole-file memory buffering. Central directory headers parsed from disk with `RandomAccessFile` before inflating. Enforced hard streaming quotas (max 250MB single entry, max 500MB total, max 1000 files, 100:1 ratio, anti-traversal). | `lib/data/services/zip_codec.dart`, `lib/data/services/backup_archive_service.dart`, and `test/data/p6_final_durability_test.dart`. |
| **P6-FINAL-04** | **CRITICAL** | Failed rollback purged rollback directory on next restore attempt, causing irreversible photo loss. | On rollback failure, journal status set to `ROLLBACK_FAILED` and `photosBackupDir` preserved. Startup recovery re-attempts rollback and alerts user, blocking any routine photo cleanup. | `lib/data/services/backup_staging_manager.dart` and `test/data/p6_final_durability_test.dart` (Boundary 8). |
| **P6-FINAL-05** | **HIGH** | Checksum algorithm named "homesets-v1-digest" lacked streaming chunk computation and explicit algorithm gating in manifest. | Implemented streaming chunked checksum in `DefaultBackupHashProvider.computeFileChecksum` (64KB chunks, O(1) RAM). Added `BackupManifest.supportedChecksumAlgorithm = 'homesets-v1-digest'`; fails closed if unrecognized algorithm is present in archive. | `lib/data/services/backup_hash_provider.dart`, `lib/domain/backup/backup_models.dart`, `lib/data/services/backup_archive_service.dart`, and `test/data/p6_final_durability_test.dart`. |
| **P6-FINAL-06** | **HIGH** | Reminder toggle allowed enabling when Android 13+ notifications are disabled at system level; Settings saved `isEnabled: true`. | Added `areNotificationsEnabled()` check in `MainActivity.kt` and `SettingsScreen._toggleReminders`. If notifications disabled at system level, toggle is reverted, user warning is displayed, and `isEnabled: true` is never committed. | `MainActivity.kt`, `lib/features/settings/settings_screen.dart`, and `test/features/settings_screen_test.dart`. |
| **P6-FINAL-07** | **HIGH** | Lack of comprehensive crash interruption boundary tests covering all failure windows and synthetic P0-P5 full roundtrip. | Created `test/data/p6_final_durability_test.dart` with 14 tests verifying all 10 crash interruption boundaries, streaming archive limits, deterministic digest vectors, full 10-table synthetic P0-P5 roundtrip, and user cancellation. | `test/data/p6_final_durability_test.dart` (14/14 pass). |

---

## 6. P6-LAST Hardening & Single Integrated Closeout Matrix (P6-LAST-01 to P6-LAST-05)

| Finding ID | Severity | Finding & Defect Description | Resolution & Architectural Implementation | Verification Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **P6-LAST-01** | **CRITICAL** | Corrupted or torn journal parsing in `recoverPendingJournal` silently deleted journal and returned success, risking photo generation loss when both existed or state was unverified. | Fail closed on torn/corrupted/malformed journal: preserves `.restore_journal.json` on disk, preserves both `progress_photos/` and `progress_photos_rollback/` without deletion, and returns `RestoreRecoveryResult.failure`. Orphaned rollback directory without journal when photos directory also exists fails closed. | `lib/data/services/backup_staging_manager.dart` and `test/data/p6_final_durability_test.dart` (P6-LAST-01A, 01B, 01C). |
| **P6-LAST-02** | **CRITICAL** | SQLite token query error (`getCurrentRestoreToken()`) was swallowed, treating DB as uncommitted and deleting newly committed photos while SQLite had new data. | Fail closed on token query exception: returns `RestoreRecoveryResult.failure`, never assumes uncommitted, preserves both photo generations and journal intact. On subsequent retry when SQLite is accessible, matches token and finalizes new photos safely. Handled token verify failure in `executeTwoPhaseRestore` catch block. | `lib/data/services/backup_staging_manager.dart` and `test/data/p6_final_durability_test.dart` (P6-LAST-02A, 02B). |
| **P6-LAST-03** | **HIGH** | Production `HomesetsApp._checkInitialState` silently fell back to `Directory.systemTemp` when `getApplicationDocumentsDirectory()` threw, decoupling storage from true SQLite/photo root. | Removed silent `systemTemp` fallback from `lib/main.dart`. If storage lookup fails, app halts with a user-facing error screen ("Storage initialization failed..."), blocking all normal DB writes and photo sweeper. Headless widget tests inject explicit verified staging managers. | `lib/main.dart`, `test/widget_test.dart`, and `test/features/workout_flow_test.dart`. |
| **P6-LAST-04** | **MEDIUM/HIGH** | Hash provider empty-input vector claimed as all-zeros; custom digest called cryptographic; memory claims overclaimed; rollback suggested destructive force-push. | Fixed known test vectors in regression tests: empty input is `8e9b30c57e3e1f91f14c4df09bb9a32e70b9288f36465e4250218c1508981abd`. Accurately documented `homesets-v1-digest` as proprietary non-cryptographic checksum for accidental corruption detection (not SHA-256/MAC). Clarified ZIP memory model (streaming chunks for entries, heap for central directory headers and snapshot JSON). Rollback plan specified as standard reviewed revert PR, never destructive force-push. | `lib/data/services/backup_hash_provider.dart`, `test/data/p6_review_hardening_test.dart`, and campaign docs. |
| **P6-LAST-05** | **OPEN GATE** | Reminders require `POST_NOTIFICATIONS` on Android 13+, not approved under GOV24. | Kept release `AndroidManifest.xml` at 0 permissions. Notification posting gated and safely bypassed when permissions disabled at system level; Settings UI displays disabled warning banner. Accurately documented notification status as BLOCKED under GOV25 owner decision gate. Physical Honor testing remains UNVERIFIED pending C9. | `MainActivity.kt`, `settings_screen.dart`, and `P6_DEPENDENCY_AND_PERMISSION_PROPOSAL.md`. |

---

## 7. Verification Evidence & Test Execution Suite

| Verification Step | Command / Tool | Result | Details |
| :--- | :--- | :--- | :--- |
| **Dart Analyzer** | `flutter analyze --fatal-infos` | **PASS (0 issues)** | Zero errors, zero warnings, zero infos across all packages and test files. |
| **Unit & Widget Tests** | `flutter test` | **PASS (171/171)** | All 171 tests green across data, domain, and feature suites (+23 new security/streaming exit tests). |
| **Python Quality Suite** | `python tools/quality/run_all_checks.py` | **PASS (4/4 suites)** | Fixtures, links, secrets, media scan, and code fence hygiene verified. |
| **Android APK Build** | `flutter build apk --debug` | **PASS** | `build/app/outputs/flutter-apk/app-debug.apk` built cleanly in 28.1s. |
| **GitHub Actions CI** | Exact-Head Workflow | **MONITORED** | Verified on push to `campaign/p6-reliability`. |

---

## 8. P6 Security & Integration Exit Matrix (P6-CLOSE-01 to P6-CLOSE-03)

| Item ID | Severity | Finding & Defect Description | Resolution & Architectural Implementation | Verification Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **P6-CLOSE-01** | **CRITICAL** | ZIP DEFLATE streaming extraction accumulated all uncompressed chunks in heap via `ChunkedConversionSink.withCallback`, retaining entire files in memory until closure. | Replaced accumulating callback with custom `_IncrementalDecompressionSink` writing chunks directly to disk stream as bytes arrive without intermediate chunk buffering. Evaluates declared entry size, max entry size, cumulative archive size, and streaming expansion ratio (zip bomb) immediately on each chunk. Honors backpressure via periodic 2MB flushes. | `lib/data/services/zip_codec.dart` and `test/data/p6_security_exit_test.dart` (WP02 & WP04 suites pass). |
| **P6-CLOSE-02** | **CRITICAL** | Journal `DB_COMMITTED` text alone authorized deleting original rollback photos without SQLite token verification, causing photo loss on token mismatch, missing token, or corrupt fields. | Enforced strict recovery protocol in `recoverPendingJournal`: validates nonempty `restoreToken`, approved `phase`, and boolean `hadOriginalPhotos`. Cross-verifies token with SQLite via `repository.getCurrentRestoreToken()`. If token matches, finalizes. If token does NOT match, fails closed on `DB_COMMITTED` and preserves both photo generations and journal on disk without deletion. If crash occurred pre-commit, safely rolls back original photos. | `lib/data/services/backup_staging_manager.dart` and `test/data/p6_security_exit_test.dart` (P6-CLOSE-02A to 02G pass). |
| **P6-CLOSE-03** | **OPEN GATE** | Reminders require Android 13+ `POST_NOTIFICATIONS` permission, unapproved under GOV24. | Release `AndroidManifest.xml` keeps 0 permissions. Notification posting safely bypassed when blocked at OS level; UI surfaces disabled banner. Accurately documented as BLOCKED under GOV25 owner decision gate. Honor physical testing remains UNVERIFIED pending C9. | `android/app/src/main/AndroidManifest.xml`, `settings_screen.dart`, and `P6_DEPENDENCY_AND_PERMISSION_PROPOSAL.md`. |

---

## 9. Commit History & PR Status

- **Draft PR:** [#18](https://github.com/abuhmaid28/homesets/pull/18) (Targeting `main`)
- **Status:** P6 Security & Integration Exit complete. Kept **UNMERGED** in Draft awaiting independent review under GOV08.
- **Commit Ledger:**
  - `6efb48c` docs(p6): WP01 preflight verification and 20-WP campaign acceptance ledger
  - `36adee3` docs(p6): WP02 backup threat model and WP03 dependency/permission decision packet
  - `eb4a997` feat(p6): WP04 data snapshot contract and WP05 backup manifest models
  - `1fa9987` feat(p6): WP06 archive serialization, WP07 photo packaging, WP08 staging and rollback
  - `45aa1f8` feat(p6): WP09-WP18 SAF backup-restore, preview dialog, local reminders, and UI integration
  - `aecba9f` test(p6): WP19 responsive layouts, text scale 1.5x, and RTL audit
  - `f46eea9` docs(p6): WP20 review passes and campaign checkpoint update
  - `a0d427b` fix(p6): await two-phase restore rollback and add fallback file copy on rename failure
  - `78ce661` docs(p6): record rollback fix in checkpoint ledger
  - `82ac35c` feat(p6): P6-R01 to P6-R07 security hardening, hostile archive defenses, crash journal, and reminder receiver
  - `b818dc9` feat(p6): final crash-safe restore protocol, streaming archive bounds, startup recovery, and reminder permission gating
  - `4c29728` feat(p6): fail-closed journal recovery, token query error safety, and truthful hash vectors
  - `a1cd977` test(p6): ensure backup button visibility and pump cycles in settings screen test
