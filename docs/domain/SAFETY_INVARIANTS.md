# HOMESETS — Training Safety Invariants & Pain STOP Semantics

**Document Status:** [Active Safety Baseline — Qualified Medical & Kinesiological Review Flagged]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-R (Issue #10)  
**Authority Reference:** `docs/PROJECT_RULES.md`, `DECISION_REGISTER.md` (D04, D05, D09)  

---

## 1. Systemic Safety Invariants

The HOMESETS domain engine enforces systematic safety invariants that take absolute precedence over progression calculations, volume targets, and streak metrics:

```text
INVARIANT 1: Joint Safety Overrides Overload (Precedence Law)
    If (PainEvent.isAcuteJointPain) -> 
        TerminateActiveExercise();
        PreserveLoggedSets();
        FreezeProgressionForMuscleGroup();
        DisallowImmediateLoadedAlternative();
```

### 1.1 Resolution of Draft C1-V2 Defect (TRUTH-02)
Prior draft `docs/quality/C2_CI_PREFLIGHT.md` (ENG-05) suggested:
*"If user reports acute shoulder pain during overhead pressing, engine substitutes pain-free lateral raises on the spot."*

**This practice is rejected as clinically unsound.** An acute joint twinge during loaded resistance work indicates that the surrounding stabilizer tissues or tendons are acutely irritated. Introducing another loaded movement immediately after acute pain risks worsening tissue strain.

**HOMESETS Binding Policy:**
1. **Immediate Cessation:** When acute joint pain is reported, all provocative loaded exercise for that joint complex stops immediately.
2. **Zero Automatic Injury Prescription:** The app does not attempt to "treat", "rehabilitate", or "prescribe" substitute loaded exercises.
3. **Rest & Recovery Guidance:** The app displays conservative, supportive first-aid prompts (cool compress, rest, consult a qualified physician if pain persists).
4. **Future Cycle Exclusion:** The affected movement pattern is placed into the `avoided_areas` quarantine list for subsequent workouts until the user explicitly clears it.

---

## 2. Invariant Catalog & Counterexamples

| Invariant ID | Rule Statement | System Behavior | Prohibited Counterexample (What We Never Do) |
| :--- | :--- | :--- | :--- |
| **SAFE-01** | **Pain Stop Precedence** | Immediate session wrap-up upon joint pain tap. Completed sets preserved; workout marked "سلامة المفاصل ✓". | Never prompt: *"Push through 2 more reps to hit your target!"* or suggest loading an antagonist immediately. |
| **SAFE-02** | **No Equipment Locking** | If an exercise requires unowned hardware, it is excluded from all generation pipelines. | Never schedule pull-ups for a user who unchecks `hasPullUpBar`. |
| **SAFE-03** | **Absence Deload Protection** | After $\ge 14$ days absence, prescribed volume is conservatively reduced (by ~30–40%) to mitigate severe post-absence soreness and prevent acute overtraining, pending qualified review. | Never assign a high-volume "catch up" workout after a missed week. |
| **SAFE-04** | **1-Tap Pain Stop Accessibility** | The emergency pain-stop CTA is reachable within 1 tap from every active workout screen. | Never bury the pain-stop link behind nested menus or confirmation dialogues. |
| **SAFE-05** | **Zero Medical Claims** | The app is a training tracker, not a medical diagnostic tool. | Never classify user pain into clinical diagnoses (e.g. *"You have rotator cuff impingement"*). |

---

## 3. Unknowns & Qualified Review Flag

> [!WARNING]
> While these safety invariants represent conservative, evidence-based strength and conditioning guidelines, software algorithms cannot replace individualized clinical assessment by a licensed sports physician or physical therapist. 
> 
> A formal qualified review of these safety bounds and deload percentages is flagged for Product Owner review before final commercial or public release.
