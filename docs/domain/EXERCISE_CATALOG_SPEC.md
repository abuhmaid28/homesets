# HOMESETS — Exercise Catalog & Movement Provenance Specification

**Document Status:** [Active Domain Specification]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Fixture Source:** `docs/domain/fixtures/exercise_catalog.json`  
**Authority Reference:** `DECISION_REGISTER.md` (D04, D09, O04), `docs/PROJECT_RULES.md`  

---

## 1. Catalog Scope & Calisthenics Progression Paths

The HOMESETS exercise catalog is curated strictly around home calisthenics and resistance/assistance bands. It provides dedicated pathways for users at all baseline fitness levels:

### 1.1 Zero-Pull-Up Beginner Progression Path
For a user starting with 0 unassisted pull-ups, the engine never prescribes an impossible unassisted set. Instead, it utilizes the following regression hierarchy:
1. **Level 1 (Foundation):** Kneeling Door-Anchor Band Lat Pulldowns (`pulldown_door_band`) — builds neural lat activation and shoulder blade depression without bodyweight load.
2. **Level 2 (Eccentric Overload):** Controlled Pull-Up Negatives (`pullup_negative`) — jumping to the top and lowering under strict 4–5 second tempo.
3. **Level 3 (Band-Assisted):** Heavy Loop-Band Assisted Pull-Ups — band looped under knees/feet to subtract ~15–20kg of bodyweight.
4. **Level 4 (Unassisted Graduation):** Standard and Wide-Grip Bodyweight Pull-Ups (`pullup_standard`, `pullup_wide`).

### 1.2 Zero-Bands (Pure Bodyweight) Fallback Path
If a user has no bands or is traveling:
- Inverted Table Rows (`row_table_inverted`) replace band rows for horizontal pulling.
- Push-Up regressions (Hands-Elevated Incline `pushup_incline_hands_elevated` $\to$ Standard Floor `pushup_standard`).
- Bodyweight Air Squats (`squat_bodyweight`) and Reverse Lunges (`lunge_reverse`).

---

## 2. Anatomical & Joint Safety Tags

Every movement is tagged with potential joint impingement vectors (`joint_stress_tags`). If a user marks an anatomical area as avoided (or experiences pain), the engine immediately filters out all matching exercises:

| Joint Impact Tag | Affected Biomechanics | Provocative Exercises | Non-Provocative Safe Alternates |
| :--- | :--- | :--- | :--- |
| `SHOULDER_SUBACROMIAL` | Extreme overhead humeral abduction | Wide-Grip Pull-Up | Neutral-Grip Chin-Up, Bent-Over Band Row |
| `ELBOW_MEDIAL` | Heavy supinated elbow flexion | Chin-Ups, Heavy Bicep Curls | Neutral Grip Pull-Up, Pronated Band Pulldown |
| `WRIST_COMPRESSION` | Extension under compression | Floor Push-Ups | Fist Push-Ups, Band Rows |
| `LUMBAR_SHEAR` | Unsupported hip hinge | Bent-Over Band Row | Chest-Supported Row, Door Anchor Pulldown |
| `KNEE_PATELLAR` | Deep acute knee flexion | Forward Lunges, Deep Squats | Reverse Lunge, Band Romanian Deadlift |

---

## 3. Provenance & Asset Licensing

- **Biomechanical Descriptions:** Movement cues and technique warnings represent established open public domain kinesiology principles.
- **Visual Assets:** In Milestone P5+, visual guidance will use lightweight vector SVG muscle-activation schematics and line art authored specifically for HOMESETS under permissive open licenses. Zero proprietary fitness videos or commercial imagery are included.
