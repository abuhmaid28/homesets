# HOMESETS — MVP Test Traceability & Negative-Path Testing Matrix

**Document Status:** [Active Quality Architecture]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Fixture Reference:** `docs/domain/fixtures/engine_scenarios.json` (106 Scenarios)  
**Authority Reference:** `docs/ROADMAP.md`, `docs/PROJECT_RULES.md`  

---

## 1. Traceability Architecture (Requirements to Test Vectors)

This matrix maps every core functional requirement and safety invariant from Milestones P0 through P8 to concrete automated test cases and the 106 validated fixture vectors:

| Milestone | Functional Scope | Primary Test Vectors / Fixtures | Verification Method & Target Criteria |
| :--- | :--- | :--- | :--- |
| **P0: Quality Harness** | Fixture validation, link integrity, secret scanning, foundation CI. | `tools/quality/` (All 3 suites) | Python stdlib scripts; GitHub Actions `foundation.yml` passing on exact head. |
| **P1: Plan Engine** | Double progression, cadence pause, band assistance/resistance, recovery spacing. | `SCEN-001` through `SCEN-068` (68 vectors) | Pure-Dart unit tests in `test/domain/engine/`; $\ge 95\%$ domain test coverage in $<1$s. |
| **P1: Training Safety** | Pain stop precedence, zero provocative substitution, joint quarantine. | `SCEN-045` through `SCEN-056` (12 vectors) | Strict invariant tests; verify provocative exercise is quarantined; zero auto-prescriptions. |
| **P1: Lite Mode** | 15-minute routine pruning, time feasibility, preserved consistency. | `SCEN-079` through `SCEN-088` (10 vectors) | Mathematical timing model; verify sets pruned to 4; duration capped $\le 15$ min. |
| **P1: Equipment Fallbacks** | Zero pullup bar, zero bands, bodyweight-only calisthenics. | `SCEN-089` through `SCEN-098` (10 vectors) | Fixture evaluation; verify table rows and floor pulldowns substitute unowned bar. |
| **P1: Shift Work Boundaries** | Night shift wake window, midnight crossing, duplicate sessions. | `SCEN-099` through `SCEN-106` (8 vectors) | Timezone/UTC boundary unit tests; verify single session across midnight rollover. |
| **P2: Local Database** | SQLite schema v1, CRUD operations, foreign keys, write-order persistence. | `LOCAL_DATABASE_SPEC.md` | In-memory SQLite transaction tests; verify immediate write-order commit. |
| **P3: Onboarding UI** | Profile setup, hardware inventory, avoid-area checklist. | `SCEN-089`..`SCEN-098` | Flutter widget tests; keyboard focus; 1.5× text scaling scroll verification. |
| **P4: Today Screen** | 1-Tap start, weekly consistency ring, quick meal checklist. | `SCEN-069`..`SCEN-078` | Frame budget $<16$ms; 1-tap transition latency $<200$ms; zero streak penalties. |
| **P5: Workout Player** | Rep stepper, live rest timer (90s), exertion pills, emergency pain stop. | `SCEN-001`..`SCEN-044` | Widget interaction tests; timer tick cancellation; $\ge 48$dp touch targets. |
| **P6: Progress Hub** | Side-by-side photo comparison slider, rolling weight chart, zero gallery leakage. | `PHOTO_PRIVACY_AUDIT.md` | Android Scoped Storage audit; verify `.nomedia` creation; zero MediaStore records. |
| **P7: Backup & Restore** | ZIP export, Zip-Slip defense, expansion bomb ceiling, two-phase swap rollback. | `BACKUP_FORMAT_SPEC.md`<br>`RESTORE_FAILURE_MODEL.md` | Synthetic fault-injection tests; Zip-Slip rejection; simulated crash rollback. |
| **P8: Generalization** | Multi-profile isolation (e.g. female friend with different equipment/goals). | `DECISION_REGISTER.md` (D03, O07) | Profile data leakage tests; verify independent schema isolation. |

---

## 2. Negative-Path & Failure Mode Test Specifications

In addition to positive flows, the following 8 critical negative-path tests are formally specified:

| Negative Test ID | Failure Mode Scenario | Injection Method | Expected System Defense & Outcome |
| :--- | :--- | :--- | :--- |
| **NEG-01** | **Zip-Slip Directory Traversal** | Import archive containing `../../files/malicious.sh`. | Zip parser checks canonical path; detects directory escape; halts immediately with `SecurityException`; live data untouched. |
| **NEG-02** | **Zip Expansion Bomb** | Import archive containing 1 MB compressed file expanding to 1 GB. | Stream counter monitors uncompressed bytes; aborts extraction upon crossing 500 MB limit; purges staging directory. |
| **NEG-03** | **Corrupt Database File** | Import archive containing truncated SQLite database header. | Preflight runs `PRAGMA integrity_check`; detects corrupt page; rejects import; live DB remains completely untouched. |
| **NEG-04** | **Missing Photo in Archive** | `manifest.json` references photo that is missing or truncated in ZIP. | Preflight SHA-256 validation detects mismatch; import rejected; user alerted with actionable error modal. |
| **NEG-05** | **Process Killed Mid-Set (Crash Recovery)** | Android OS kills app process during Set 2 execution. | On next launch, app queries uncompleted session; displays recovery banner; user resumes from Set 2 with Set 1 preserved. |
| **NEG-06** | **Acute Joint Pain Mid-Set** | User reports sharp elbow pain during Set 1 of bicep curls. | Pain-stop protocol terminates session immediately; freezes bicep progression; disallows immediate loaded exercise. |
| **NEG-07** | **Unowned Equipment Requested** | User profile unchecks pull-up bar, but attempts to start Upper Pull routine. | Plan engine substitutes door anchor pulldowns and inverted table rows; zero purchase prompts. |
| **NEG-08** | **Notification Permission Denied** | User taps "Don't allow" on Android 13+ `POST_NOTIFICATIONS` dialog. | App gracefully silences reminder scheduler; zero recurring nagging dialogues; 100% core features remain operational. |
