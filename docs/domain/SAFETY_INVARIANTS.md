# HOMESETS — Training Safety Invariants & Pain STOP Semantics

**Document Status:** [Active Safety Baseline — Qualified Review Required]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `docs/PROJECT_RULES.md`, `DECISION_REGISTER.md` (D04, D05, D09)  

---

## 1. Absolute Safety Invariants

The HOMESETS domain engine enforces mathematical safety invariants that override all progression calculations, volume goals, and streak metrics:

```text
INVARIANT 1: Joint Safety Overrides Overload (Precedence Law)
    If (PainEvent.isAcuteJointPain) -> 
        TerminateActiveExercise();
        PreserveLoggedSets();
        FreezeProgressionForMuscleGroup();
        DisallowImmediateLoadedAlternative();
```

### 1.1 Resolution of Draft C1-V2 Defect (TRUTH-02)
Prior draft `docs/quality/C2_CI_PREFLIGHT.md` (ENG-05) incorrectly suggested:
*"If user reports acute shoulder pain during overhead pressing, engine substitutes pain-free lateral raises on the spot."*
**This is dangerous and clinically unsound.** An acute joint twinge during loaded work means the surrounding stabilizer tissues are irritated or compromised. Introducing another loaded movement immediately after acute pain exacerbates inflammation.

**HOMESETS Binding Policy:**
1. **Immediate Cessation:** When acute joint pain is reported, all provocative loaded exercise for that joint complex stops immediately.
2. **No Automatic Injury Prescription:** The app does not attempt to "treat" or "prescribe" substitute loaded exercises.
3. **Rest & Recovery Guidance:** The app displays conservative, supportive first-aid advice (cool compress, rest, consult a qualified physician if pain persists).
4. **Future Cycle Exclusion:** The affected movement is placed into the `avoided_areas` quarantine list for subsequent workouts until the user explicitly unblocks it.

---

## 2. Invariant Catalog & Counterexamples

| Invariant ID | Rule Statement | System Behavior | Prohibited Counterexample (What We Never Do) |
| :--- | :--- | :--- | :--- |
| **SAFE-01** | **Pain Stop Precedence** | Immediate session wrap-up upon joint pain tap. Completed sets preserved; workout marked "سلامة المفاصل ✓". | Never prompt: *"Push through 2 more reps to hit your target!"* or suggest loading an antagonist immediately. |
| **SAFE-02** | **No Equipment Locking** | If an exercise requires unowned hardware, it is filtered out of all generation pipelines. | Never schedule pull-ups for a user who unchecks `hasPullUpBar`. |
| **SAFE-03** | **Absence Deload Protection** | After $\ge 14$ days absence, volume is cut by 35–50% to prevent rhabdomyolysis and severe delayed onset soreness. | Never assign a high-volume "catch up" workout after a missed week. |
| **SAFE-04** | **1-Tap Pain Stop Accessibility** | The emergency pain-stop CTA is reachable within 1 tap from every active workout screen. | Never bury the pain-stop link behind nested menus or confirmation dialogues. |
| **SAFE-05** | **Zero Medical Claims** | The app is a training tracker, not a medical diagnostic tool. | Never classify user pain into clinical diagnoses (e.g. *"You have rotator cuff impingement"*). |

---

## 3. Unknowns & Qualified Review Flag

> [!WARNING]
> While these safety invariants represent conservative, evidence-based strength and conditioning standards, software algorithms cannot replace individualized clinical assessment by a licensed sports physician or physical therapist. 
> 
> A formal qualified review of these safety bounds is flagged for Product Owner review before final commercial or public release.
