# HOMESETS — Adaptive Lite Mode & Time-Feasibility Specification

**Document Status:** [Active Domain Specification — Hardened]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-R (Issue #10)  
**Authority Reference:** `DECISION_REGISTER.md` (D08, D12, D15), `docs/PROJECT_RULES.md`  

---

## 1. The Real-World Problem: Tired Days Before Shift Work

Ahmed works an exhausting night shift (7 PM – 4 AM) preceded by a 3-hour round-trip commute (D07). Waking up tired at 3:00 PM often leads to skipping a 25–30 minute workout entirely. 

Commercial apps handle this with rigid all-or-nothing designs. HOMESETS introduces **Adaptive Lite Mode (`⚡ وضع الإرهاق السريع`)**:
- A dedicated 1-tap alternative on the Today screen.
- Empirically structured to target a realistic **~12–15 minute window**.
- Delivers the minimal effective volume (MEV) to stimulate muscle maintenance and motor retention without depleting physical energy prior to a 9-hour physical work shift.

---

## 2. Empirical Duration Breakdown & Time-Feasibility Modeling

A frequent failure mode in fitness software is unrealistic duration estimation. Total workout duration is modeled as:
$$\text{Estimated Duration} = T_{\text{warmup}} + \sum (T_{\text{set\_execution}} + T_{\text{rest}}) + T_{\text{transitions}}$$

### 2.1 Standard 25-Minute Routine vs. 15-Minute Lite Mode Baseline

| Workout Phase | Standard Routine (3 Exercises × 3 Sets) | Lite Mode Routine (2 Exercises: 1 Compound × 2 Sets + 1 Antagonist × 2 Sets) |
| :--- | :--- | :--- |
| **Warmup & Joint Lubrication** | ~3.5 minutes (Targeted mobility, arm swings, bodyweight hinges) | ~2.5 minutes (Direct joint preparation for active patterns) |
| **Total Working Sets** | 9 working sets | 4 working sets |
| **Set Execution Time** (Avg 40s per set) | $9 \times 40\text{s} = 6.0\text{ minutes}$ | $4 \times 40\text{s} = 2.67\text{ minutes}$ |
| **Rest Intervals** | 8 intervals $\times 90\text{s} = 12.0\text{ minutes}$ | 3 intervals $\times 90\text{s} = 4.5\text{ minutes}$ |
| **Transition & Log Time** | ~2.5 minutes | ~1.5 minutes |
| **Total Estimated Duration** | **~24 minutes** (Fits 20–25m target) | **~11 minutes 10 seconds** (Comfortably within 15m ceiling) |

### 2.2 Feasibility Analysis & Real-World Variances
- **Baseline Target:** Lite Mode targets completion in approximately **11 to 12 minutes** assuming standard 90-second rest intervals between sets.
- **Buffer Margin:** Even if a fatigued trainee extends each rest interval by 30 seconds (adding +90 seconds total), estimated execution time reaches ~12 minutes 40 seconds, maintaining a healthy buffer beneath the 15-minute upper threshold.
- **Core Design Invariant:** Lite mode explicitly avoids rushing rest intervals or forcing rapid supersets (which could induce cardiovascular distress or degraded form). Instead, it respects physiological recovery intervals and achieves its duration budget strictly by **pruning non-essential accessory volume down to 4 focused working sets**.
- **Real-World Variance Note:** Pacing varies with user mobility and equipment access. The app displays time as an estimate rather than a rigid deadline.

---

## 3. Lite Mode Routine Synthesis Algorithm

When the user taps `⚡ تمرين سريع (15 دقيقة)`:
1. **Primary Compound Prioritization:** The engine isolates the single primary multi-joint compound movement in the scheduled routine (e.g., Pull-Up or Push-Up).
2. **Volume Pruning:** Working sets for this compound movement are reduced from 3 sets to 2 quality working sets.
3. **Antagonist / Accessory Selection:** A single balancing accessory exercise is selected (e.g. Band Row or Band Curls), capped strictly at 2 sets.
4. **Preserved Consistency Credit:** Logging a completed Lite Mode session increments the weekly consistency tracker identically to a standard session (`3/4 -> 4/4`), reinforcing habit formation on high-stress days without guilt or streak penalties (D12, D15).
