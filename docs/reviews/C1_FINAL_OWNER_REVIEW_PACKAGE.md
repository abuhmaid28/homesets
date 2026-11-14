# HOMESETS — Campaign C1-R Final Product Owner Review Package

**Date:** 2026-11-14
**Author:** Antigravity (Gemini 3.8 Flash High)
**Status:** [PROPOSAL FOR ONE CONSOLIDATED PRODUCT OWNER DECISION]
**Target Pull Request:** [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5)
**Feature Branch:** `campaign/c1-design-foundation`
**Tracking Issues:** [Issue #4 (C1 Blueprint)](https://github.com/abuhmaid28/homesets/issues/4), [Issue #6 (C1-R Marathon)](https://github.com/abuhmaid28/homesets/issues/6)
**Authority Reference:** `docs/DECISION_REGISTER.md` (D01–D20, GOV06–GOV11), `docs/MASTER_EXECUTION_PLAN.md`

---

## 1. Executive Summary & Problem-Solution Fit

HOMESETS is an offline-first, single-user mobile workout companion engineered specifically for Ahmed’s lifestyle and constraints:
- **Daily Context:** Working night shifts (7:00 PM to 4:00 AM) in Cairo; workouts take place in a focused 15–30 minute window before work.
- **Home Equipment:** Wall-mounted pull-up bar, resistance loop bands, and assistance super-bands.
- **Core User Friction Solved:** Zero decision fatigue before night shifts. Launching the app delivers **1-Tap Clarity**: the exact workout for today is immediately shown, auto-rotated, and started with a single tap.
- **Privacy & Ownership:** Zero cloud servers, zero account sign-ups, zero analytics trackers, and zero recurring fees. All data, workout logs, and private physique progress photos stay strictly within the app's local sandbox on the physical phone.

This package consolidates the entire C1 Product Blueprint, Design System, UX Information Architecture, and C1-R visual quality marathon into **one grouped decision package** for Product Owner review.

---

## 2. Decision Classification: Approved vs Preferred vs Proposed

| Category | Decision Item | Status | Technical Reality & Scope Boundary |
| :--- | :--- | :--- | :--- |
| **Foundational** | Single-user, offline-first Android app | **[Confirmed]** | Zero backend servers; zero user accounts; SQLite/Drift local engine. |
| **Scope Boundary**| Single Goal: Muscle Building & Strength | **[Confirmed]** | Scope locked strictly to "بناء العضلات والقوة". Friend goals deferred to post-MVP. |
| **Brand Identity**| "HOMESETS" Working Title | **[Preferred]** | Capitalized modern wordmark. Preserved across all designs. |
| **Brand Identity**| "Pull-Up Motion" Logo Direction | **[Preferred]** | Original PNG reference tracked in Issue #1 (`ASSET_SOURCE_UNAVAILABLE`). No substitute vector fabricated; neutral typography placeholder `[ HOMESETS ]` used in prototypes. |
| **Design System** | Performance Lime on Deep Charcoal | **[Preferred]** | `#CCFF00` on `#121316` / `#1C1E24`. 15.81:1 contrast ratio (AAA). |
| **Safety Protocol**| Assistance vs Resistance Band Physics | **[Proposed]** | Pull-up bands assist body weight (thicker = easier). Rows/push-up bands add load (thicker = harder). Universal color ladders prohibited. |
| **Safety Protocol**| Acute Joint Pain Stop Precedence | **[Proposed]** | Joint pain triggers immediate stop and rest recommendation. Exercise swapping is deferred until pain fully subsides. |
| **Privacy/Backup** | Android 12+/16 Cloud Backup Exclusion | **[Proposed]** | `data_extraction_rules.xml` completely excludes private photos and SQLite DB from automatic Google Drive cloud backup. |
| **Privacy/Backup** | Two-Phase Staged Restore Pipeline | **[Proposed]** | Pre-restore snapshot rollback (`cache/pre_restore_snapshot/`) guarantees atomicity across filesystem images and database. |

---

## 3. Visual Prototype Gallery & Screenshot Catalog

All 24 screenshot assets were rendered directly from the responsive HTML source using headless Google Chrome. They are organized in `design/reviews/c1-r/screenshots/` and indexed in [`design/reviews/c1-r/INDEX.md`](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/INDEX.md).

### Visual Refinements Applied in C1-R:
1. **Device-First Rendering:** Outer wrapper banners, desktop mock phone frames, and artificial desktop margins were removed. Screenshots are 100% clean, edge-to-edge mobile screens.
2. **Thumb-Zone Separation:** Separated the crowded workout player into two distinct screens:
   - **Active Workout State:** Focuses purely on set progress, 52×52dp rep stepper, primary CTA, and pain-stop control.
   - **Rest Timer State:** Displays a large circular countdown ring (`01:14`), exertion feedback pills, next set preview card, and skip/add-time controls.
3. **1.5× Dynamic Text Scale:** Verified across compact (360×780) and wide (412×915) viewports. Arabic typography scales up cleanly without clipping or button truncation.
4. **Neutral Wordmark Placeholder:** Replaced the artificial athlete silhouette in `today_exploration.html` with a neutral `[ HOMESETS ]` typography badge pending original asset conversion.
5. **Synthetic Progress Fixtures:** Clearly labeled all sample weight and photo data with `بيانات افتراضية تجريبية (Synthetic Fixtures)`. Replaced bar mocks with a semantic 7-day rolling average SVG trendline.

### Master Screenshot Links:
- **Today Screen (Wireframe):**
  - [today_wireframe_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/today_wireframe_390x844.png) (Baseline iPhone 14)
  - [today_wireframe_360x780.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/today_wireframe_360x780.png) (Compact Android)
  - [today_wireframe_412x915.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/today_wireframe_412x915.png) (Pixel 7 / Honor Baseline)
  - [today_wireframe_360x780_scale150.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/today_wireframe_360x780_scale150.png) (1.5× Large Text on 360px)
  - [today_wireframe_412x915_scale150.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/today_wireframe_412x915_scale150.png) (1.5× Large Text on 412px)
- **Today Screen (Exploration - Performance Lime):**
  - [today_exploration_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/today_exploration_390x844.png) (Baseline)
  - [today_exploration_412x915.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/today_exploration_412x915.png) (Wide)
- **Workout Player (Active Set):**
  - [workout_player_wireframe_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_player_wireframe_390x844.png) (Baseline)
  - [workout_player_wireframe_360x780.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_player_wireframe_360x780.png) (Compact)
  - [workout_player_wireframe_412x915.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_player_wireframe_412x915.png) (Wide)
  - [workout_player_wireframe_360x780_scale150.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_player_wireframe_360x780_scale150.png) (1.5× Large Text)
  - [workout_exploration_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_exploration_390x844.png) (High-Fidelity Lime Active Player)
- **Workout Player (Rest Timer State):**
  - [workout_rest_wireframe_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_rest_wireframe_390x844.png) (Baseline)
  - [workout_rest_wireframe_360x780.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_rest_wireframe_360x780.png) (Compact)
  - [workout_rest_wireframe_412x915.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_rest_wireframe_412x915.png) (Wide)
  - [workout_rest_wireframe_360x780_scale150.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_rest_wireframe_360x780_scale150.png) (1.5× Large Text)
  - [workout_rest_exploration_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/workout_rest_exploration_390x844.png) (High-Fidelity Lime Rest Countdown)
- **App Setup & Onboarding:**
  - [onboarding_wireframe_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/onboarding_wireframe_390x844.png) (Baseline)
  - [onboarding_wireframe_360x780.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/onboarding_wireframe_360x780.png) (Compact)
  - [onboarding_wireframe_360x780_scale150.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/onboarding_wireframe_360x780_scale150.png) (1.5× Large Text)
- **Progress Hub & Rolling Average:**
  - [progress_hub_wireframe_390x844.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/progress_hub_wireframe_390x844.png) (Baseline)
  - [progress_hub_wireframe_360x780.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/progress_hub_wireframe_360x780.png) (Compact)
  - [progress_hub_wireframe_360x780_scale150.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/progress_hub_wireframe_360x780_scale150.png) (1.5× Large Text)
- **Edge States & Failure Recovery:**
  - [edge_states_wireframe_900x950.png](file:///C:/Users/TopOne%20MM/Documents/homesets/design/reviews/c1-r/screenshots/edge_states_wireframe_900x950.png) (Crash Recovery, Pain Stop Precedence, 7+ Day Absence, Empty State)

---

## 4. Reproducible Mathematical Color Contrast Audit

Audit script committed to repository: [`docs/reviews/check_contrast.py`](file:///C:/Users/TopOne%20MM/Documents/homesets/docs/reviews/check_contrast.py).
Command: `python docs/reviews/check_contrast.py` (Standard Python 3, zero dependencies).

| Token Pair | Foreground | Background | Measured Ratio | WCAG Requirement | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Primary Text (Pure White) | `#FFFFFF` | `#121316` | **18.58:1** | $\ge 4.5:1$ (Normal) | **PASS AAA** |
| Primary Body (Off-White) | `#F8FAFC` | `#121316` | **17.75:1** | $\ge 4.5:1$ (Normal) | **PASS AAA** |
| Secondary Text (Zinc-400) | `#A1A1AA` | `#121316` | **7.25:1** | $\ge 4.5:1$ (Normal) | **PASS AAA** |
| Accessible Caption Slate | `#9CA3AF` | `#121316` | **7.32:1** | $\ge 4.5:1$ (Normal) | **PASS AAA** |
| Accessible Tertiary Zinc | `#8E8E93` | `#121316` | **5.70:1** | $\ge 4.5:1$ (Normal) | **PASS AA** |
| Accessible Tertiary on Card | `#8E8E93` | `#1C1E24` | **5.11:1** | $\ge 4.5:1$ (Normal) | **PASS AA** |
| Performance Lime CTA | `#CCFF00` | `#121316` | **15.81:1** | $\ge 3.0:1$ (Large) | **PASS AAA** |
| Charcoal Button Text | `#0F1012` | `#CCFF00` | **16.20:1** | $\ge 4.5:1$ (Normal) | **PASS AAA** |
| Danger Red Outline/Text | `#EF4444` | `#121316` | **4.94:1** | $\ge 4.5:1$ (Normal) | **PASS AA** |
| Danger Red Filled Button | `#FFFFFF` | `#DC2626` | **4.83:1** | $\ge 4.5:1$ (Normal) | **PASS AA** |
| Inactive / Disabled Border | `#71717A` | `#121316` | **3.84:1** | $\ge 3.0:1$ (Non-Text) | **PASS Non-Text** |

*(Note: `#71717A` is strictly restricted to non-text disabled outlines; normal text uses `#8E8E93` or `#A1A1AA`).*

---

## 5. The Four Product Owner Gate Decisions

To unlock development and transition smoothly into the next phase, Ahmed must make **four grouped decisions**:

### Decision 1: Visual & Brand Direction
- [ ] **Approve Option A (Performance Lime - Recommended):** Confirm `#CCFF00` accent on `#121316` dark charcoal theme, 4dp grid, and typography scale as the visual baseline for HOMESETS.
- [ ] **Request Adjustments:** Specify color saturation or typography alterations before Flutter scaffolding.

### Decision 2: Safety & Progression Logic
- [ ] **Approve Training Logic (Recommended):** Confirm equipment-specific band physics (assistance bands decrease pull-up difficulty; resistance bands increase row/push difficulty) and Acute Joint Pain Stop precedence.
- [ ] **Request Adjustments:** Specify custom exercise rules or progression pacing.

### Decision 3: Local Backup & Privacy Architecture
- [ ] **Approve Privacy Architecture (Recommended):** Confirm `android:dataExtractionRules` excluding private photos and SQLite DB from Google Drive cloud backup, manual-only ZIP export with pre-restore snapshot rollback, and SHA-256 corruption verification.
- [ ] **Request Adjustments:** Modify data retention or export policies.

### Decision 4: Next Campaign Authorization
- [ ] **Authorize Campaign C2 (Architecture & CI Setup):** Authorize creation of the pure-Dart domain model, deterministic workout engine scenario test suite, and GitHub Actions CI workflow on `campaign/c2-architecture-ci`.
- [ ] **Hold:** Keep in review.

---

## 6. Remaining Blockers & Next Actions

1. **Logo Reference Asset (Issue #1):**
   - Status remains `ASSET_SOURCE_UNAVAILABLE`.
   - The exact 2,018,426-byte reference file (`Neon-Lime Pull-Up Fitness Logo(1).png`, SHA-256 `95822f54...`) is pending placement into `assets/brand/reference/homesets-pullup-preferred.png`.
   - Once placed, Gate G2 vectorization can proceed. No lookalike substitute will be promoted.
2. **Draft PR #5 Status:**
   - [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5) is complete, fully verified, and remains in **DRAFT** pending your grouped decision above.
   - Upon approval, PR #5 can be marked ready and merged.
