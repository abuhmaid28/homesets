# HOMESETS — C2-MEGA Consolidated Product Owner Decision Package

**Document Status:** [Final Decision Package for Ahmed]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Target Pull Request:** [Draft PR #9](https://github.com/abuhmaid28/homesets/pulls) (Branch `campaign/c2-mega-foundation`)  
**Design Reference:** [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5)  

---

## 1. Executive Summary for Product Owner (Ahmed)

Campaign **C2-MEGA** is complete across all 28 authorized work packages. We have engineered the complete architectural blueprint, training safety invariants, failure-recoverable storage models, 106 structured scenario fixtures, and foundation quality tooling.

In strict compliance with `docs/AGENT_AUTONOMY_POLICY.md` and Decision GOV08:
- **Zero runtime Flutter application code** has been authored.
- **Zero dependencies** have been installed into `pubspec.yaml`.
- This pull request is submitted as a **DRAFT** for your review.

To advance to implementation (Milestone P0+), five grouped decisions are prepared for your review:

---

## 2. Grouped Decision Gates for Product Owner

### Decision Gate 1: Visual Design Direction Selection (Gate G4)
On Draft PR #5, two complete visual design directions were rendered and verified across all target viewports. Please choose your preferred visual identity:

- **Option 1A: Direction A (Performance Stealth)**
  - *Aesthetic:* Deep matte charcoal (`#0D0E11`), sharp 1px borders, zero glow, monospace telemetry, technical athlete density.
  - *Screenshots:* [Dir A Today](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_a_today_390x844.png) | [Dir A Workout](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_a_workout_390x844.png) | [Dir A Rest](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_a_rest_390x844.png)
- **Option 1B: Direction B (Kinetic Depth) — [RECOMMENDED]**
  - *Aesthetic:* Warm dark charcoal (`#121316`), elevated cards (`#1C1E26`), soft neon glow shadows (`rgba(204,255,0,0.18)`), rounded tactile pills, energetic athlete motivation.
  - *Screenshots:* [Dir B Today](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_b_today_390x844.png) | [Dir B Workout](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_b_workout_390x844.png) | [Dir B Rest](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_b_rest_390x844.png)
- **Option 1C: Hybrid (Kinetic Depth + Tabular Precision)**
  - Combines Direction B’s warm card elevation with Direction A’s monospace tabular numerals for countdown timers.

---

### Decision Gate 2: Training Safety & Overload Physics (Gate G6)
- **Zero External Weights Enforced (D09):** All pull-up progression uses bodyweight rep brackets (6–8–10), 2-second top pause cadence, and inverse band assistance rungs. No added weights or backpack loading.
- **Stop-First Pain Precedence:** When acute joint pain is reported, all loaded work for that joint halts immediately. The app does NOT prescribe an immediate loaded alternative on the spot.
- **Qualified Review Flag:** Safety boundaries represent conservative S&C standards, but software does not replace personalized medical advice.

---

### Decision Gate 3: Local Storage & Crash-Recoverable Backup Model
- **Scoped App Sandbox:** Physique photos stored strictly in internal app directory (`files/physique_photos/`) with `.nomedia`. Zero visibility in Google Photos or phone gallery.
- **Android 12–16 Data Extraction:** Manifest blocks automatic cloud backups and device-to-device transfers via XML `dataExtractionRules`.
- **Failure-Recoverable Restore:** Restores extract to a staging sandbox, validating SHA-256 and SQLite `PRAGMA integrity_check` before an atomic two-phase swap with rollback snapshot.

---

### Decision Gate 4: Minimal Dependency Stack Selection
Please approve the dependency footprint for Milestone P2+:

- **Stack Option 4A: Typed Drift Architecture [RECOMMENDED]**
  - `drift: ^2.24.0`, `drift_flutter: ^0.2.0`, `path_provider: ^2.1.5`, `intl: ^0.20.1`, `uuid: ^4.5.1`, `crypto: ^3.0.6`, `archive: ^3.6.1`, `flutter_local_notifications: ^18.0.1`.
  - *Benefit:* Compile-time SQL verification and declarative schema migrations.
- **Stack Option 4B: Zero-Codegen Sqflite Architecture [FALLBACK]**
  - Substitutes `sqflite: ^2.4.1` for Drift. Zero code generation build steps; raw SQL queries.

---

### Decision Gate 5: Authorization to Proceed to Implementation (C3 / P0+)
- Upon your review and approval of the gates above:
  1. Authorize candidate dependencies in `pubspec.yaml`.
  2. Implement Milestone P0: Pure-Dart Plan Engine in `lib/domain/engine/` and unit test suite in `test/domain/engine/`.
  3. Merge exact-head Flutter CI workflow to enforce quality gates on all subsequent PRs.
