# HOMESETS — C1-V2 Baseline & Visual Defect Matrix

**Document Status:** [Final Baseline]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-14  
**Target Pull Request:** [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5)  
**Reference Head:** `78282819f781a1dd66204aeec2ea6ade812882d1`  
**Authority Reference:** `docs/reviews/C1_POST_MARATHON_VISUAL_QA.md`, GitHub Issue #7  

---

## 1. Executive Summary

This matrix audits the specific UI, BiDi, layout, and architectural shortcomings identified during the independent visual inspection of the C1-R screenshot gallery at commit `7828281`. 

Every finding is assigned an explicit tracking ID, severity, root cause, required remediation, and verifiable pass criteria for the C1-V2 campaign.

---

## 2. Detailed Defect Inventory

| Defect ID | Category | Severity | Observed Defect & Root Cause | Target Technical Resolution | Pass Verification Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **V2-D01** | BiDi / Arabic Layout | **P0 (Critical)** | **Progress Hub Header Misordering:** `سجل التقدم (Progress) (Hub` wraps across two lines with broken parenthesis reordering due to unconstrained English text in an RTL header. | Isolate English titles into `<span dir="ltr">` or use natural pure-Arabic header `سجل التقدم` with subtle secondary subtitle. | Clean single-line or naturally wrapped Arabic title with zero misordered punctuation across all viewports. |
| **V2-D02** | Typography & Bilingual Copy | **P0 (Critical)** | **Workout & Rest Fragmented English:** `عقلة قبضة واسعة` accompanied by duplicate English line `(Wide Grip Pull-ups)`; on Rest screen it wraps into `(Wide Grip Pull) ... (ups)`. | Remove intrusive English duplicates from primary screen; provide clean, localized Arabic exercise names with optional small LTR meta tag. | Zero broken English words or fragmented multi-line parentheses across all exercise names. |
| **V2-D03** | Workout Layout & Density | **P1 (High)** | **Active Workout Mid-Screen Dead Space:** In 390×844 and 412×915, a large empty gap exists between set chips and the bottom thumb-zone dock. | Introduce muscular activation cue card (`عضلة الظهر العريضة • البايسبس`) and set-by-set history table without expanding height beyond thumb reach. | Balanced vertical hierarchy without artificial dead space; thumb-zone controls remain in lower 40%. |
| **V2-D04** | Rest Timer Screen Ergonomics | **P1 (High)** | **Rest Pill Crowding & Technical Jargon:** Exertion pills contain cryptic technical acronyms `(RIR 1-2)` confusing for Egyptian Arabic users; next-set preview is crowded. | Replace with natural Egyptian Arabic: `فاضل طاقة (سهل)`, `مظبوط ومثالي 👍`, `على الآخر (صعب)`. Give timer and buttons breathing room. | Clean 48dp+ feedback buttons with intuitive Arabic copy; spacious countdown timer display. |
| **V2-D05** | Today Screen Information Hierarchy | **P1 (High)** | **Today Card Density:** Competing status chips, long bilingual routine title, and high-intensity lime glow overshadowing workout info. | Streamline header to `سحب وضهر وبايسبس`; group duration, equipment, and sets into a clean horizontal chip row; soften glow. | 1-Tap start remains instantly prominent; metadata is scannable at a glance. |
| **V2-D06** | Screenshot Tooling Reproducibility | **P1 (High)** | **Missing Script in Repository (404):** `scratch/render_c1r_gallery.py` was located in uncommitted scratch storage, preventing independent reproduction from GitHub. | Commit `design/reviews/c1-v2/render_gallery.py` directly to the repository; document execution and timeouts. | `python design/reviews/c1-v2/render_gallery.py` runs and verifies all screenshots deterministically. |
| **V2-D07** | Prototype Interactivity | **P1 (High)** | **Zero Interaction Testing:** Static HTML previews do not allow evaluation of transitions, set logging, countdown ticking, or pain-stop flows. | Construct `design/preview/prototype.html`: an offline interactive vanilla JS prototype simulating the complete workout lifecycle. | Fully testable in browser: Start -> Log Set -> Live Rest Countdown -> Next Set -> Pain Stop -> Summary. |
| **V2-D08** | Visual A/B Options | **P1 (High)** | **Single Visual Exploration:** PO cannot evaluate visual trade-offs without two coherent, grounded design directions. | Create **Direction A (Performance Stealth)** and **Direction B (Kinetic Depth)** within preferred charcoal + lime palette. | Side-by-side comparison available for all key screens. |
| **V2-D09** | Accessibility & Scaling Proof | **P1 (Medium)** | **Unverified 1.5× Text Scroll-to-Action:** 1.5× text scale claims lacked full-screen scroll-to-action proof. | Capture full-screen scrolled captures of 1.5× text scale on 360px and 412px viewports. | Every primary button and input is confirmed reachable under 1.5× text scale. |
| **V2-D10** | Logo Asset Transparency | **P2 (Low)** | **Missing Original Logo PNG:** Original binary remains `ASSET_SOURCE_UNAVAILABLE`. | Maintain neutral wordmark `[ HOMESETS ]` with explicit `Pending Original Asset` tag; do not fabricate a substitute. | Transparent status maintained in asset manifest. |

---

## 3. Campaign Execution Roadmap

- **Phase 1 (WP01–WP04):** Core layout, BiDi, bilingual, and typography defect resolution.
- **Phase 2 (WP05–WP07):** Offline interactive prototype and reproducible multi-viewport screenshot pipeline.
- **Phase 3 (WP08–WP10):** Architecture preflight, adversarial QA, and A/B visual diff.
- **Phase 4 (WP11–WP12):** Product Owner review consolidation, PR update, and final delivery.
