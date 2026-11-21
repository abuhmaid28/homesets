# HOMESETS Campaign P5 — Correction Matrix & Findings Ledger

**Date:** 2026-11-21  
**Campaign:** P5 (Progress Tracking) — Post-Review Corrections  
**Issue:** [#15](https://github.com/abuhmaid28/homesets/issues/15)  
**Pull Request:** [PR #16](https://github.com/abuhmaid28/homesets/pull/16)  
**Branch:** `campaign/p5-progress`  
**Base:** `main` at `463487c1d5318d14699bb0cc47193de71a6bc0be`  
**Governance Authority:** Confirmed GOV21 & GOV22  
**Privacy Audit:** [PHOTO_PRIVACY_AUDIT.md](../architecture/PHOTO_PRIVACY_AUDIT.md)  
**Checkpoint Ledger:** [P5-PROGRESS_CHECKPOINT.md](../campaigns/P5-PROGRESS_CHECKPOINT.md)  

---

## 1. Executive Summary & Verification Acceptance

Campaign P5 delivers offline calisthenics progress tracking: private physique photos, body weight tracking with rolling 7-day averages, automatic strength trends derived from completed `set_logs`, weekly consistency tracking, and a simple daily meal checklist.

Following the initial P5 candidate delivery (exact-head CI #43761250118 PASS), independent lead review identified 9 findings (P5-R01 to P5-R09). All 9 findings have been addressed autonomously under GOV21 authority, verified with red-before-green reproduction tests, full Flutter test suite (81/81 pass), static analysis (0 issues), Python quality checks (4/4 pass), and a verified debug APK build.

---

## 2. Independent Review Corrections Matrix (P5-R01 through P5-R09)

| Finding ID | Severity | Area | Review Description | Production Corrective Action | Verification Evidence | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **P5-R01** | **CRITICAL** | Photo Import & Privacy | Unbounded raw photo copy; EXIF/GPS preserved; full raw bytes in Dart heap; no decode limit. | Implemented off-thread bounded import in `MainActivity.kt` (max 25MB raw, 2048px decode cap with `inSampleSize`, `ExifInterface` rotation, `Bitmap.compress` JPEG re-encode stripping EXIF/GPS). In Dart, stream-bounded 16-byte magic header validation and 15MB file cap. | `test/features/p5_review_repro_test.dart` (oversized file rejection & temp cleanup) | **RESOLVED & VERIFIED** |
| **P5-R02** | **HIGH** | Data Integrity & Lifecycle | Binary copied before DB insert without rollback on error; delete not atomic; orphan cleanup not wired to startup. | Implemented two-phase photo save with atomic compensating file deletion on DB failure. Failure-tolerant photo delete. Wired `cleanupOrphanPhotos` to app startup in `HomesetsApp._checkInitialState` and `_loadAllData`. | `test/features/p5_review_repro_test.dart` (rollback on SQLite error & startup orphan sweep) | **RESOLVED & VERIFIED** |
| **P5-R03** | **HIGH** | Database Migration | Migration test used an inline copied SQL DDL string rather than production `DatabaseHelper._onUpgrade`. | Refactored `DatabaseHelper` to expose `onUpgradeCallback`, `migrateToV2`, and `onCreateV1ForTesting`. Updated test to execute actual production migration code across all 6 v1 tables with idempotence. | `test/data/database_migration_test.dart` & `p5_review_repro_test.dart` (real v1→v2 upgrade) | **RESOLVED & VERIFIED** |
| **P5-R04** | **HIGH** | Android Privacy Rules | `data_extraction_rules.xml` excluded only `progress_photos`, omitting `database`, `sharedpref`, `root`. | Updated `data_extraction_rules.xml` (API 31+) and created `backup_rules.xml` (pre-API 31) excluding all sensitive domains (`database`, `file`, `root`, `sharedpref`) from cloud and D2D. Documented OEM D2D as UNVERIFIED. | Inspected merged manifest & extraction XMLs; Python hygiene check passes | **RESOLVED & VERIFIED** |
| **P5-R05** | **HIGH** | Strength Progress Factual Integrity | Mixed band variations aggregated into one exercise session, producing misleading delta claims. | Added `getAvailableBandConfigurations` and `bandFilter` to `WorkoutRepository`. In `ProgressAnalytics`, enforced strict comparability: deltas are computed only across identical configurations; mixed sets flagged as non-comparable. Added ChoiceChips to Strength UI. | `test/features/p5_review_repro_test.dart` (segmented band history & neutral mixed delta) | **RESOLVED & VERIFIED** |
| **P5-R06** | **MEDIUM** | Weight Editing | Weight editing missing; `LogWeightDialog` always created new ID and was synchronous. | Added `entryToEdit` and `onSaveAsync` to `LogWeightDialog`. Retains original entry ID and date when editing. Added edit button and tap-to-edit on weight list. Awaits async save and displays localized error if write fails. | `test/features/p5_review_repro_test.dart` (editing preserves ID and awaits save) | **RESOLVED & VERIFIED** |
| **P5-R07** | **MEDIUM** | Midnight Meal Rollover | Screen kept open across midnight saved checks to yesterday's date. | Implemented `WidgetsBindingObserver` in `ProgressHubScreen` checking `_currentDateYmd()` on resume and dynamic rollover check in `_onToggleMeal`. | `test/features/p5_review_repro_test.dart` (clean day-boundary rollover) | **RESOLVED & VERIFIED** |
| **P5-R08** | **MEDIUM** | Truthful Architecture Docs | Docs cited `PickVisualMedia` contract; native code uses `ACTION_GET_CONTENT`; camera path absent. | Updated documentation accurately labeling the system content selector (`ACTION_GET_CONTENT`). Formally recorded Direct Camera Capture as **BLOCKED / NOT IMPLEMENTED** under zero-permission constraints. | `PHOTO_PRIVACY_AUDIT.md` & `P5-PROGRESS_CHECKPOINT.md` updated | **RESOLVED & VERIFIED** |
| **P5-R09** | **MEDIUM** | UI Privacy Claims | Progress Hub AppBar hardcoded "100% Private" overpromising on gallery/OEM boundaries. | Replaced with localized badge `appPrivateBadge` ("App-Private" / "حفظ محلي خاص") with tap disclosure explaining local sandbox boundaries and gallery independence. | `test/features/p5_review_repro_test.dart` (asserts 100% Private removed) | **RESOLVED & VERIFIED** |

---

## 3. Final Integration Gate Matrix (P5-FINAL-01 through P5-FINAL-05)

| Finding ID | Severity | Area | Review Description | Production Corrective Action | Verification Evidence | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **P5-FINAL-01** | **HIGH** | Photo Deletion Protocol | Sensitive photo deletion failure was masked as success. SQLite row was deleted first, file deletion errors were swallowed, and UI refreshed as if deleted, leaving untracked private files. | Inverted deletion protocol in `ProgressHubScreen._onDeletePhotoPrompt`: physical file is deleted from sandbox first; if file deletion returns `false` or throws, SQLite deletion is aborted, state is preserved, and a localized error SnackBar (`deletePhotoFailed`) is displayed. | `test/features/p5_review_repro_test.dart` (reproduced DB deletion aborted & error SnackBar shown) | **RESOLVED & VERIFIED** |
| **P5-FINAL-02** | **HIGH** | Import / Sweeper Concurrency | Race condition between orphan sweeper and photo import: `cleanupOrphanPhotos` swept staged files before metadata was committed to SQLite. | Added `markImportPending` and `completePendingImport` reservation tracking to `PhotoService`. Staged files are protected from orphan deletion during active imports. Added 60-second grace window on file modification time in `AndroidPhotoService.cleanupOrphanPhotos`. | `test/features/p5_review_repro_test.dart` (reproduced concurrent orphan sweep does not delete in-flight photo) | **RESOLVED & VERIFIED** |
| **P5-FINAL-03** | **MEDIUM** | Midnight Meal Rollover Gesture | Screen left open across midnight applied stale yesterday's inverted boolean state upon tap, saving `false` for today instead of toggling today's fresh state. | In `ProgressHubScreen._onToggleMeal`, detected calendar rollover before save, reloaded today's actual checks from repository, and inverted today's actual state (`!todayState`) saving `true`. Added deterministic `nowProvider` seam for time-travel verification. | `test/features/p5_review_repro_test.dart` (reproduced rollover gesture saves true for today) | **RESOLVED & VERIFIED** |
| **P5-FINAL-04** | **MEDIUM** | Migration & Hardware Limits | Migration test duplicated SQL; real callback needed verification across all 6 v1 tables with rollback/restart. Hardware proofs needed truthful boundaries. | Added comprehensive v1 upgrade test with rollback on injected error and restart in `test/data/database_migration_test.dart`. Formally documented in `PHOTO_PRIVACY_AUDIT.md` and checkpoints that native JPEG transform & EXIF stripping and OEM D2D clone tools remain **UNVERIFIED ON PHYSICAL HARDWARE** (Honor MagicOS 10) until C9 acceptance. | `test/data/database_migration_test.dart` (populated v1 migration + rollback/restart passing) | **RESOLVED & VERIFIED** |
| **P5-FINAL-05** | **MEDIUM** | Truthful Strength Mixed State | No band filter by default showed unqualified baseline/recent/best reps; `repsDelta=0` masqueraded as flat progress. Exercise change did not reset stale filter before query. | Reset `_selectedBandFilter = null` in `_onSelectExercise` before fetching configurations and history. In `ProgressAnalytics`, made `repsDelta` nullable (`int?`), returning `null` when `!isComparable`. In UI, replaced misleading numeric metrics with "Mixed", hid zero delta badge, and added explicit `Key('mixed_bands_banner')` banner. | `test/features/p5_review_repro_test.dart` (reproduced exercise switch resets filter, delta hidden, banner shown) | **RESOLVED & VERIFIED** |

---

## 4. Residual & Discovered Findings Log (P5 Campaign)

| ID | Component | Discovery Description | Corrective Action Applied | Verification |
| :--- | :--- | :--- | :--- | :--- |
| **P5-FIND-01** | `lib/main.dart` | Nav label "Today" / "النهاردة" conflicted with screen header "Today", causing ambiguous widget test finders in `workout_flow_test.dart`. | Changed navigation label to "Workout" in English and "التمرين" in Arabic, matching standard fitness UX. | Both `workout_flow_test.dart` and `progress_hub_test.dart` pass unambiguously. |
| **P5-FIND-02** | `test/features/progress_hub_test.dart` | Using `pumpAndSettle()` directly after SQLite FFI setup stalled event loop on test isolates. | Created `pumpAsync(tester)` helper driving microtask pump inside `tester.runAsync`. | All Progress Hub widget tests run to completion within 12 seconds. |
| **P5-FIND-03** | `progress_charts.dart` & `progress_hub_screen.dart` | Row layouts on strength stats card overflowed by 37px at 1.5x font scaling on 360dp width. | Wrapped metrics in `LayoutBuilder` dynamically switching to vertical stack when constrained width < 340dp; wrapped weight history header in `Wrap`. | Verified 0 `RenderFlex` overflows under 1.5x font scale and 360x780 viewport in `progress_hub_test.dart`. |
| **P5-FIND-04** | `MainActivity.kt` | `registerForActivityResult` is not available on base `io.flutter.embedding.android.FlutterActivity`. | Implemented standard `startActivityForResult(Intent.ACTION_GET_CONTENT)` with `onActivityResult`, maintaining 0 permissions. | Kotlin compiles and APK builds without warnings or extra AndroidX dependencies. |
| **P5-FIND-05** | `lib/features/progress/progress_hub_screen.dart` | Tapping weight ListTile inside DecoratedBox caused Flutter framework ink splash assertion. | Wrapped `ListTile` in `Material(color: Colors.transparent, child: ...)` to provide proper Material ancestor for ink splashes. | `progress_hub_test.dart` passes cleanly without framework assertions. |

---

## 5. Dependency Ledger & Version Reconcile (GOV21 Compliance)

| Package Name | Type | Current Version in pubspec.yaml | Status under GOV16/GOV21 | Justification & Note |
| :--- | :--- | :--- | :--- | :--- |
| `intl` | Dependency | `^0.20.1` | **Explicitly Authorized** | Localization, pluralization, and date formatting. |
| `sqflite` | Dependency | `^2.4.6` | **Explicitly Authorized** | Authorized SQLite local persistence engine. |
| `path_provider` | Dependency | `^2.1.6` | **Explicitly Authorized** | Resolves local app-private database directory. |
| `flutter_lints` | Dev Dependency | `^6.0.0` | **GOV20 Dev-Only Exception** | Official Flutter lint rules for static analysis (excluded from release APK). |
| `sqflite_common_ffi` | Dev Dependency | `^2.4.7` | **GOV20 Dev-Only Exception** | Enables headless SQLite unit/repository/migration tests on CI and desktop runners. |

**Zero new direct runtime or dev dependencies added.**
