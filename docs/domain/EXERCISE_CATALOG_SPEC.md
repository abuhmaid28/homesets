# HOMESETS — Exercise Catalog & Movement Provenance Specification

**Document Status:** [Active Domain Specification — Hardened]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-R (Issue #10)  
**Fixture Source:** `docs/domain/fixtures/exercise_catalog.json`  
**Authority Reference:** `DECISION_REGISTER.md` (D04, D09, O04), `docs/PROJECT_RULES.md`, `docs/domain/SAFETY_INVARIANTS.md`  

---

## 1. Catalog Scope & Calisthenics Progression Paths

The HOMESETS exercise catalog is curated strictly around home calisthenics and resistance/assistance bands (D09). Standard equipment consists exclusively of a doorway pull-up bar and loop resistance bands. Unowned hardware (e.g. barbells, dumbbells, commercial machines) is never required or prompted.

### 1.1 Complete Movement Inventory (14 Exercises)

| Exercise ID | Movement Pattern | Equipment Required | Optional Accessories | Primary Muscles |
| :--- | :--- | :--- | :--- | :--- |
| `pullup_standard` | `VERTICAL_PULL` | `pull_up_bar` | — | Latissimus dorsi, Biceps brachii |
| `pullup_wide` | `VERTICAL_PULL` | `pull_up_bar` | — | Latissimus dorsi, Teres major |
| `chinup_neutral` | `VERTICAL_PULL` | `pull_up_bar` | — | Biceps brachii, Latissimus dorsi |
| `pullup_negative` | `VERTICAL_PULL` | `pull_up_bar` | — | Latissimus dorsi, Biceps brachii |
| `pulldown_door_band` | `VERTICAL_PULL` | `resistance_bands` | `door_anchor` | Latissimus dorsi, Rhomboids |
| `row_band_bent_over` | `HORIZONTAL_PULL` | `resistance_bands` | — | Rhomboids, Latissimus dorsi |
| `row_table_inverted` | `HORIZONTAL_PULL` | `bodyweight` | Sturdy heavy table | Rhomboids, Latissimus dorsi |
| `pushup_standard` | `HORIZONTAL_PUSH` | `bodyweight` | — | Pectoralis major, Triceps brachii |
| `pushup_incline_hands_elevated` | `HORIZONTAL_PUSH` | `bodyweight` | Stable chair/wall | Pectoralis major, Triceps brachii |
| `pushup_decline_feet_elevated` | `HORIZONTAL_PUSH` | `bodyweight` | Stable bench/chair | Pectoralis major, Anterior deltoid |
| `pushup_band_resisted` | `HORIZONTAL_PUSH` | `resistance_bands` | — | Pectoralis major, Triceps brachii |
| `curl_band_biceps` | `ISOLATION_ARM` | `resistance_bands` | — | Biceps brachii, Brachialis |
| `squat_bodyweight` | `QUAD_DOMINANT` | `bodyweight` | — | Quadriceps, Gluteus maximus |
| `lunge_reverse` | `QUAD_DOMINANT` | `bodyweight` | — | Quadriceps, Gluteus maximus |

### 1.2 Zero-Pull-Up Beginner Progression Path
For a user starting with 0 unassisted pull-ups, the engine never prescribes an impossible unassisted set. Instead, it utilizes the following regression hierarchy:
1. **Level 1 (Foundation):** Kneeling Band Lat Pulldowns (`pulldown_door_band`) — builds neural lat activation and scapular depression. *(Note: requires door anchor or overhead beam; if unavailable, standing bent-over band rows `row_band_bent_over` are used).*
2. **Level 2 (Eccentric Overload):** Controlled Pull-Up Negatives (`pullup_negative`) — jumping to top position and lowering under strict 4–5 second tempo.
3. **Level 3 (Band-Assisted):** Heavy Loop-Band Assisted Pull-Ups — band looped under knees/feet to subtract load.
4. **Level 4 (Unassisted Graduation):** Standard and Wide-Grip Bodyweight Pull-Ups (`pullup_standard`, `pullup_wide`).

### 1.3 Push-Up Double Progression & Mechanical Leverage Path
To provide continuous progressive overload without external iron weights:
1. **Regression:** Incline Push-Up (Hands Elevated) (`pushup_incline_hands_elevated`) reduces effective body mass percentage.
2. **Base:** Standard Floor Push-Up (`pushup_standard`) (12–15 rep bracket ceiling).
3. **Mechanical Leverage Advance:** Decline Push-Up (Feet Elevated) (`pushup_decline_feet_elevated`) shifts center of mass toward shoulders and clavicular pectoral fibers.
4. **Elastic Accommodating Resistance:** Band-Resisted Push-Up (`pushup_band_resisted`) matches the muscular strength curve with peak band tension at full lockout.

### 1.4 Zero-Bands (Pure Bodyweight) Fallback Path
If a user has no bands or is traveling:
- Inverted Table Rows (`row_table_inverted`) replace band rows for horizontal pulling.
- Push-Up leverage ladder (`pushup_incline_hands_elevated` $\to$ `pushup_standard` $\to$ `pushup_decline_feet_elevated`).
- Bodyweight Air Squats (`squat_bodyweight`) and Reverse Lunges (`lunge_reverse`).

---

## 2. Equipment Rules, Accessories & Furniture Safety

### 2.1 Door Anchor Specification (D09 Alignment)
Per Product Decision D09, the canonical HOMESETS equipment inventory consists strictly of a **pull-up bar** and **resistance bands**. 
- A **door anchor** is an optional accessory, not a mandatory prerequisite for using bands.
- If `hasDoorAnchor == false`, the engine never prescribes overhead anchor pulldowns (`pulldown_door_band`); it routes to standing bent-over rows (`row_band_bent_over`) or foot-anchored rows.
- If a door is detected as hollow, weak-latched, or swings toward the user, the anchor is disallowed to eliminate anchor slippage or door damage (SAFE-01).

### 2.2 Inverted Table Row Structural Verification
- Inverted table rows require users to suspend their bodyweight beneath household furniture.
- Safety invariant requires explicit verification that the table is heavy, solid-wood, and structurally load-bearing before prescribing or starting this movement.

### 2.3 Pull-Up Bar Grip Variations
- `chinup_neutral` utilizes parallel grip handles if available on multi-grip doorway bars.
- If only a straight doorway bar is available, standard supinated (underhand) grip is utilized as the shoulder-friendly alternative.

---

## 3. Anatomical & Joint Safety Tags

Every movement is tagged with potential joint impingement vectors (`joint_stress_tags`). If a user marks an anatomical area as avoided (or experiences pain), the engine immediately filters out all matching exercises:

| Joint Impact Tag | Affected Biomechanics | Provocative Exercises | Non-Provocative Safe Alternates |
| :--- | :--- | :--- | :--- |
| `SHOULDER_SUBACROMIAL` | Extreme overhead humeral abduction | `pullup_wide`, `pullup_standard` | `chinup_neutral`, `row_band_bent_over` |
| `ELBOW_MEDIAL` | Heavy supinated elbow flexion | `chinup_neutral`, `curl_band_biceps` | `pullup_standard` (pronated), `row_band_bent_over` |
| `WRIST_COMPRESSION` | Extension under compression | `pushup_standard`, `pushup_decline_feet_elevated` | Incline push-up (parallettes/fist grip), `row_band_bent_over` |
| `LUMBAR_SHEAR` | Unsupported hip hinge | `row_band_bent_over` | `pulldown_door_band`, `curl_band_biceps` |
| `KNEE_PATELLAR` | Deep acute knee flexion | Forward lunges, deep squats | `lunge_reverse`, isometric wall sits |

---

## 4. Provenance & Asset Licensing

- **Biomechanical Descriptions & Cues:** Movement cues, anatomical mappings, and safety warnings represent original documentation authored for HOMESETS, derived from established open kinesiological domain principles.
- **Zero Third-Party Media:** The catalog contains zero proprietary video clips, copyrighted photography, or commercial fitness training plans.
- **Visual Assets Plan:** In Phase 5+, visual guidance will utilize lightweight, offline vector SVG line art and muscle schematics created specifically for this repository.
