# HOMESETS Campaign C3R2 — Residual Correctness Hardening Matrix

**Date:** 2026-11-15  
**Campaign:** C3R2 (Residual Core Correctness & Regression Hardening)  
**Issue:** [#14](https://github.com/abuhmaid28/homesets/issues/14)  
**Target Pull Request:** [Draft PR #12](https://github.com/abuhmaid28/homesets/pull/12)  
**Branch:** `campaign/c3-flutter-core`  
**Basis:** Independent Source Review Findings (WP01 through WP10)  
**Governance Authority:** Product Owner Approved GOV12–GOV19  

---

## 1. Executive Summary & Verification Acceptance

All 10 Work Packages (WP01 through WP10), all 6 Follow-up Findings (F1 through F6), and all 3 Final Closeout Work Packages (WP-A, WP-B, WP-C) in GitHub Issue #14 have been implemented, verified, and backed with automated test suites:
- **Flutter Test Suite:** 48 tests passing (100%), 0 failures across all unit, repository, domain, and widget suites (`flutter test`).
- **Reproduction Test Suite:** 15 explicit behavior-driven regression tests passing in `test/domain/c3r2_repro_test.dart` (including failing red-before-green reproductions for WP-A, WP-B, WP-C).
- **Domain Fixture Runner:** All 106 fixture scenarios (59 positive, 47 negative) executed dynamically against pure-Dart domain logic (`test/domain/fixture_engine_test.dart`).
- **Static Analysis:** `flutter analyze --fatal-infos` reported **0 issues** (clean code quality).
- **Python Quality QA:** 4/4 suites passing (`python tools/quality/run_all_checks.py`).
- **Android Debug APK:** `build/app/outputs/flutter-apk/app-debug.apk` built successfully (`89E569EAB7D7C67BA3CF99E9F3F64B51FD360A95A2729941969DB159B2EE5CED`, 209,984,523 bytes).
- **Physical Phone Status:** Explicitly marked **UNVERIFIED** (deferred to C9 final phone acceptance per GOV09).

---

## 2. Work Package Resolution Matrix

| WP | Severity | Description | Modified Files | Resolution & Implementation Evidence | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WP01** | **HIGH** | Preflight and failing repro matrix before fixes. | `test/domain/c3r2_repro_test.dart` | Created dedicated reproduction test file reproducing rotation double-skip (REPRO-01) and zero-set consistency credit (REPRO-02) as failing tests before code fixes were applied. Expanded to 6 comprehensive regression tests. | **RESOLVED & VERIFIED**<br>6/6 regression tests passing. |
| **WP02** | **HIGH** | Rotation double-skip & per-group recovery: 12h gap after Routine A caused Routine B to incorrectly skip to Routine C. | `lib/domain/engine/workout_engine.dart`<br>`lib/data/repositories/workout_repository.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | Added `targetGroupForCycle()` and `nextCycleAfter()`. Updated `generateNextSession()`: rotation away from a candidate routine is now **strictly conditional on whether the candidate targets the same fatigued muscle group** as `lastTargetMuscleGroup`. Implemented `getLastWorkoutMuscleGroup()` in `WorkoutRepository` and wired it into `TodayScreen._loadData()`. Short 12h gap between different groups (e.g. chest/triceps after lats/biceps) is allowed without double-skipping. | **RESOLVED & VERIFIED**<br>`REPRO-01` and `REPRO-06` passing. |
| **WP03** | **HIGH** | Fixture coverage truth: cadence-pause, assistance, resistance, absence-deload asserted fixture inputs rather than calling engine. | `lib/domain/models/domain_models.dart`<br>`lib/domain/engine/workout_engine.dart`<br>`test/domain/fixture_engine_test.dart` | Added domain models (`CadencePauseResult`, `BandAssistanceResult`, `BandResistanceResult`, `AbsenceDeloadResult`) and domain methods: `WorkoutEngine.evaluateCadencePause()`, `evaluateBandAssistance()`, `evaluateBandResistance()`, `evaluateAbsenceDeload()`, and `isContinuousShiftWorkSession()`. Refactored `test/domain/fixture_engine_test.dart` to execute real engine calls across all 10 categories. | **RESOLVED & VERIFIED**<br>106/106 dynamic scenarios passing. |
| **WP04** | **HIGH** | Safe legacy/corrupt snapshot recovery: corrupt JSON caused silent fallback to freshly generated standard session, losing Lite mode. | `lib/data/repositories/workout_repository.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | Updated `WorkoutRepository.getActiveSessionState()`: if `active_session_json` cannot be decoded or is corrupted/empty, repository synthesizes a safe fallback `ScheduledSession` preserving `isLiteMode`, target routine, and planned exercises from completed sets/catalog. In `TodayScreen`, resume button safely preserves `isLiteMode` and routine identity. Added user-facing "Discard In-Progress Draft" button with confirmation dialog. | **RESOLVED & VERIFIED**<br>`REPRO-03` passing; zero silent data loss. |
| **WP05** | **HIGH** | Pain Stop event and async race safety: `_triggerPainStop()` fabricated completed reps (`_currentReps`); lack of `_isSessionFinished` gates. | `lib/features/workout/workout_player_screen.dart` | In `_triggerPainStop()`, logged emergency set with `performedReps: 0` (preventing false credit). Wrapped all repository persistence operations in `try-catch` blocks so disk I/O failure cannot trap the user in an unresponsive state. Added `_isSessionFinished` early return guards to `_handleLogSet()`, `_advanceAfterRest()`, and before/after bottom sheet / rest timer transitions in `_promptExertionAndRest()`. | **RESOLVED & VERIFIED**<br>E2E and widget flow tests passing. |
| **WP06** | **HIGH** | Progression applied to real sessions: planned workouts previously used fixed 8–10 rep targets without feeding logged history. | `lib/domain/engine/workout_engine.dart`<br>`lib/data/repositories/workout_repository.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | Added `getRecentExerciseHistory()` to `WorkoutRepository` querying past 30 days of completed sets per exercise. In `WorkoutEngine.generateNextSession()`, evaluated `evaluateProgression()` per exercise and applied adapted min/max reps or tempo cues (e.g. `'2s pause top, 3s eccentric'`). Wired into `TodayScreen._loadData()`. | **RESOLVED & VERIFIED**<br>`REPRO-05` passing with tempo cues applied. |
| **WP07** | **MEDIUM** | Real consistency credit: SQL query counted zero-set non-emergency sessions as completed workouts. | `lib/data/repositories/workout_repository.dart`<br>`test/data/workout_repository_test.dart`<br>`test/domain/c3r2_repro_test.dart` | Updated `getWeeklyConsistencyCredit()` query to require: `AND EXISTS (SELECT 1 FROM set_logs sl WHERE sl.session_id = ws.id AND sl.is_pain_stopped = 0 AND sl.performed_reps > 0)`. Zero-set sessions earn 0 credit; sessions with at least one completed non-pain rep earn 1 credit. | **RESOLVED & VERIFIED**<br>`REPRO-02` passing. |
| **WP08** | **MEDIUM** | Dependency & audit honesty: reconcile `path`, `flutter_lints`, `sqflite_common_ffi` with GOV16 allowlist and report actual versions. | `pubspec.yaml`<br>`docs/reviews/C3R2_CORRECTION_MATRIX.md` | Documented verified dependency ledger: `intl: ^0.20.1`, `sqflite: ^2.4.6`, `path_provider: ^2.1.6`, `path: ^1.9.1` (transitive Dart team utility used for path joins in `DatabaseHelper`), `flutter_lints: ^6.0.0` (standard SDK linter), `sqflite_common_ffi: ^2.4.7` (dev-only for headless desktop/CI tests). Zero unapproved dependencies added. | **RESOLVED & VERIFIED**<br>Honest ledger documented. |
| **WP09** | **HIGH** | Verify exact-head CI plus honest APK permissions: debug manifest includes `INTERNET` via Flutter dev tooling; release manifest has zero permissions. | `android/app/src/main/AndroidManifest.xml`<br>`android/app/src/debug/AndroidManifest.xml`<br>`build/app/outputs/flutter-apk/app-debug.apk` | Audited compiled APK and source manifests. `android/app/src/main/AndroidManifest.xml` declares **0 permissions** (`<uses-permission>` is completely absent). `android/app/src/debug/AndroidManifest.xml` includes `INTERNET` solely for Flutter CLI/DevTools local socket connection. Full SHA-256 hash and size recorded. Physical Honor test explicitly marked **UNVERIFIED** (deferred to C9). | **RESOLVED & VERIFIED**<br>Full permission audit documented. |
| **WP10** | **HIGH** | Independent self-review, small scoped commits, PR #12 update, leave Draft & UNMERGED. | `docs/reviews/C3R2_CORRECTION_MATRIX.md`<br>`docs/campaigns/C3-MEGA_CHECKPOINT.md` | Prepared comprehensive correction matrix, updated checkpoint, committed clean diffs to `campaign/c3-flutter-core`, pushed to PR #12, confirmed CI execution, and preserved PR in DRAFT awaiting independent lead review. | **RESOLVED & VERIFIED**<br>Draft PR #12 updated. |

---

## 3. Post-CI Independent Review Hardening Matrix (Findings F1 through F6)

Following successful initial CI on exact head `d33e8461`, independent review [#5908883089](https://github.com/abuhmaid28/homesets/pull/12#pullrequestreview-5908883089) identified six residual correctness findings. All six have been resolved with red-before-green reproduction tests:

| Finding | Severity | Description | Modified Files | Resolution & Implementation Evidence | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **F1** | **CRITICAL** | Corrupt/legacy active snapshot in Routine C with 0 sets synthesized fallback referencing 6 nonexistent catalog IDs (`overhead_press_band`, `pushdown_triceps_band`, `squat_band_resisted`, `glute_bridge_single_leg`, `split_squat_rear_foot_elevated`, `bicep_curl_band`), returning `isViable: true` with 0 exercises, crashing the player and bypassing safety. | `lib/data/repositories/workout_repository.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | Completely eliminated fabricated fallback workout synthesis from `WorkoutRepository.getActiveSessionState()`. If `active_session_json` cannot be decoded into a valid scheduled session, `scheduledSession` is set to `null` and `isPlanUnrecoverable = true`. In `TodayScreen`, the resume button is disabled/hidden, an informative amber warning card is presented, and options to non-destructively "Save Logged Sets to History" or "Discard Draft" are provided. Tested on Routine C, empty JSON, and corrupted strings. | **RESOLVED & VERIFIED**<br>`REPRO-03` and `F1` tests passing; zero hallucinated exercises; zero crash risk. |
| **F2** | **HIGH** | Monolithic `try-catch` around `completed_sets_json` parsing previously swallowed exceptions and wiped all valid completed sets if a single set entry was malformed. | `lib/data/repositories/workout_repository.dart`<br>`test/domain/c3r2_repro_test.dart` | Replaced monolithic parser with defensive item-by-item JSON parsing in `WorkoutRepository.getActiveSessionState()`. Individual corrupt/invalid set entries are skipped while preserving all valid sets. Sets `hasCorruptSetLogs = true` and retains `rawCompletedSetsJson` for inspection. | **RESOLVED & VERIFIED**<br>`F2` test passing; valid logs preserved under partial corruption. |
| **F3** | **HIGH** | Evaluating only the single most recent session's muscle group allowed rapid cycles ($A \to B \to C \to A$ within 36 hours) to prescribe Routine A despite Lats/Biceps having been trained $<36$ hours prior. | `lib/data/repositories/workout_repository.dart`<br>`lib/domain/engine/workout_engine.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | Added `getLastWorkoutTimePerMuscleGroup()` to `WorkoutRepository` querying the latest non-emergency completion timestamp for each muscle group (`LATS_BICEPS`, `CHEST_TRICEPS`, `LEGS_GLUTES`). In `WorkoutEngine.generateNextSession()`, if all muscle groups were trained within the past 36 hours, it marks the plan unviable (`ScheduledSession.unviable(routineName: 'Full Joint & Muscle Recovery', targetMuscleGroup: 'RECOVERY')`). | **RESOLVED & VERIFIED**<br>`F3` test passing; exhaustive 36h multi-session fatigue guard. |
| **F4** | **HIGH** | In `WorkoutPlayerScreen._triggerPainStop()`, if SQLite persistence fails (e.g. disk full / IO error), error was caught but dialog gave no visible indication of persistence failure. | `lib/features/workout/workout_player_screen.dart` | Added failure tracking in `_triggerPainStop()` (`persistenceFailed`). If joint quarantine cannot be written to SQLite, the dialog renders an explicit amber notice ("Notice: Could not save joint quarantine to local storage (Disk/IO error)") along with an idempotent "Retry Save" button and safe exit without trapping the user. | **RESOLVED & VERIFIED**<br>Interactive dialog and retry logic verified. |
| **F5** | **HIGH** | 1) Absence deload domain evaluation was disconnected from the planning pipeline.<br>2) Querying all historical set logs over 30 days caused older sets with lower reps from weeks prior to permanently suppress double progression. | `lib/domain/models/domain_models.dart`<br>`lib/domain/engine/workout_engine.dart`<br>`lib/data/repositories/workout_repository.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | 1) Connected `evaluateAbsenceDeload()` directly into `WorkoutEngine.generateNextSession()`. If $\ge 6$ days elapsed since `lastWorkoutTime`, planned sets are reduced by 25% (8+ days) or 40% (14+ days) with attached `AbsenceDeloadResult`. `TodayScreen` displays a dedicated "Gentle Re-entry Deload Active" card with guilt-free messaging.<br>2) Refactored `getRecentExerciseHistory()` in `WorkoutRepository` to strictly isolate sets from the **single latest session** per exercise (`ws.ended_at DESC, sl.set_index ASC`), allowing double progression to trigger naturally when the user hits ceiling reps in their latest session. | **RESOLVED & VERIFIED**<br>`F5` absence deload & progression tests passing. |
| **F6** | **MEDIUM** | Consistency credit counted workouts with only 1 completed set as a completed workout, giving false consistency credit to abandoned sessions. | `lib/data/repositories/workout_repository.dart`<br>`test/data/workout_repository_test.dart`<br>`test/domain/c3r2_repro_test.dart` | Updated `getWeeklyConsistencyCredit()` to enforce legitimate completion thresholds:<br>- Standard mode: $\ge 3$ completed non-pain sets (with reps > 0).<br>- Lite mode: $\ge 2$ completed non-pain sets (out of 4 planned sets).<br>Partially quit or abandoned sessions below these thresholds earn 0 credit. | **RESOLVED & VERIFIED**<br>`F6` and `REPRO-02` tests passing. |

---

## 4. Final Closeout Resolution Matrix (Work Packages A, B, and C)

Following independent review [#5908980367](https://github.com/abuhmaid28/homesets/pull/12#pullrequestreview-5908980367), three targeted final closeout packages were executed and verified with red-before-green reproduction tests:

| WP | Severity | Defect & Root Cause | Modified Files | Resolution & Implementation Evidence | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WP-A** | **HIGH** | Potential silent, irreversible loss of corrupt workout logs: `saveCompletedSession()` deleted `active_session_state`, permanently wiping raw corrupt bytes. Partially salvaged workouts were saved as normal completions with full weekly credit. | `lib/data/database/database_helper.dart`<br>`lib/data/repositories/workout_repository.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | Created `session_salvage_archive` table in SQLite schema (`DatabaseHelper`). Added `salvageCorruptSession()` in `WorkoutRepository` to durably archive `raw_completed_sets_json` and `raw_active_session_json` BEFORE deleting active state. Marked salvaged sessions with `is_emergency_stopped = 1` and explicit reason so `getWeeklyConsistencyCredit()` strictly returns 0 credit. Updated `TodayScreen` to display truthful copy ("Notice: Draft contains corrupt entries... Raw data will be durably archived in local storage without false completion credit.") and button "Archive Raw & Save Salvaged Sets". | **RESOLVED & VERIFIED**<br>`WP-A / CORE-FINAL-01` test passing; zero raw data loss; zero false credit. |
| **WP-B** | **HIGH** | Pain STOP still exited as saved after persistence failure: separate profile/session writes risked partial state; when DB failed, primary `painStopConfirm` was still available and called `onFinishSession()` as if saved. | `lib/data/repositories/workout_repository.dart`<br>`lib/features/workout/workout_player_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | Implemented `saveEmergencyPainStopSession()` executing profile joint quarantine, emergency session record, and set logs insertion in a single atomic SQLite transaction. In `WorkoutPlayerScreen._triggerPainStop()`, when persistence fails, the confirm button is hidden and replaced with `Retry Save` (`ElevatedButton`) and an explicit `Exit Unsaved (Acknowledge Risk)` (`TextButton`). | **RESOLVED & VERIFIED**<br>`WP-B / CORE-FINAL-02` test passing; atomic transaction; explicit failure UI. |
| **WP-C** | **MEDIUM** | Final-set interruption & crash replay: `_handleLogSet()` set `currentExerciseIndex` to last exercise and reset `currentSetIndex` to 1, causing crash resumes to replay set 1. | `lib/data/repositories/workout_repository.dart`<br>`lib/features/workout/workout_player_screen.dart`<br>`lib/features/today/today_screen.dart`<br>`test/domain/c3r2_repro_test.dart` | In `_handleLogSet()`, when the final set of the final exercise is logged, `currentSetIndex` remains on the final set (`_totalSetsInExercise`) and `isPendingFinalization = true` is set on `ActiveSessionSnapshot`. In `WorkoutPlayerScreen._restoreSessionOrInit()`, if `isPendingFinalization` is true or all planned sets are logged, it immediately routes to `_finalizeSession(isEmergency: false)` without replaying set 1. In `TodayScreen`, shows "Finish & Finalize Workout". | **RESOLVED & VERIFIED**<br>`WP-C` test passing; zero duplicated sets. |

---

## 5. Dependency Ledger & Version Reconcile (WP08)

| Package Name | Type | Current Version in pubspec.yaml | Status under GOV16 | Justification & Note |
| :--- | :--- | :--- | :--- | :--- |
| `intl` | Dependency | `^0.20.1` | **Explicitly Authorized** | Localization, pluralization, and date formatting. |
| `sqflite` | Dependency | `^2.4.6` | **Explicitly Authorized** | Authorized SQLite local persistence engine. |
| `path_provider` | Dependency | `^2.1.6` | **Explicitly Authorized** | Resolves local app-private database directory. |
| `path` | Dependency | `^1.9.1` | **Essential Companion** | Official `dart.dev` path utility for safe cross-platform path joining (`join(dbPath, 'homesets_local.db')`). |
| `flutter_lints` | Dev Dependency | `^6.0.0` | **Development Only** | Official Flutter lint rules for static analysis. |
| `sqflite_common_ffi` | Dev Dependency | `^2.4.7` | **Development Only** | Enables headless SQLite unit & repository tests on CI and desktop runners without an attached Android emulator. |

---

## 6. Truthful Permission & Manifest Audit (WP09)

### Compiled Debug APK Details
- **Artifact File:** `build/app/outputs/flutter-apk/app-debug.apk`
- **File Size:** `209,984,523` bytes (~200.2 MB uncompressed debug bundle with symbols & all ABIs)
- **SHA-256 Hash:** `89E569EAB7D7C67BA3CF99E9F3F64B51FD360A95A2729941969DB159B2EE5CED`

### Permission Audit
1. **Release Manifest (`android/app/src/main/AndroidManifest.xml`):**
   - `<uses-permission>` tags: **0 (NONE)**.
   - Cloud backup: `android:allowBackup="false"` and `android:fullBackupContent="false"`.
   - The production app has no network access, no backend connectivity, no analytics, no external trackers, and zero cloud leaks.
2. **Debug Manifest (`android/app/src/debug/AndroidManifest.xml`):**
   - `<uses-permission android:name="android.permission.INTERNET" />`: Injected automatically by the Flutter SDK template solely for local host-to-device socket communication (`127.0.0.1`) during development (DevTools, debugging, hot reload).
   - In release builds, Gradle excludes the debug manifest, ensuring the final APK retains 0 permissions.
3. **Physical Phone Status:**
   - Physical device behavior on Honor MagicOS 10 remains explicitly **UNVERIFIED** (deferred to C9 final phone acceptance per GOV09).

---

## 7. Test Execution Evidence

| Test Suite | File | Tests | Results |
| :--- | :--- | :--- | :--- |
| **C3R2 Repro & Regression** | `test/domain/c3r2_repro_test.dart` | 15 | **ALL PASS** (1.0s) |
| **Domain Fixture Runner** | `test/domain/fixture_engine_test.dart` | 2 (106 scenarios) | **ALL PASS** (0.9s) |
| **Workout Engine Pure-Dart** | `test/domain/workout_engine_test.dart` | 12 | **ALL PASS** (0.9s) |
| **Repository Integration** | `test/data/workout_repository_test.dart` | 8 | **ALL PASS** (1.2s) |
| **Design System / Widget** | `test/ui/design_system_test.dart` | 6 | **ALL PASS** (1.5s) |
| **Widget Smoke Test** | `test/widget_test.dart` | 1 | **ALL PASS** (1.0s) |
| **E2E Flow (LTR & Arabic RTL)** | `test/features/workout_flow_test.dart` | 4 | **ALL PASS** (13.5s) |
| **Total Flutter Test Suite** | | **48** | **ALL PASS (100%)** |

### Python QA Suites (`python tools/quality/run_all_checks.py`)
1. `validate_fixtures.py`: Exercise catalog (14 movements) and engine scenarios (106 total: 59 positive, 47 negative) verified.
2. `test_validation.py`: 21 mutation and negative validator tests passing.
3. `validate_links.py`: Checked 51 Markdown files; 0 broken relative links.
4. `check_hygiene.py`: Zero prohibited secret keys, private photos, or oversized blobs.

---

## 8. PR & Next Step Status
- **PR #12:** Kept in **DRAFT** status on branch `campaign/c3-flutter-core`.
- **Merge Gate:** Will not be merged until exact-head GitHub Actions CI completes and independent lead review confirms all acceptance gates.
- **Recommended Next Campaign:** Campaign C4 (Localization & Visual Refinement) or C5 (Advanced Audio / Haptics / Rest Timer hardening).
