# HOMESETS Campaign C2-R — Engineering Baseline Audit

**Date:** 2026-11-15  
**Campaign:** C2-R (Foundation Rework & Validation Hardening)  
**Issue:** [#10](https://github.com/abuhmaid28/homesets/issues/10)  
**Pull Request:** [Draft PR #9](https://github.com/abuhmaid28/homesets/pull/9)  
**Baseline Commit HEAD:** `c43420af66108584a41cd2b061b13a30db77430e`  
**Branch:** `campaign/c2-mega-foundation`  
**Active CI Run:** Run ID [#43660778170](https://github.com/abuhmaid28/homesets/actions/runs/43660778170) (Status: SUCCESS, Duration: 12s, Event: pull_request)  

---

## 1. Executive Summary

Campaign C2-MEGA established 28 foundation work packages across architectural specifications, SQLite schema, zero-dependency validation tooling, and 106 engine test fixtures. 

An external engineering audit identified seven technical and conceptual defects (R-C2-01 through R-C2-07). Campaign C2-R was authorized to repair all seven defects, harden verification tooling with negative mutation testing, audit equipment safety, tone down unscientific guarantees, and produce a unified owner gate package without altering Flutter code (`lib/`, `test/`) or adding external dependencies.

---

## 2. Baseline State & Defect Register

| Defect ID | Severity | Component | Finding Description | Target Resolution |
| :--- | :--- | :--- | :--- | :--- |
| **R-C2-01** | High | `validate_fixtures.py` | Fixture validator only asserts dictionary key presence, count $\ge 100$, and ID uniqueness; ignores data types, allowed enums, value ranges, and relational links to catalog. | Implement semantic validator verifying strict types, enum validity, relational integrity, and non-empty values. |
| **R-C2-02** | High | `engine_scenarios.json` | Exact duplicate scenario vectors: `SCEN-089` == `SCEN-093`, and `SCEN-090` == `SCEN-094`. | Update generator with distinct physical boundary conditions and regenerate clean fixtures. |
| **R-C2-03** | High | `exercise_catalog.json` | Referential integrity broken: `SCEN-006` references `pushup_decline_feet_elevated` and `SCEN-041..044` reference `pushup_band_resisted`, both missing from catalog. | Add fully articulated, safety-tagged movement records for both exercises to catalog and specifications. |
| **R-C2-04** | Medium | `exercise_catalog.json` | Equipment and furniture safety: `pulldown_door_band` lists door anchor as mandatory equipment contrary to D09; inverted table rows lack load-bearing warning; chin-up neutral grip assumptions. | Tag door anchor as optional accessory; fallbacks must prioritize standard bar and bands; add structural furniture stability cues. |
| **R-C2-05** | Medium | Catalog Provenance | Dual conflicting licensing claims (`CC-BY-4.0` vs `Public Domain`). | Clarify provenance as original documentation based on open kinesiological principles; zero third-party media. |
| **R-C2-06** | Medium | `LITE_MODE_SPEC.md` & `SAFETY_INVARIANTS.md` | Overconfident phrasing ("mathematical proof", "safety guarantee", "prevents rhabdomyolysis", arbitrary deload numbers). | Soften claims to empirical estimates, target execution models, and conservative fatigue guidelines pending clinical review. |
| **R-C2-07** | High | Quality Tooling | Zero negative/mutation tests verifying that quality tooling actually fails on malformed or illegal inputs. | Create `test_validation.py` asserting validator failure modes on mutated inputs; integrate into CI runner. |

---

## 3. Tooling & Environment Verification

- **Python Version:** 3.12+ (standard library only: `json`, `pathlib`, `re`, `subprocess`, `unittest`, `sys`)
- **Git Remote:** `origin https://github.com/abuhmaid28/homesets.git`
- **Working Tree:** Clean, tracking `origin/campaign/c2-mega-foundation`
- **GitHub Workflow:** `.github/workflows/foundation.yml` active in remote repo, executing `python tools/quality/run_all_checks.py`.

---

## 4. Execution Plan Mapping

Campaign C2-R progresses through 4 phases and 20 work packages:
- **Phase A (WP01–WP05):** Reproducible Baseline & Scenario Integrity
- **Phase B (WP06–WP10):** Exercise Catalog & Training Safety Correctness
- **Phase C (WP11–WP15):** Foundation Tooling, CI & Robustness
- **Phase D (WP16–WP20):** Independent Audit & Owner Gate Handoff
