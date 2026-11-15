# HOMESETS Campaign C2-R — Consolidated Product Owner Gate Package

**Document Status:** [Awaiting Product Owner Decision]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Product Owner:** Ahmed (@abuhmaid28)  
**Target Pull Request:** [Draft PR #9](https://github.com/abuhmaid28/homesets/pull/9)  
**Verification Baseline:** Commit `c43420af` + C2-R Verification Suite  

---

## 1. Executive Summary

Campaign C2-R successfully completed a comprehensive audit and remediation of all seven technical defects (R-C2-01 through R-C2-07) identified in the engineering foundation:
1. Hardened fixture validation with strict schema typing and relational integrity.
2. Eliminated duplicate test vectors, achieving 106 unique scenarios.
3. Added missing movements (`pushup_decline_feet_elevated`, `pushup_band_resisted`) to complete bidirectional referential integrity across all 14 catalog exercises.
4. Audited equipment safety (door anchor clarified as optional accessory per D09; table row load-bearing furniture check).
5. Implemented a 21-case mutation test suite proving validators reject invalid data.
6. Refined specifications to eliminate unscientific claims ("mathematical proofs", "rhabdomyolysis prevention") in favor of empirical modeling and qualified review flags.
7. Maintained strict boundaries: **zero Flutter runtime code** (`lib/`, `test/`) and **zero dependencies** added to `pubspec.yaml`.

This package consolidates the key decisions required from Ahmed to transition from foundation architecture into implementation.

---

## 2. Product Owner Decision Items

### Decision 1: Visual Direction Selection (from Campaign C1)
- **Option A (Industrial High-Contrast Dark):** Pure black (`#0B0D0F`), safety orange accents (`#FF5E1E`), high-visibility bold typography, rugged mechanical feel.
- **Option B (Minimalist Dark Utility):** Deep obsidian (`#121417`), electric amber/teal accents, subtle cards, refined micro-borders.
*Recommendation:* Proceed with Option A as the primary workout execution theme, with subtle card styling influenced by Option B.

### Decision 2: Hardware & Equipment Rules (D09 Hardening)
- Standard HOMESETS equipment remains strictly: **Doorway Pull-up Bar** and **Resistance Bands**.
- A **door anchor** is classified as an optional accessory. If not owned, the engine automatically selects standing bent-over rows (`row_band_bent_over`) rather than overhead door pulldowns.
- Inverted table rows require solid, heavy furniture; a safety verification check is displayed before first execution.
*Recommendation:* Approve the clarified hardware boundaries.

### Decision 3: Safety Invariants & Prolonged Absence Deload
- **SAFE-01 (1-Tap Pain Stop):** Immediate stop on joint pain tap; completed sets preserved; exercise quarantined from future rotations; zero immediate loaded substitution.
- **SAFE-03 (Absence Deload):** For absences $\ge 14$ days, volume is conservatively reduced by ~30–40% to mitigate severe soreness and overtraining.
- **SAFE-05 (Zero Medical Claims):** App never diagnoses injuries; prompts conservative first-aid and medical consultation.
*Recommendation:* Approve the safety rules as conservative baseline heuristics pending future qualified clinical review.

### Decision 4: Local Storage, Privacy & Restore Architecture
- **Physique Photos:** Stored strictly in internal app sandbox (`/data/user/0/.../files/physique_photos/`) with `.nomedia` sentinel. Completely hidden from phone gallery.
- **OS Data Extraction:** Modern Android 12–16 XML `dataExtractionRules` deployed to block unencrypted Google Drive cloud backups and device migration.
- **Failure-Recoverable Restore:** Two-phase restore pipeline with pre-swap `.snap` cold snapshot rollback to eliminate corruption during power loss.
*Recommendation:* Approve the offline storage and restore architecture.

### Decision 5: Dependency Authorization & Greenlight for Campaign C3
- Review candidate dependencies: `drift`, `drift_flutter`, `path_provider`, `flutter_local_notifications`, `intl`, `uuid`, `crypto`, `archive`.
- Authorize adding these vetted, permissive packages to `pubspec.yaml` in Campaign C3 to begin Flutter runtime implementation and domain engine coding.
*Recommendation:* Authorize Campaign C3 transition.

---

## 3. Physical Testing Notice

Per `AGENT_AUTONOMY_POLICY.md` and `AGENTS.md`, manual real-phone testing on Ahmed's physical device (Honor MagicOS 10) is deliberately deferred to the **final integrated APK acceptance test**. Earlier milestone verification relies strictly on automated headless suites, unit tests, and CI.
