# HOMESETS — Decision Register

Last updated: 2026-11-15
Status: **Living register — owner review required for newly proposed items**

## Authority and change control
1. Read this file together with [the verbatim Master Project Initialization Prompt](MASTER_PROJECT_INITIALIZATION_PROMPT.txt).
2. A newer **[Confirmed]** owner decision may supersede an older one only if explicitly recorded with its reason and date.
3. **[Recommended]** and **[Open]** are never authorizations to implement.
4. When the two sources appear to conflict, stop and ask Ahmed rather than guessing.
5. Keep rejected alternatives and outstanding questions visible.

## Original product decisions — preserved without changing their original statuses

| ID | Decision or fact | Status |
| --- | --- | --- |
| D01 | Private Flutter application, Android-only, personally installed APK; no Play Store | Confirmed |
| D02 | Offline-first, local data, no backend/accounts/cloud, zero recurring cost | Confirmed |
| D03 | Ahmed first; friends later using separate local installs and differing equipment/needs | Confirmed |
| D04 | App selects training plan from user goal, equipment, time, and avoided areas | Confirmed |
| D05 | Baseline in original brief: age 26, 190 cm, 60 kg, about 10 pull-ups and 10 push-ups, no reported injuries | Confirmed in original brief; re-check if changed |
| D06 | Goal 80 kg, build muscle and defined physique; pace 0.25–0.5 kg/week is advisory | Confirmed goal; Recommended pace |
| D07 | Shift 7 pm–4 am, about 3 hours commute; days off Saturday/Sunday; wakes around 3 pm, leaves around 5 pm | Confirmed |
| D08 | Workouts 15–30 minutes, usually before work and same duration on days off | Confirmed |
| D09 | Pull-up bar and resistance bands; no dumbbells, no backpack loading | Confirmed |
| D10 | No fixed weekdays; session rotation with recovery spacing | Recommended (adopted) |
| D11 | Weekly consistency rather than daily streaks | Recommended (adopted) |
| D12 | 15-minute Lite option for tiring days | Recommended (adopted) |
| D13 | Progress photos first, weekly weight average and automatic strength charts; no body measurements | Confirmed |
| D14 | Simple meal checklist; no calorie counting | Recommended (adopted) |
| D15 | No scolding, light re-entry after week away, optional 3:30 pm reminder, supportive Egyptian Arabic | Confirmed |
| D16 | Dark-first, full design system, Arabic RTL first, bilingual | Confirmed |
| D17 | Deterministic rule-based plan engine; no AI model inside app | Recommended (adopted) |
| D18 | One profile per installation, manual export/import, private photo storage | Recommended (adopted) |
| D19 | Antigravity writes app code; ChatGPT plans and independently reviews | Confirmed |
| D20 | Tiny milestones, Git and tests: originally Confirmed. The **per-milestone human device gate only** is explicitly superseded by GOV07 on 2026-11-14; small internally verified milestones, evidence, and Git remain mandatory. | Confirmed original; partial supersession GOV07 |

## Later facts and decisions

| ID | Date | Statement | Status |
| --- | --- | --- | --- |
| E01 | 2026-11-14 | Honor X9e Pro runs MagicOS 10 based on Android 16 (owner-reported). | Confirmed (reported by owner) |
| E02 | 2026-11-14 | On Windows 10, Flutter 3.47.0, Dart 3.13.0, Android SDK 36.0.0; `flutter doctor` showed `No issues found!`. | Confirmed by terminal screenshot |
| E03 | 2026-11-14 | Owner does not want phone connected to PC by USB. APK installation/testing will be wireless; no emulator needed. | Confirmed |
| E04 | 2026-11-14 | Antigravity model picker visibly shows `Gemini 3.8 Flash High`; this verifies the displayed name only, not any external model catalog claim. | Confirmed by owner screenshot |
| E05 | 2026-11-14 | Antigravity displays a separate project/workspace named `homesets` and selected local checkout in its UI. Its Git remote and local folder contents are not yet verified. | Confirmed UI / Open Git connection |
| G01 | 2026-11-14 | Private GitHub repository `abuhmaid28/homesets`, default branch `main`. | Confirmed via GitHub |
| G02 | 2026-11-14 | The original P0-05 Antigravity bootstrap prompt was canceled before being used. Documentation, branding, UX and technical planning precede implementation. | Confirmed |
| B01 | 2026-11-14 | `HOMESETS` is the current **preferred candidate** app name; repository slug is `homesets`. | Preferred, **not final approval** |
| B02 | 2026-11-14 | Dark/charcoal + bright lime, **Performance Lime / Direction A**, is the preferred visual direction. | Preferred, **not final design tokens** |
| B03 | 2026-11-14 | Pull-Up Motion logo: rear-view muscular pull-up silhouette, lime on dark; `HOME` white and `SETS` lime. Owner liked the specific refined uploaded image. | **Preferred Logo Refinement; final validation outstanding** |

