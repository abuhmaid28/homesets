# HOMESETS — CI Pipeline & Quality Assurance Matrix Draft (Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G7 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)
**Authority Reference:** `docs/DECISION_REGISTER.md` (GOV07, GOV08, GOV10), `docs/AGENT_AUTONOMY_POLICY.md`

---

## 1. CI Status & Guarded Merge Pre-Condition

### 1.1 Current CI Availability: ABSENT
- GitHub Actions workflow (`.github/workflows/ci.yml`) is **NOT YET CONFIGURED** in the repository.
- **Strict Policy Rule (GOV08):** In accordance with `docs/AGENT_AUTONOMY_POLICY.md` line 29, **no implementation code or runtime Flutter PR may be merged into `main`** until an exact-head GitHub Actions workflow exists and reports demonstrably green.
- Local command executions alone do NOT authorize implementation PR merges.

---

## 2. Proposed Exact-Head CI Check Matrix (Milestone P0+)

When initialized in Campaign G7 / Milestone P0, every implementation PR must pass the following continuous integration matrix on the exact PR head commit:

```text
[ GitHub Actions: PR Head Commit ]
       │
       ├── Step 1: Code Formatting Check
       │     `dart format --output=none --set-exit-if-changed .`
       │
       ├── Step 2: Strict Static Analysis
       │     `flutter analyze --fatal-infos`
       │
       ├── Step 3: Pure Dart Engine Unit Tests
       │     `flutter test test/domain/engine/` (Architecture target: verify double progression, fatigue, recovery)
       │
       ├── Step 4: Widget & RTL Accessibility Tests
       │     `flutter test test/widgets/` (Touch targets >=48dp, RTL mirroring, contrast)
       │
       ├── Step 5: Data Migration & Backup Integrity Tests
       │     `flutter test test/database/` (Schema migrations v1->vX, backup round-trip)
       │
       └── Step 6: Android Debug APK Compilation Build
             `flutter build apk --debug` (Verifies buildable Android artifact)
```

*(Note: The test commands above represent the planned verification pipeline for Milestone P0+. Zero test directories or runtime Flutter code currently exist in the repository.)*

---

## 3. Targeted Test Categories & Methodologies

### 3.1 Pure-Dart Plan Engine Unit Tests (Target: $\ge 90\%$ Coverage)
- **Double Progression Scenarios:**
  - Verify reps advance when all sets are rated "Right" / "Easy" within bracket.
  - Verify band rung advances and reps reset when top bracket is exceeded.
  - Verify load holds or steps back when rated "Hard" with falling reps across consecutive sessions.
- **Muscle Recovery Spacing:**
  - Verify sessions targeting overlapping primary muscles (e.g., Pull-ups and Band Rows) enforce a minimum 24–48 hour recovery window before being scheduled next in rotation.
- **Absence Handling:**
  - Verify 1–6 days missed resume next rotation without penalty.
  - Verify 7–14 days missed trigger an automatic lighter re-entry session with 30–40% volume reduction.
  - Verify 15+ days absence prompt a recalibration check.
- **Injury / Avoided Joints Exclusion:**
  - Verify movements tagged with contraindicated joints (e.g., Shoulder impingement) are strictly removed from candidate pool.

### 3.2 Private Photo Storage & Privacy Verification
- **Test:** Verify all progress photos are saved exclusively in `app_flutter/private_photos/`.
- **Test:** Verify `android.permission.READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE` are absent.
- **Test:** Verify `android.permission.INTERNET` is completely absent from `AndroidManifest.xml`.
- **Test:** Verify Android MediaStore indexing is bypassed (no public gallery visibility).

### 3.3 Database Migration & Backup Round-Trip Tests
- **Schema Migration Tests:** Test programmatic migration from initial schema v1 to any subsequent schema versions, asserting zero data loss across existing workout logs and photos.
- **Backup Round-Trip Test:**
  1. Populate mock database with 20 workout sessions, 60 set logs, and 3 test photos.
  2. Export `.homesets` backup archive.
  3. Wipe mock database completely.
  4. Import `.homesets` backup archive.
  5. Assert bit-for-bit parity across all restored relational records and photo files.

