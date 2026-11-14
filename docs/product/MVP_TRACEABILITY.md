# HOMESETS — MVP Requirements Traceability Matrix (Draft Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G1 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)

---

## 1. Traceability Matrix

| Req ID | Requirement Description | Decision Ref | Master Ref | User Story | Milestone | Automated Verification Method |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-01** | Offline-first, zero-network Flutter Android APK | D01, D02 | §0, §5, §15 | US-15 | P0, P7 | Manifest inspection test verifying `android.permission.INTERNET` is absent; network stub test in test runner. |
| **REQ-02** | Guided onboarding with goal, stats, equipment, and injury avoidance | D04, D05, D09 | §5.1 | US-01 | P4 | Widget test verifying multi-step state capture, validation limits, and initial program generation. |
| **REQ-03** | Today screen with next session card and $\le 3$ tap workout start | D04, D10 | §5.2, §7 | US-02 | P4 | Widget interaction test asserting tap sequence from Today launch to Workout Player active $\le 3$ taps. |
| **REQ-04** | 15-Minute Lite mode for tired pre-shift days | D12 | §5.2, §11 | US-03 | P3, P4 | Unit test verifying plan engine volume reduction ($\sim 50\%$) and widget test launching Lite workout. |
| **REQ-05** | One-handed Workout Player with large thumb-zone controls | D08, D16 | §5.3, §8 | US-04 | P1, P4 | Widget test validating touch target bounds ($\ge 56\times 56$ dp) and wake-lock controller activation. |
| **REQ-06** | One-tap rep logging, automatic rest timer with audio/haptic alert | D08 | §5.3 | US-04 | P4 | Unit test for timer state machine; widget test for rep stepper increment/decrement and timer trigger. |
| **REQ-07** | Perceived effort feedback (Easy / Right / Hard) | D08, D17 | §5.3, §11 | US-05 | P3, P4 | Unit test verifying logged ratings influence subsequent progression rungs. |
| **REQ-08** | In-workout exercise swap and emergency pain stop | D04, D17 | §5.3, §11 | US-06 | P3, P4 | Unit test verifying pain contraindication filtering; widget test for swap modal and safe early stop. |
| **REQ-09** | Pure-Dart deterministic plan engine (double progression, recovery spacing) | D10, D17 | §4, §9, §11 | US-05, US-14 | P3 | 100+ exhaustive pure Dart unit tests verifying double progression, 24–48h spacing, absence re-entry, and equipment filtering. |
| **REQ-10** | Absence handling: 7+ days away triggers lighter re-entry session | D15 | §5.4, §11 | US-14 | P3 | Unit tests simulating timestamp deltas ($\Delta t = 8$ days, 15 days, 30 days) asserting volume deload percentage. |
| **REQ-11** | Private progress photos (front/side/back) stored in app sandbox | D13, D18 | §5.5, §9 | US-07 | P5 | Storage integration test verifying photo paths stay in `Context.getFilesDir()`, excluded from MediaStore. |
| **REQ-12** | Side-by-side progress photo comparison slider | D13 | §5.5, §7 | US-07 | P5 | Widget test for interactive split-screen image slider widget. |
| **REQ-13** | Weekly weight logging with 7-day rolling average chart | D06, D13 | §4, §5.5 | US-08 | P5 | Mathematical unit tests for rolling average calculation; widget test for chart rendering and slow-gain tip. |
| **REQ-14** | Strength progress charts for key benchmark exercises | D13 | §5.5 | US-09 | P5 | Unit tests calculating max reps/effective volume per movement; widget test for chart display. |
| **REQ-15** | Weekly consistency view (sessions completed vs target) | D11 | §5.5, §6 | US-09 | P5 | Unit test verifying consistency percentage across calendar weeks without daily streak counters. |
| **REQ-16** | Daily meal checklist (4–5 items) and cheap local protein list | D14 | §4, §5.6 | US-10 | P5 | Widget test for checklist state toggles, midnight reset logic, and protein information card display. |
| **REQ-17** | Optional daily local reminder (default 3:30 PM) | D15 | §5.8, §9 | US-11 | P6 | Unit test for notification scheduling payload; manual checklist for Honor/MagicOS power settings. |
| **REQ-18** | Single-file manual export/import backup with data & photo validation | D02, D18 | §5.7, §9 | US-13 | P6 | End-to-end integration test exporting DB + sample images to ZIP, importing into fresh DB, verifying bit-for-bit parity. |
| **REQ-19** | Mid-workout crash recovery / state restoration | D17 | §11, §12 | US-12 | P4 | State restoration test simulating app kill after set 2 and verifying recovery prompt on subsequent launch. |
| **REQ-20** | Bilingual design system with Egyptian Arabic RTL first | D15, D16 | §0, §8 | US-01 | P1 | Golden/widget tests in RTL locale asserting directional mirroring, Arabic typography, and alignment. |
| **REQ-21** | Dark-first Performance Lime aesthetic | D16, B02 | §8 | US-01 | P1 | Widget tests asserting color role mapping for dark and light themes, contrast ratios $\ge 4.5:1$. |
| **REQ-22** | Guarded CI pipeline and exact-head green check before code merge | GOV08 | §13 | All | G7, P0 | GitHub Actions workflow execution verifying clean format, analyze, test, and build before PR merge. |
| **REQ-23** | Single final integrated physical phone acceptance on Honor X9e Pro | GOV07, GOV10 | §16, §20 | All | Final Gate | Hands-on manual wireless APK installation and complete user journey validation by Ahmed. |

---

## 2. Scope Conflict Resolution: Friend Goal Mismatch

### Identified Discrepancy
- **Master Prompt §5 (MVP Specifications):** Defines Onboarding goal selection with: *"MVP: build muscle; others later"*.
- **Master Prompt §16 (Phase P8 Done criteria) & §22 (D03):** States: *"A friend installs and completes onboarding with a different goal/equipment"*.
- **Decision Register O07:** Flags this exact conflict as an open item.

### Policy Resolution in this Blueprint
1. **MVP Boundary (P0–P7):** The onboarding goal selection strictly supports **"بناء العضلات والقوة (Build Muscle & Strength)"**. No fat-loss, endurance, or sports-specific engines are implemented during MVP.
2. **P8 Friend Testing:** To validate friend onboarding in P8 without adding unapproved goal engines, the friend tests onboarding using **different equipment** (e.g., bodyweight-only or chair/floor without pull-up bar) and **different session lengths** (15 vs 30 min) under the core muscle-building engine.
3. **Post-MVP Goals:** Any additional goal engines (e.g., fat loss / cutting, endurance, general cardio) require explicit Product Owner approval and will be implemented post-MVP.

---

## 3. Physique & Health Data Safeguards

1. **No Clinical Diagnosis:** The app must never state or imply medical diagnoses (e.g., anorexia, obesity, malnutrition).
2. **No BMI Labeling:** Body Mass Index numbers and labels ("underweight", "normal", "overweight") are strictly forbidden.
3. **No Fabricated User Data:** Test fixtures and seed data must use synthetic mock names/identifiers; Ahmed's personal stats are stored only on his private device upon local input.
4. **Non-Shaming Encouragement:** Copy after missed workouts is strictly welcoming and neutral ("حمد الله على السلامة! جاهز نرجع نتمرن؟").
5. **Medical Advisory Gate:** Clear one-time onboarding disclaimer stating the app is a training tool and does not constitute medical advice.