## Open items (do not silently resolve)

| ID | Question / investigation |
| --- | --- |
| O01 | Android version — resolved by E01. |
| O02 | Resolved by E04: displayed picker name `Gemini 3.8 Flash High`. Exact external product/version validity beyond display not checked. |
| O03 | Resistance-band strengths and whether to purchase stronger bands. |
| O04 | Exercise demonstration media, provenance and usable asset licenses. |
| O05 | Final brand name, logo vector, wordmark, accent color tokens, accessible contrast and font license. |
| O06 | Android auto-backup policy and Honor/MagicOS reminder reliability. |
| O07 | Resolve inconsistency between MVP onboarding supporting only the build-muscle goal and original P8 friend acceptance requiring a different goal. Additional goals are post-MVP unless explicitly approved. |
| O08 | Final app package identifier, launcher icon, and Android APK signing/update approach; do not create key until release plan is reviewed. |
| O09 | Preferred logo **image file** has not yet been uploaded to GitHub; text documentation is not a substitute for the exact reference. |
| O10 | Verify current Flutter package versions/maintenance and Android requirements at dependency-selection time. |

## Rejected / superseded concepts
- Earlier symbolic names ATHAR, NAMA, MADA were rejected.
- Earlier generic intertwined-letter/gym-shield/bar-chart logos were rejected.
- The first broad Brand Exploration sheet was not accepted.
- The **specific** refined neon-lime pull-up design shared by Ahmed is the current visual reference; do not casually replace with a similar image.

## Next owner gate
Confirm the registry is faithful, then preserve the exact selected image in `assets/brand/reference/` and review logo small-size, monochrome, Android adaptive-icon and vector-master tests. No technical logo approval yet.

## PO-only operating model — confirmed by Ahmed 2026-11-14

| ID | Decision | Status |
| --- | --- | --- |
| GOV01 | Ahmed is Product Owner: he makes product/design/scope decisions, approves gates, and tests behavior on the phone. No routine file operations, Git commands, or manual uploads. | Confirmed |
| GOV02 | ChatGPT owns planning, docs/decisions/issues it can update directly, design/architecture review, QA and Antigravity task briefs. | Confirmed |
| GOV03 | Antigravity owns local workspace/file handling, source/binary asset commits, implementation, command logs, builds and Git pushes through narrow authorized tasks. | Confirmed |
| GOV04 | One-time machine setup/authentication and phone testing may require Ahmed's direct action; minimize these and explain why. | Confirmed |
| GOV05 | No implicit authorization to change MVP scope, add dependencies, pay for services, or run destructive operations. **Guarded implementation merges are now explicitly authorized by GOV08**, not unconditional merges. | Confirmed, amended by GOV08 |

**Limit:** Current ChatGPT GitHub text-file writer cannot by itself upload the exact 2 MB image asset. The selected source image was verified locally and fingerprinted in ASSET_MANIFEST.md; commit of the exact binary remains an Antigravity handoff. Do not mark it Done until GitHub evidence confirms it.

## GOV06–GOV11 — Explicit workflow amendment (2026-11-14)

**Owner authorization (verbatim intent):** Ahmed approved changing human device testing from **every milestone** to **a final manual test only**, after understanding the late-defect risk. He authorized long autonomous Antigravity campaigns, automated tests, and merges after passing them, excluding destructive operations and out-of-scope changes. This explicitly changes the procedure in the immutable Master Prompt §0 rule 2, §13 and §16 and original D20, but NOT the app's functional scope, safety principles or documented verification standards.