### 3.4 Accessibility & RTL Golden Tests
- Golden tests for Today, Workout Player, and Progress screens rendered in `ar_EG` (Egyptian Arabic RTL).
- Verify directional arrows flip correctly; verify numeric timers remain LTR (`01:30`).
- Touch target size assertions verifying all interactive widgets meet $\ge 48\times 48$ dp ($\ge 56\times 56$ dp in Workout Player).

---

## 4. Workout Safety Requirements: Confirmed vs. Proposed

All exercise and load progression logic is classified as **[Proposed pending qualified fitness safety review]**, never as clinical or medical prescriptions.

| Principle / Rule | Status | Source / Evidence | Safety Rationale |
| :--- | :--- | :--- | :--- |
| **No Medical Diagnosis** | **[Confirmed]** | D05, D15, Master §0 | The app is an autonomous training log, not a clinical tool. No BMI labeling or clinical claims. |
| **Acute Pain Stop Precedence** | **[Proposed Safety Policy]** | Master §11 | Acute joint discomfort triggers **immediate cessation and joint rest**. Never automatically prescribe an alternative loaded movement during acute pain. |
| **Band Assistance vs Resistance**| **[Proposed Safety Policy]** | C1 Review | **Crucial Distinction**: In assisted pull-ups, heavier bands provide MORE upward assistance (EASIER). In resisted movements (push-ups/rows), heavier bands increase tension (HARDER). Universal color ladders are prohibited. Progression must be exercise-specific. |
| **Double Progression** | **[Proposed]** | Master §4, §11 | Evidence-backed progressive overload; advance one variable at a time (reps first within range, then external tension/rung). |
| **1–3 Reps-in-Reserve (RIR)** | **[Proposed]** | Master §4 | Keeps sets challenging for hypertrophy without excessive failure fatigue. |
| **24–48h Recovery Window** | **[Proposed]** | Master §4, §11 | Allows systemic and local muscle tissue repair before reloading the same muscle group. |
| **Absence Deload ($\ge 7$ days)**| **[Proposed]** | D15, Master §11 | Protects unconditioned muscles and tendons from acute soreness/injury after time off. |
| **Bands-Only Leg Limitation** | **[Confirmed]** | Master §4, D09 | Honest messaging: resistance bands have limits for heavy lower-body overload. Unilateral and tempo variations used. |

---

## 5. Candidate Tooling & Dependencies License Inventory (Pre-G6 Review Only)

> **IMPORTANT POLICY GUARD:** All items below are **proposed candidates only**. No dependencies are added to `pubspec.yaml` in Campaign C1. Formal dependency addition remains strictly blocked until Product Owner Gate G6 approval.

Verified against pub.dev and official upstream repositories as of November 2026:

| Package / Action | Upstream Version (pub.dev / GitHub) | License | Min Dart / SDK Requirement | Upstream Source & Notes |
| :--- | :--- | :--- | :--- | :--- |
| `actions/checkout` | `v4` | MIT | N/A | GitHub Actions Official (2026) |
| `actions/setup-java` | `v4` | Apache-2.0 | N/A | GitHub Actions Official (2026) |
| `subosito/flutter-action` | `v2` | MIT | N/A | GitHub Community Action (2026) |
| `drift` | `2.35.4` | MIT | Dart >= 3.8.0 | Simon Binder / Pub.dev (Active 2026) |
| `drift_flutter` | `0.3.1` | MIT | Dart >= 3.8.0, Flutter >= 3.24.0 | Simon Binder / Pub.dev (Active 2026) |
| `flutter_local_notifications` | `23.0.2` | BSD-3-Clause | Dart >= 3.12.0, Android compileSdk 35/36 | Michael Bui / Pub.dev (Active 2026) |
| `intl` | `0.19.0` (or `^0.20.x`) | BSD-3-Clause | Dart >= 3.0.0 | Dart.dev Official (Active 2026) |
| `cairo` font | Latest | SIL OFL 1.1 | Open Font License | Google Fonts (Free redistribution) |
