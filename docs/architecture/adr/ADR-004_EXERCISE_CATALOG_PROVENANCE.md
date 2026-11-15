# ADR-004: Exercise Catalog Provenance, Immutability, and Asset Licensing

- **Status:** Recommended (Architecture Baseline)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `DECISION_REGISTER.md` (D04, D09, O04), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

HOMESETS requires a curated library of calisthenics, pull-up bar, and resistance-band exercises. In many commercial apps, exercise libraries are fetched from remote clouds, contain copyright-encumbered video files, or assume access to commercial gym machinery (cables, dumbbells, barbells).

How should the exercise catalog be structured, stored, and licensed to guarantee total offline functionality, zero copyright infringement, and strict adherence to the owner's equipment constraints?

---

## Decision Drivers

1. **Equipment Constraint (D09):** Bar, resistance bands, and bodyweight ONLY. No weights, no dumbbells, no cables.
2. **Zero Recurring Cost & Total Offline Availability (D02):** The catalog must be bundled statically within the app assets; zero remote API dependencies.
3. **Asset Licensing & Provenance (O04):** No scraping of copyrighted fitness videos or proprietary workout animations.
4. **Calisthenics Progression Paths:** Clear progression pathways from zero-pull-up beginner (band-assisted, negatives) to advanced bodyweight variations.

---

## Considered Options

- **Option A: Static Bundled JSON Catalog + Vector Anatomy Cues (Recommended)**
  - All exercise definitions, muscle maps, setup cues, and safety warnings compiled into a versioned asset file (`assets/data/exercise_catalog.json`).
  - Clear provenance documentation for every exercise movement.
  - Zero video files; visual cues provided via lightweight offline SVG vector anatomy diagrams or static line drawings.
- **Option B: Bundled High-Resolution Video Clips**
  - MP4 clips embedded in the APK. Results in a massive APK ($>150$MB) and severe licensing risks.
- **Option C: Remote CDN Fetch on Launch**
  - Contradicts the absolute offline requirement (D02).

---

## Decision Outcome

**Chosen Option:** **Option A: Static Bundled JSON Catalog with Semantic Progression Links**.

### Architectural Contract:
1. Catalog schema is immutable at runtime; user custom variations are stored in a separate local SQLite user-exercise table.
2. Every catalog record includes:
   - Primary and secondary muscular targets.
   - Specific equipment requirements (e.g. `pull_up_bar`, `heavy_loop_band`, `door_anchor`).
   - Calisthenics skill prerequisites.
   - Non-provocative alternative mapping (for pain-free movement swap).
   - Natural Egyptian Arabic and standard English terminology.
3. Provenance and movement descriptions are authored under permissive open documentation standards (Public Domain / CC-BY).