| ID | Decision | Status |
| --- | --- | --- |
| GOV06 | Ahmed prefers long continuous autonomous Antigravity campaigns; no repetitive routine owner approvals. Agent works on many internal tasks per campaign and reports evidence/blocks. | **Confirmed** |
| GOV07 | **Human phone acceptance only at the final integrated release gate**. Original per-milestone phone gate D20 and Master Prompt §0 rule 2 / §16 are specifically superseded for the **timing of manual testing only**. Milestones still require automated evidence, tests and recorded commits; never call earlier device behavior verified. | **Confirmed — explicit supersession** |
| GOV08 | Antigravity may create branches, change files **within a preapproved campaign scope**, run tests/builds, push PRs and **merge** independently **only after all required automated checks are demonstrably green on the exact head, reviewed diff is within scope, no unresolved critical issues and required product/design approvals exist**. No blind merges, no bypassing failing/missing checks. | **Confirmed — guarded merge authorization** |
| GOV09 | No force push, deleting branches/workspaces/user data, secret exposure, external-repo access, paid services, unapproved dependencies, permissions expansion, out-of-scope changes, unsafe exercise logic or destructive operations. Agent must stop on those blockers. | **Confirmed limits** |
| GOV10 | Final device gate occurs on Honor X9e Pro via wireless APK (no USB). Verify install/update, workouts and resumes, localized UI, backup/photo privacy and reminder limitations. Until then, device behavior is **unverified**, even when automated tests pass. | **Confirmed testing schedule** |
| GOV11 | Product Owner continues to approve **major product/branding scope decisions** at planned gates, not every implementation task. Long campaigns cannot silently approve the logo, training safety, or changes to any other confirmed requirement. | **Confirmed** |

**Operational source of truth:** [Approved Autonomy Policy](AGENT_AUTONOMY_POLICY.md) and [Updated Roadmap](ROADMAP.md). The original Master Prompt is retained verbatim for history; newer explicitly confirmed entries GOV07–GOV11 control the conflicting process rules.

**Current blockers (unchanged):** Antigravity local origin/permissions unverified, preferred exact PNG missing from GitHub, CI not configured, brand and architecture approval incomplete. The authorization above is **policy**, not proof of an agent run, CI pass, APK, or merge.


## GOV12–GOV19 — Owner-approved C3-MEGA implementation gate (2026-11-15)

