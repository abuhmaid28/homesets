# C1-R — Independent visual QA after autonomous marathon

**Date:** 2026-11-14
**Source:** Exact GitHub Draft PR #5 head `78282819f781a1dd66204aeec2ea6ade812882d1` (8 commits; 73 PR changed paths) and original PNG assets read from `design/reviews/c1-r/screenshots`.
**Author:** ChatGPT independent reviewer.
**Outcome:** **Technical deliverables exist, but Product Owner visual gate NOT ready / NOT accepted.** Do not merge or start Flutter UI implementation based on these designs yet.

## What GitHub verified
- Draft PR #5 remains open and unmerged.
- `docs/reviews/C1_FINAL_OWNER_REVIEW_PACKAGE.md`, `docs/campaigns/C1-R_CHECKPOINT.md`, `design/reviews/c1-r/INDEX.md` exist.
- Image assets from Today, Workout, Rest and Progress were fetched **as PNG bytes** and inspected as actual rendered images.
- A gallery of 24 images is present in the PR paths. This is evidence of PNG file existence and visual content, **not** sufficient proof of every claimed automated screenshot condition or Honor behavior.
- No Flutter runtime implementation or CI exists in C1.

## Product/UI critique grounded in actual PNGs
1. **P0 — Progress header breaks visually in AR/RTL**. Screenshot `progress_hub_wireframe_390x844.png`: header reads `سجل التقدم (Progress) (Hub` on two misordered lines, visibly truncated/awkward. This is a failure of bilingual copy and heading semantics, regardless of claimed zero horizontal overflow.
2. **P0 — Workout and rest bilingual labels**. Workout displays a duplicate large English `(Wide Grip Pull-ups)` line; Rest preview wraps English exercise name into awkward fragments `(Wide Grip Pull) ... (ups)`. Remove English duplicates from primary Arabic screen, use short optional subtitles with explicit `dir=ltr` spans and constrained width.
3. **P1 — Too much dead space in active workout**. Workout `390×844` has a very large empty mid-screen gap separating set chips and bottom controls; optimize visual exercise guidance or hierarchy without compromising thumb-zone reach and without adding unsafe exercise demonstrations.
4. **P1 — Rest screen small/pill crowding**. Current exertion control and next-set preview are cramped, mixed technical terms `RIR` in user-facing Arabic and overly long exercise title. Clarify one-hand priorities and visible timer status.
5. **P1 — Today hierarchy/density**. Hero includes a long bilingual session heading, tiny exercise rows and several competing status chips. Maintain one-tap start and 15m Lite but shorten labels, group data, and avoid glowing CTA overshadowing safety state.
6. **P1 — Style coherence and accessibility**. Screens have inconsistently treated English parentheses, synthetic status bar, small caption sizes and raw mixed numeral formats. A declaration of 1.5× support in a PNG index is not proof without inspecting the actual large-text screenshot and testing scroll-to-action visibility.
7. **P1 — No real full interaction coverage**. HTML previews are static; zero state transitions tested. Design for focus, semantics, loading, enabled/disabled states and route transitions; if implemented as a throwaway offline interactive prototype, explicitly label it *prototype*, not the Flutter app.
8. **P2 — Preferred image still missing**. Brand exact PNG not committed and placeholder cannot be approved as the final symbol. Maintain preferred wordmark without inventing a substitute.

## Required final Product Owner review
- Two polished, purposeful **visual alternatives within preferred HOMESETS charcoal×lime direction**, not dozens of random themes, across same real user journey for side-by-side comparison.
- Device-first *clean* RTL Arabic screen captures for Today, workout active, rest, onboarding, progress, settings/backup and essential edge states, plus English and light-theme regression.
- Practical 360×780 and 412×915 small/large size, 1.5× text scale, 48/56dp targets, and behavior under long text and missing equipment.
- A reproducible accessibility report with honest coverage and screenshot/text overflow findings; don't equate no horizontal scrollbar with no truncation.
- Keep strict pain-stop, bands physics, privacy and anti-shaming policies; never claim safety tests passed solely from prose.
- Return a compact side-by-side **one-decision visual PO package**; do not ask owner to click 24 separate mockup links.

## Major gates
- The current visual direction is **Preferred, not owner approved**. C2 architecture preparation can be performed as Draft/Design-Only work while C1 is refined; no Flutter UI implementation, package installation, new dependency or code merge until proper approval and real exact-head CI.
- No hourly runtime guarantee. Deliver actual work rather than artificially long execution or repeated loops.
