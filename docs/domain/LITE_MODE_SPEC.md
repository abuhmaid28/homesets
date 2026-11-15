# HOMESETS — Adaptive Lite Mode & Time-Feasibility Specification

**Document Status:** [Active Domain Specification]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D08, D12, D15), `docs/PROJECT_RULES.md`  

---

## 1. The Real-World Problem: Tired Days Before Shift Work

Ahmed works an exhausting night shift (7 PM – 4 AM) preceded by a 3-hour round-trip commute (D07). Waking up tired at 3:00 PM often leads to skipping a 25–30 minute workout entirely. 

Commercial apps handle this with rigid all-or-nothing designs. HOMESETS introduces **Adaptive Lite Mode (`⚡ وضع الإرهاق السريع`)**:
- A dedicated 1-tap alternative on the Today screen.
- Mathematically engineered to fit within a realistic **~12–15 minute window**.
- Delivers the minimal effective volume (MEV) to stimulate muscle maintenance and protein synthesis without draining energy before a 9-hour physical shift.

---

## 2. Mathematical Duration Models & Feasibility Proofs

A common flaw in fitness app design is underestimating execution time. Total workout duration is defined as:
$$\text{Total Duration} = T_{\text{warmup}} + \sum (T_{\text{set\_execution}} + T_{\text{rest}}) + T_{\text{transitions}}$$

### 2.1 Standard 25-Minute Routine vs. 15-Minute Lite Mode

| Workout Phase | Standard Routine (3 Exercises × 3 Sets) | Lite Mode Routine (2 Exercises: 1 Compound × 2 Sets + 1 Antagonist × 2 Sets) |
| :--- | :--- | :--- |
| **Warmup & Joint Lubrication** | 3.5 minutes (Shoulder dislocates, wrist circles, bodyweight hinges) | 2.5 minutes (Targeted joint mobility only) |
| **Total Working Sets** | 9 sets | 4 sets |
| **Set Execution Time** (Avg 40s per set) | $9 \times 40\text{s} = 6.0\text{ minutes}$ | $4 \times 40\text{s} = 2.67\text{ minutes}$ |
| **Rest Intervals** | 8 intervals $\times 90\text{s} = 12.0\text{ minutes}$ | 3 intervals $\times 90\text{s} = 4.5\text{ minutes}$ |
| **Transition & Log Time** | 2.5 minutes | 1.5 minutes |
| **Total Calculated Duration** | **24 minutes 00 seconds** (Fits 20–25m target) | **11 minutes 10 seconds** (Safely within 15m ceiling) |

### 2.2 Proof of Feasibility:
- **Result:** Lite Mode completes in **11 minutes 10 seconds** under standard 90s rest intervals.
- Even if the user extends one rest interval by 60s, total duration is **12m 10s**, leaving a 2.5-minute safety margin before the 15-minute ceiling.
- **Safety Guarantee:** Lite mode does NOT rush rest intervals (which would cause dangerous cardiovascular fatigue); it achieves its time cap strictly by **pruning accessory sets down to 4 high-yield working sets**.

---

## 3. Lite Mode Routine Synthesis Algorithm

When the user taps `⚡ تمرين سريع (15 دقيقة)`:
1. **Primary Compound Isolation:** The engine selects the single most important multi-joint compound movement in the scheduled routine (e.g., Pull-Up or Push-Up).
2. **Volume Reduction:** Sets for this compound lift are pruned from 3 sets to 2 high-intensity working sets.
3. **Antagonist Pairing:** A single accessory exercise is selected to balance the movement (e.g. Band Pull-Apart for posture, or Band Curls). Set count is capped at 2 sets.
4. **Preserved Consistency:** Logging a Lite Mode session increments the weekly consistency tracker identically to a standard session (`3/4 -> 4/4`).