**[Confirmed] One grouped approval from Ahmed (Product Owner):** He explicitly approves the Hybrid C1 design, conservative hardware/safety defaults, private/offline data model, only the bounded dependency allowlist *after actual compatibility/license verification*, and execution of [C3-MEGA Issue #11](https://github.com/abuhmaid28/homesets/issues/11) for Flutter **P0–P4**, automated tests, exact-head CI and conditional normal merges without routine approvals. No destructive operation or unapproved MVP scope expansion. Real-phone acceptance stays **final only** per GOV07.

**This is a newer explicit approval superseding earlier "preferred/unapproved" classifications solely for the choices enumerated below.** The original Master Prompt and historical B01–B03 entries are retained verbatim; no final approval is inferred for the still-missing exact logo binary, vector icon, font licensing or unreviewed dependencies.

| ID | Decision | Status |
| --- | --- | --- |
| GOV12 | **Visual direction selected:** C1 **Hybrid B + A precision** — Direction B *Kinetic Depth* with warm charcoal, Performance Lime, rounded tactile cards/pills and restrained glow; borrow Direction A's tabular timers/counters. Use natural Egyptian Arabic RTL + English, light/dark and accessible responsive UI. **No orange/amber/teal substitution.** | **Confirmed — Owner approved 2026-11-15** |
| GOV13 | **Hardware eligibility:** owner baseline remains pull-up bar + resistance bands + bodyweight; no dumbbells, weighted backpacks or presumed furniture/accessories. `pulldown_door_band` defaults unavailable without **explicit verified suitable overhead/door anchor**; `row_table_inverted` unavailable without **explicit verified load-bearing furniture**; neutral-grip handles not assumed. Exercise capability gates must be enforced by *real Dart code and tests*, not just display notices. | **Confirmed — Owner approved** |
| GOV14 | **Safety:** immediate one-tap pain STOP preserving recorded sets, with **no loaded substitute automatically prescribed**, no diagnosis/shame. Recovery/progression and post-absence deload are adjustable conservative heuristics, not medically validated guarantees; never force a timed Lite workout to rush rest. | **Confirmed — Owner approved with conservative/adjustable guardrails** |
| GOV15 | **Privacy/storage policy:** offline local app-private data/photos, no accounts/backend/online AI/telemetry/cloud sync. Manual explicit backup/export later, with sharing warning; Android backup/extraction and failure-recoverable restore are *planned and must be tested*, not guaranteed or already deployed. **C3 P0–P4 covers profile/session/set persistence only; photos and backup belong to later milestones.** | **Confirmed — Owner approved model, implementation unverified** |
| GOV16 | **Conditional dependency allowlist only:** `drift` + `drift_flutter` as preferred persistence pair **OR** `sqflite` fallback (not both); `path_provider`, Flutter SDK localization plus `intl`, `uuid` (optional), `crypto`, `archive`, `flutter_local_notifications` only at their corresponding approved features/milestones. Check exact current package version, license, Dart/Flutter/Android/Gradle compatibility and actual `flutter pub get`/analyze/test/APK first; retain `pubspec.lock`. Do not adopt stale draft pinned numbers or add any other direct dependency without approval. Do not install archive/notifications merely for future P5/P6. | **Confirmed conditional authorization, versions & builds unverified** |
| GOV17 | **C3-MEGA execution authorization:** Antigravity may autonomously implement the 32-WP **P0–P4** real Flutter Android foundation, theme/localization, safe deterministic workout engine, local persistence, onboarding → Today → Active Workout → Rest → Lite → Summary; run analyzer/tests/build and establish real exact-head Flutter CI; small commits, PRs and **normal merges only after all GOV08 gates pass**. No routine PO approvals or phone tests until final C9. | **Confirmed — authorized, not executed yet** |
| GOV18 | **Brand scope boundary:** HOMESETS is the approved **working app name for implementation**, while the **exact preferred Pull-Up Motion PNG / final vector/adaptive launcher icon and license/visual validation remain OPEN** (Issue #1). Until exact asset is verifiably available, use a temporary neutral HOMESETS **wordmark only**, not a fabricated logo or final launcher claim. | **Confirmed interim implementation rule; final logo still open** |
| GOV19 | **Remaining owner gates:** This approval covers C3 P0–P4 only; does not authorize P5–P8, new exercise goals, new subscriptions, paid CI, auto-backup, future user-data migration guarantees, final signing keys, repo/publication or irreversible changes. Record any provisional technical app ID and its upgrade implications; final signing/package ID release gate O08 still open. | **Confirmed limits** |

**Decision provenance:** Ahmed's direct approval in the HOMESETS conversation on 2026-11-15; the previously proposed grouped policy is recorded in [C2R_OWNER_GATE_PACKAGE.md](https://github.com/abuhmaid28/homesets/blob/campaign/c2-mega-foundation/docs/reviews/C2R_OWNER_GATE_PACKAGE.md). Any agent claims of test success, repo merge, APK, package compatibility, or Honor behavior remain **UNVERIFIED until direct evidence**.

**Current next step:** Update [Issue #11](https://github.com/abuhmaid28/homesets/issues/11) to authorized and hand one long Antigravity task to the verified HOMESETS workspace. User is not asked to operate routine Git commands.

## GOV20 — Explicit C3 dev-only dependency exception (2026-11-15)

**Owner authorization (direct):** Ahmed explicitly approves `flutter_lints ^6.0.0` and `sqflite_common_ffi ^2.4.7` **as Dev-Only exceptions to GOV16**, and authorizes a guarded normal merge of [PR #12](https://github.com/abuhmaid28/homesets/pull/12) after all GOV08 checks are reverified.

| ID | Decision | Status |
| --- | --- | --- |
| GOV20 | **Narrow exception to GOV16, for HOMESETS C3 P0–P4 only:** allow `flutter_lints: ^6.0.0` under `dev_dependencies` for static lint rules, and `sqflite_common_ffi: ^2.4.7` under `dev_dependencies` for headless SQLite tests/CI. They must remain dev-only; no authorization to add other packages, runtime network services, paid dependencies, or to expand P5–P8. Preserve `pubspec.lock` and verify the exact resolved package versions and license evidence at relevant gate. **Merge authorization is conditional on GOV08 exact-head green CI, reviewed in-scope diff, no critical blocker, and a non-force GitHub PR merge.** | **[Confirmed] — Ahmed approved 2026-11-15** |

**Scope and provenance:** This is an additive, narrow exception; all other GOV16 restrictions remain in force. The final C3 technical review is recorded on [PR #12 review #5909225185](https://github.com/abuhmaid28/homesets/pull/12#pullrequestreview-5909225185). The current Flutter Core candidate uses provisional `com.abuhmaid.homesets`; final signing/package ID and Honor acceptance are still separate gates.
