# HOMESETS — C1-V2 Final Product Owner Review Package

**Document Status:** [Final Review Package]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-14  
**Target Pull Request:** [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5)  
**Tracking Issues:** [GitHub Issue #7](https://github.com/abuhmaid28/homesets/issues/7), [GitHub Issue #4](https://github.com/abuhmaid28/homesets/issues/4)  

---

## 1. Executive Summary for Product Owner (Ahmed)

Campaign **C1-V2** is complete. All 12 authorized work packages have been executed autonomously, delivering:
1. **Two Complete Visual Directions:** **Direction A (Performance Stealth)** and **Direction B (Kinetic Depth)** within our preferred charcoal + Performance Lime identity.
2. **Offline Interactive Prototype:** A fully functional vanilla JS prototype (`design/preview/prototype.html`) evaluating the entire workout flow, rest countdown, and joint pain safety stops.
3. **100% Defect Resolution (V2-D01 to V2-D10):** BiDi punctuation wrapping, fragmented English titles, mid-screen workout dead space, and technical rest jargon have all been resolved.
4. **Reproducible Screenshot Gallery:** 26 multi-viewport screenshots rendered and committed directly inside Git via `design/reviews/c1-v2/render_gallery.py`, resolving all previous 404 image issues.
5. **Campaign C2 Technical Preflight:** Staged database restore boundaries, scoped storage rules, pure-Dart test suite specs, and CI preflight documents prepared.

PR #5 remains in **DRAFT** status in strict compliance with Decision GOV08. Zero runtime Flutter production code or dependencies were added.

---

## 2. Grouped Decision Package for Product Owner Review

To advance from design foundation to implementation, please review and select from the following 4 decisions:

### Decision 1: Visual Design Direction Selection (Gate G4)
- **Option 1A: Direction A (Performance Stealth)**
  - *Aesthetic:* Deep matte charcoal (`#0D0E11`), sharp 1px borders, zero glow, monospace telemetry, technical athlete density.
  - *Preview:* [direction_a_stealth.html](../../design/explorations/direction_a_stealth.html)
- **Option 1B: Direction B (Kinetic Depth) — [RECOMMENDED]**
  - *Aesthetic:* Warm dark charcoal (`#121316`), elevated cards (`#1C1E26`), soft neon glow shadows (`rgba(204,255,0,0.18)`), rounded tactile pills, energetic athlete motivation.
  - *Preview:* [direction_b_kinetic.html](../../design/explorations/direction_b_kinetic.html)
- **Option 1C: Hybrid (Kinetic Depth + Tabular Precision)**
  - Combines Direction B’s elevated tactile surfaces with Direction A’s monospace tabular numbers for jitter-free countdown timers.

---

### Decision 2: Workout Flow & Rest Feedback Ergonomics
- **Approved Implementation Pattern:**
  - One-handed thumb-zone rep stepper (`[-] [8] [+]`) centered in lower 40% of viewport.
  - Muscular activation card and set progression table filling mid-screen dead space without overflowing small viewports.
  - Natural Egyptian Arabic exertion feedback pills:
    1. `فاضل طاقة (سهل) 💪`
    2. `مظبوط ومثالي 👍`
    3. `على الآخر (صعب) 🔥`
  - Replaces cryptic technical jargon (`RIR 1-2`, `RPE 8-9`).

---

### Decision 3: Interactive Prototype Evaluation
- **Offline Prototype:** Open [design/preview/prototype.html](../../design/preview/prototype.html) in any browser.
- **Key Flows to Test:**
  1. *Today Screen -> Start Workout (25 min)*: Instant 1-tap transition.
  2. *Set Stepper & Logging*: Increment reps, tap `تسجيل المجموعة واسترخاء`.
  3. *Live Rest Timer*: Watch 90s countdown tick down, test `+30 ثانية` and `تخطي وبدء الآن`.
  4. *Joint Pain Stop Protocol*: Tap `🛑 هل تشعر بألم في المفصل؟` -> safely terminates session, preserves completed sets, and excludes offending movements.
  5. *Workout Summary*: Displays duration, completed sets, and updates weekly streak (`4/4 🔥`).

---

### Decision 4: Architecture & CI Scope for Campaign C2
- **Plan Engine Boundary:** Pure-Dart isolated logic in `lib/domain/engine/` (zero Flutter/UI/DB imports) enabling sub-second unit tests on workstations and CI.
- **Database Restoration Safeguard:** Restores staged in `cacheDir/restore_staging` with SHA-256 and `PRAGMA integrity_check` before atomic swap.
- **Candidate Dependencies for C2:** `drift: ^2.24.0`, `drift_flutter: ^0.2.0`, `sqlite3_flutter_libs: ^0.5.24`, `path_provider: ^2.1.5`, `uuid: ^4.5.1`, `crypto: ^3.0.6`, `intl: ^0.20.1`.
- **CI Pipeline:** `.github/workflows/ci.yml` initialized in Milestone P0 to enforce formatting, analysis, pure-Dart unit tests, and APK compilation on exact PR heads.

---

## 3. Verifiable Delivery Evidence

- **Committed Screenshot Generator:** `design/reviews/c1-v2/render_gallery.py`
- **Rendered Gallery Index:** [design/reviews/c1-v2/INDEX.md](../../design/reviews/c1-v2/INDEX.md) (26 verified captures)
- **Defect Matrix:** [docs/reviews/C1V2_BASELINE_AND_DEFECT_MATRIX.md](C1V2_BASELINE_AND_DEFECT_MATRIX.md)
- **Adversarial QA:** [docs/reviews/C1V2_INDEPENDENT_QA.md](C1V2_INDEPENDENT_QA.md)
- **A/B Diff & Decision Sheet:** [docs/reviews/C1V2_VISUAL_DIFF_AND_DECISION.md](C1V2_VISUAL_DIFF_AND_DECISION.md)
- **Architecture Readiness:** [docs/architecture/C2_READINESS_REVIEW.md](../architecture/C2_READINESS_REVIEW.md)
- **CI Preflight:** [docs/quality/C2_CI_PREFLIGHT.md](../quality/C2_CI_PREFLIGHT.md)
- **Campaign Checkpoint:** [docs/campaigns/C1-V2_CHECKPOINT.md](../campaigns/C1-V2_CHECKPOINT.md)

---

## 4. Next Recommended Campaign

Upon Product Owner review and decision selection on PR #5:
- **Campaign C2 (Pure-Dart Plan Engine & Database Foundation):**
  1. Authorize candidate dependencies in `pubspec.yaml`.
  2. Implement `lib/domain/engine/` (Double progression, recovery spacing, absence deload, pain stop filters).
  3. Implement `test/domain/engine/` (Target $\ge 95\%$ domain test coverage).
  4. Setup `.github/workflows/ci.yml` and establish the first passing exact-head CI run.
