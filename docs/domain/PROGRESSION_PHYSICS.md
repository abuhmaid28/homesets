# HOMESETS — Progression Physics per Equipment & Overload Algorithms

**Document Status:** [Active Domain Specification]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D05, D06, D09, D17), `docs/PROJECT_RULES.md`  

---

## 1. Absolute Hardware Constraints (Zero External Weights)

In strict accordance with Decision D09, the progression engine enforces:
- **NO added weight plates**
- **NO dumbbells or barbells**
- **NO weighted backpacks or loading vests**

Progressive overload in calisthenics is achieved through **double progression (reps bracket), mechanical leverage, tempo control, and calibrated elastic band rungs**.

---

## 2. Separate Progression Physics by Movement Type

### 2.1 Unassisted Bodyweight Pull-Ups (Reps & Pause Cadence)
Because external weight is unavailable, pull-up progression uses a **6–8–10 Reps Ladder with Cadence Overload**:

1. **Rep Bracket Expansion:**
   - Base target: 3 sets × 6 reps.
   - When all 3 sets hit 6 reps with exertion rated `مظبوط ومثالي` or `فاضل طاقة`, the target advances to 3 sets × 8 reps.
   - When all 3 sets hit 8 reps, the target advances to 3 sets × 10 reps.
2. **Tempo & Cadence Progression (Beyond 10 Reps):**
   - Once a user achieves 3 sets × 10 clean reps, adding more mindless reps leads to form breakdown and shoulder fatigue.
   - Overload advances to **Pause Cadence**: `3 sets × 8 reps with a 2-second hold at the top` (chin over bar) and a 3-second eccentric lower.
   - This increases mechanical tension by 40% without requiring added weights.

---

### 2.2 Band-Assisted Pull-Ups (Inverse Elastic Progression)
For assisted movements, **the physics is reversed**:
$$\text{Effective Load} = \text{Bodyweight} - \text{Band Assistance Force}$$
- Progressing means **reducing** the assistance band strength!

```text
Assistance Progression Ladder (Heavy to Unassisted):
  [ Rung 4: Heavy Purple Loop Band (~20-25kg assistance) ]
            │ (Hits 3x10 clean reps)
            ▼
  [ Rung 3: Medium Black Loop Band (~12-15kg assistance) ]
            │ (Hits 3x10 clean reps)
            ▼
  [ Rung 2: Light Red Loop Band (~6-8kg assistance) ]
            │ (Hits 3x10 clean reps)
            ▼
  [ Rung 1: Unassisted Bodyweight Pull-Ups (0kg assistance) ]
```

---

### 2.3 Band-Resisted Movements (Rows, Curls, Push-Ups)
For horizontal pulling and isolation exercises, **band tension adds load**:
$$\text{Effective Load} = \text{Base Resistance} + \text{Band Elastic Tension}$$
- Progressing means **increasing** band tension or adding an additional loop!

```text
Resisted Double Progression Algorithm:
  Target: 3 sets × 10–12 reps.
  1. Start on Band Rung 2 (e.g. Medium Band) at 3 × 10 reps.
  2. Maintain current band while reps increase: 10, 10, 10 -> 11, 10, 10 -> 12, 12, 12.
  3. When all 3 sets achieve 12 reps at `مظبوط ومثالي`:
     -> Step UP to Band Rung 3 (Heavy Band).
     -> Reset reps target back to the bottom of bracket: 3 × 8-10 reps.
```

---

## 3. Decision Matrix for Next-Session Prescription

| Current Set Log State | Exertion Rating | Engine Action for Next Cycle |
| :--- | :--- | :--- |
| **All sets hit top of rep bracket** (e.g. 10, 10, 10) | `فاضل طاقة (سهل) 💪` or `مظبوط 👍` | **ADVANCE:** Advance to next difficulty rung (heavier band for rows; lighter band for assisted pullups; cadence hold for unassisted pullups). Reset reps to bracket floor. |
| **Middle of rep bracket** (e.g. 9, 8, 8 in 8–10 bracket) | `مظبوط ومثالي 👍` | **HOLD & EXPAND:** Keep current band/leverage. Target: Add +1 rep to Set 2 or Set 3. |
| **Failed to hit bracket floor** (e.g. 7, 6, 5 in 8–10 bracket) | `على الآخر (أقصى مجهود) 🔥` | **HOLD LOAD:** Maintain current rung. Prompt +30s rest interval recommendation between sets. |
| **Two consecutive sessions below bracket floor** | `على الآخر (صعب) 🔥` | **FATIGUE DELOAD:** Reduce prescribed volume by 1 set or drop back 1 band rung to restore form. |
| **Any set terminated due to joint pain** | `🛑 ألم مفصلي غير طبيعي` | **IMMEDIATE HALT:** Freezes progression; excludes exercise from upcoming rotation; triggers safety review. |

---

## 4. Band Tension Calibration (No Universal Color Myth)

Different manufacturers use conflicting color codes (e.g., Red is 15 lbs in one brand, 30 lbs in another). HOMESETS resolves this by relying on **relative user-ordered ranks** (`Band 1 (Lightest)`, `Band 2`, `Band 3`, `Band 4 (Heaviest)`), calibrated during onboarding rather than hardcoding arbitrary color values.
