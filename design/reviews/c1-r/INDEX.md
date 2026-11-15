# HOMESETS Campaign C1-R — Screenshot Evidence Index

**Date:** 2026-11-14
**Campaign:** C1-R Extended Autonomous Marathon
**Tracking Issue:** [GitHub Issue #6](https://github.com/abuhmaid28/homesets/issues/6)
**Pull Request:** [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5)
**Render Engine:** Google Chrome 131+ (`--headless=new`, zero third-party design tool dependencies)
**Reproducibility:** Pipeline executable via `python docs/reviews/check_contrast.py` and headless Chrome.

---

## 1. Overview & Verification Summary

All 24 screenshot assets have been rendered from the underlying responsive HTML source files directly into `design/reviews/c1-r/screenshots/` and mirrored in `design/screenshots/`.

Key improvements verified across this gallery:
1. **Device-First Rendering:** Outer wrapper banners, debug borders, and artificial padding have been completely removed. Every screenshot captures a pristine, edge-to-edge mobile app screen.
2. **Thumb-Zone Separation:** The Workout Player has been cleanly split into two distinct, dedicated states:
   - **Active Workout State:** Displays exercise cues, set counter, 52×52dp rep stepper, primary CTA, and pain-stop controls without any debug overlays or rest sheet collisions.
   - **Rest Timer State:** Displays a large circular countdown ring (`01:14`), exertion rating pills (RIR 1–2), next set preview, and `+30s` / `تخطي الراحة` controls.
3. **1.5× Dynamic Text Scale Support:** Tested and verified across compact (360×780) and wide (412×915) viewports. All text scales by 150% without clipping, button overlap, or horizontal scrollbar emergence.
4. **Neutral Brand Placeholder:** Replaced the hand-coded pull-up athlete vector in `today_exploration.html` with a clean, neutral wordmark badge `[ HOMESETS ]` explicitly marked `مسار مؤقت (Pending Original Asset)`.
5. **Synthetic Progress Fixtures:** Clearly labeled all sample weight and photo data with `بيانات افتراضية تجريبية (Synthetic Fixtures)`. Replaced bar mocks with a semantic 7-day rolling average SVG trendline.

---

## 2. Master Screenshot Catalog

| Filename | Screen & State | Viewport | Text Scale | File Size | Verified Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `today_wireframe_390x844.png` | Today Screen (Wireframe) | 390×844 | 1.0× (Base) | 75,212 B | 1-Tap clarity, weekly consistency ring (3/4), 25m routine, meal nudge. |
| `today_wireframe_360x780.png` | Today Screen (Wireframe) | 360×780 | 1.0× (Base) | 74,953 B | Compact mobile fit; zero horizontal overflow; full RTL navigation bar. |
| `today_wireframe_412x915.png` | Today Screen (Wireframe) | 412×915 | 1.0× (Base) | 77,870 B | Large Android (Honor/Pixel) baseline; cards expand gracefully. |
| `today_wireframe_360x780_scale150.png` | Today Screen (Wireframe) | 360×780 | 1.5× (Large) | 90,134 B | 1.5× text scale; exercise titles wrap cleanly; buttons remain $\ge 56\text{dp}$. |
| `today_wireframe_412x915_scale150.png` | Today Screen (Wireframe) | 412×915 | 1.5× (Large) | 108,785 B | Wide viewport with 1.5× text; zero truncation; accessible typography. |
| `today_exploration_390x844.png` | Today Screen (Exploration) | 390×844 | 1.0× (Base) | 89,888 B | Performance Lime glow; neutral wordmark placeholder; high-fidelity tokens. |
| `today_exploration_412x915.png` | Today Screen (Exploration) | 412×915 | 1.0× (Base) | 92,305 B | Wide exploration; rich contrast; balanced dark surface hierarchy. |
| `workout_player_wireframe_390x844.png` | Workout Player (Active) | 390×844 | 1.0× (Base) | 37,003 B | Active set; form cue; 52×52dp rep stepper; zero debug blue lines. |
| `workout_player_wireframe_360x780.png` | Workout Player (Active) | 360×780 | 1.0× (Base) | 36,408 B | Compact thumb zone; pain stop CTA visible in lower 40% dock. |
| `workout_player_wireframe_412x915.png` | Workout Player (Active) | 412×915 | 1.0× (Base) | 37,126 B | Wide viewport active set; generous spacing; uncrowded controls. |
| `workout_player_wireframe_360x780_scale150.png`| Workout Player (Active) | 360×780 | 1.5× (Large) | 51,886 B | 1.5× text scale; stepper numbers fit; pain stop button wraps cleanly. |
| `workout_rest_wireframe_390x844.png` | Rest Timer (Wireframe) | 390×844 | 1.0× (Base) | 32,816 B | Circular timer `01:14`; exertion pills; next set card; skip CTA. |
| `workout_rest_wireframe_360x780.png` | Rest Timer (Wireframe) | 360×780 | 1.0× (Base) | 32,421 B | Compact rest state; no overlap with background; clear primary actions. |
| `workout_rest_wireframe_412x915.png` | Rest Timer (Wireframe) | 412×915 | 1.0× (Base) | 33,161 B | Wide rest state; elegant circular track; accessible feedback pills. |
| `workout_rest_wireframe_360x780_scale150.png` | Rest Timer (Wireframe) | 360×780 | 1.5× (Large) | 48,080 B | 1.5× text scale; feedback pills expand vertically without truncation. |
| `workout_exploration_390x844.png` | Workout Player (Exploration)| 390×844 | 1.0× (Base) | 47,694 B | High-fidelity active player; Performance Lime accents; deep charcoal dock. |
| `workout_rest_exploration_390x844.png` | Rest Timer (Exploration) | 390×844 | 1.0× (Base) | 58,761 B | High-fidelity rest state; glowing timer ring; exertion pill selected state. |
| `onboarding_wireframe_390x844.png` | App Setup Flow (Wireframe) | 390×844 | 1.0× (Base) | 34,454 B | Baseline onboarding; blank inputs with placeholder hints; single goal locked. |
| `onboarding_wireframe_360x780.png` | App Setup Flow (Wireframe) | 360×780 | 1.0× (Base) | 34,036 B | Compact onboarding; local privacy notice; keyboard-friendly input cards. |
| `onboarding_wireframe_360x780_scale150.png` | App Setup Flow (Wireframe) | 360×780 | 1.5× (Large) | 51,165 B | 1.5× text scale; input labels remain legible; zero horizontal overflow. |
| `progress_hub_wireframe_390x844.png` | Progress Hub (Wireframe) | 390×844 | 1.0× (Base) | 40,328 B | Comparison slider; 7-day rolling avg trendline; synthetic demo badge. |
| `progress_hub_wireframe_360x780.png` | Progress Hub (Wireframe) | 360×780 | 1.0× (Base) | 38,750 B | Compact progress view; subtabs scroll smoothly; trend dots aligned. |
| `progress_hub_wireframe_360x780_scale150.png` | Progress Hub (Wireframe) | 360×780 | 1.5× (Large) | 43,554 B | 1.5× text scale; dates and weights wrap cleanly; zero card blowout. |
| `edge_states_wireframe_900x950.png` | Edge & Recovery States | 900×950 | 1.0× (Base) | 99,764 B | 4-card grid: crash recovery, pain stop precedence, 7+ day re-entry, empty state. |

---

## 3. Provenance & Reproduction

To reproduce these screenshots identically from any terminal with Google Chrome installed:
```bash
# 1. Verify contrast compliance
python docs/reviews/check_contrast.py

# 2. Render all 24 screenshot targets
python scratch/render_c1r_gallery.py
```
