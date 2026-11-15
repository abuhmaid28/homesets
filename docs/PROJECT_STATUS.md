# HOMESETS — Current Project Status

**Updated:** 2026-11-14. All claims below are based on actual GitHub reads or owner screenshots as specified. No Antigravity run has been observed.

## Working model (owner-approved on 2026-11-14)
- Ahmed = **Product Owner only**; no routine commands, uploads, manual Git chores or per-step approvals.
- ChatGPT = project lead, planner, architect, governance and independent QA reviewer.
- Antigravity = long-running autonomous campaigns in verified HOMESETS-only workspace, with independent small internal commits, tests/CI, and **conditional automatic normal PR merges after all required gates pass**.
- **Explicit change:** manual Honor X9e Pro device test happens **only at final integrated acceptance**, not between P0–P8. Keep automated checks after each implementation slice. Never say device-tested early.
- [Canonical policy](AGENT_AUTONOMY_POLICY.md), [Decision Register GOV06–GOV11](DECISION_REGISTER.md), [Current roadmap](ROADMAP.md).

## Evidence verified to date
| Topic | Status | Evidence |
| --- | --- | --- |
| Private GitHub repo | VERIFIED | `abuhmaid28/homesets`, `main` |
| Initial Docs/Decision Register | VERIFIED PRESENT | GitHub file reads; approved product/design details still gated |
| Development toolchain | VERIFIED BY AGENT RUN | Windows 10 Enterprise 22H2, Flutter 3.47.0 (stable), Dart 3.13.0, Android SDK 36.0.0; `flutter doctor` verified clean ("No issues found!") |
| Antigravity project in UI | VERIFIED IN WORKSPACE | `homesets` workspace verified at `C:/Users/TopOne MM/Documents/homesets`, model Gemini 3.8 Flash High |
| Local Git origin and files | VERIFIED BY AGENT RUN | Root `C:/Users/TopOne MM/Documents/homesets`, origin `https://github.com/abuhmaid28/homesets.git`, main tracking origin/main, clean tree |
| Actual loaded Antigravity rules / permissions | VERIFIED | Root `AGENTS.md` active per Antigravity rules engine; project-scoped workspace execution, non-workspace access denied, global Turbo disabled |
| Original owner-selected logo PNG in GitHub | **MISSING (ASSET_SOURCE_UNAVAILABLE)** | Reference folder contains only `.gitkeep`; file missing locally in workspace; no lookalike substituted |
| Final brand, UX, design system | **PENDING APPROVAL** | Pull-Up Motion / Performance Lime preferred only |
| Flutter app source / APK | **NOT CREATED** | No Flutter tree/build evidence |
| GitHub CI / required automated checks | **NOT CONFIGURED** | No `.github/workflows` at audit |
| Branch protection | **UNVERIFIED** | GitHub app query 403 |
| GitHub native Auto-merge | **NOT ENABLED IN REPO METADATA** | `allow_auto_merge=false`; programmatic ordinary merge is a separate approved operation after checks |
| Physical phone test | **DEFERRED UNTIL FINAL** | No APK currently; user-approved policy |

## Stages
| Stage | Status | Next proof |
| --- | --- | --- |
| G0.1 Private repository | VERIFIED | Metadata |
| G0.2 Source-of-truth files | REVIEWED & VERIFIED | Audit findings documented in `docs/reviews/FOUNDATION_REVIEW_G0_CAMPAIGN_01.md` |
| G0.3 Exact logo asset | BLOCKED | `ASSET_SOURCE_UNAVAILABLE` locally; exact PNG pending upload with SHA-256 verification (Issue #1) |
| G0.4 Antigravity Git linkage/rules | VERIFIED | Local repo root, origin remote, and `AGENTS.md` rules verified |
| G1 Product Blueprint | DRAFT | Owner approval of major requirements |
| G2 Branding | PREFERRED DIRECTION ONLY | Owner approval after technical validation |
| G3–G5 UX/design system/high fidelity | NOT APPROVED | Design evidence |
| G6–G7 Architecture & CI/rules | NOT APPROVED / NOT BUILT | Approved design and independent CI gate |
| P0–P8 Flutter implementation | NOT STARTED | Automated build/test/CI per milestone; normal merge only after passing |
| Final Honor acceptance | NOT STARTED | Single manual integration test + retest if necessary |

## Current campaign
- [G0-CAMPAIGN-01 Issue #2](https://github.com/abuhmaid28/homesets/issues/2) was **EXECUTED & VERIFIED** by Antigravity on 2026-11-14.
- Results: Exact Git origin, toolchain, and workspace isolation verified; docs consistency review completed; missing exact logo recorded as `ASSET_SOURCE_UNAVAILABLE`; CI prerequisites documented.
- Next campaign: Campaign C1 (G1/G2/G3 Blueprint, Brand & UX planning) and G7 CI workflow setup. Exact PNG preservation pending binary availability.

## Risks / stop conditions
- Other repos visible on PC; no global unrestricted Turbo access.
- Without actual CI, **no implementation PR may merge**, even under newly approved automatic merge policy.
- Fitness logic must honor conservative training safety and recovery; no diagnosis or body shaming.
- Original Master Prompt is immutable history; GOV07 explicitly supersedes only manual phone-test **timing**.
- A one-time setup or OS/Git authentication step may require Ahmed; do not ask him to perform routine maintenance.

## Handoff to any new chat
Read `docs/DECISION_REGISTER.md`, `docs/AGENT_AUTONOMY_POLICY.md`, this file, `docs/ROADMAP.md`, `PROJECT_RULES.md` and the latest live GitHub state. Honor newer explicit decisions; never claim that unobserved agent work happened. Identify current campaign and one concrete next step.

## Independent GitHub review after G0-CAMPAIGN-01 (2026-11-14)
- ChatGPT independently verified [PR #3](https://github.com/abuhmaid28/homesets/pull/3) merged to `main`: head `7a56ed4148794477ed84eb863013eef042917a30`, merge commit `9265e6f6004a21ee222dcdc16518820d88de0d34`; changes limited to three docs, no Flutter runtime.
- [Issue #2](https://github.com/abuhmaid28/homesets/issues/2) closed.
- GitHub PR-head combined status shows **zero status checks**; do not cite any successful GitHub Actions run for G0. Documentation-only merge reviewed; no runtime code merge permitted while CI absent.
- Local Git/Flutter and permission results were recorded by Antigravity, but actual Windows permission enforcement was **not independently tested by ChatGPT**. See [independent review](reviews/INDEPENDENT_G0_REVIEW.md).
- Exact preferred PNG exists in ChatGPT session storage with SHA-256 `95822f54686cc17b7878322dc23607af04a010e073ffd722b91c2bc012d1596b`; **still missing in the Antigravity local workspace and GitHub**.
- [C1 design-only autonomous campaign — Issue #4](https://github.com/abuhmaid28/homesets/issues/4) is **prepared, not executed**. It may produce product/UX/design drafts and offline static mockups as one bounded run; no Flutter code, CI claims, or approval of final brand.

## C1 product/UX/design review — 2026-11-14
- Antigravity pushed [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5), head `70aaacc2a72278e876163033a7a61b8542fb9c5e` with **17 files / 5 commits**, all documentation and offline static HTML design previews. **NOT merged to main.**
- ChatGPT independently reviewed GitHub files and added [review #5906101899](https://github.com/abuhmaid28/homesets/pull/5#pullrequestreview-5906101899) as **CHANGES REQUIRED** (comment review, not approval): R01 contrast errors incl dim text not AA; R02 Android 12+/16 backup privacy and cross-file restore atomicity; R03 pain safety and assistance/resistance bands; R04 static HTML and missing real render/screenshot validation, inaccurate substitute logo; R05 stale/unverified package versions; R06 UX scope/sample data inconsistencies.
- **C1 gate remains OPEN**. Await agent fix pass on **same Draft PR**; get screenshot evidence for one grouped owner visual review; no routine approvals and no Flutter implementation yet.
- Current official pub.dev evidence (2026-11-14): drift 2.35.4, drift_flutter 0.3.1, flutter_local_notifications 23.0.2 (min Dart 3.12) — **candidates only**, no dependency selected/approved. Links in the PR review.
- Exact owner-selected `homesets-pullup-preferred.png` source is present in ChatGPT working storage and checksum was rechecked as `95822f54686cc17b7878322dc23607af04a010e073ffd722b91c2bc012d1596b`; however **binary remains absent from HOMESETS GitHub**. Distinguish local ChatGPT asset from Antigravity workspace access.

## 2026-11-14 — End-to-end plan and extended C1 work
- [Master execution plan](MASTER_EXECUTION_PLAN.md) defines C0–C9, detailed goals, internal tests, necessary PO gates and final-only Honor acceptance; campaign map is recommended execution grouping, not new scope approval.
- Owner requests genuinely long autonomous work with no routine interruptions; extended [C1-R Issue #6](https://github.com/abuhmaid28/homesets/issues/6) expands correction R01–R06 into responsive UI/design polish, actual visual captures, WCAG/privacy/safety corrections, documentation QA and grouped review.
- **C1-R not yet executed**. Must stay on existing [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5), no merge, no Flutter app or new dependency.
- Current blockers unchanged: exact selected logo binary absent from repo; CI absent; final brand/product/architecture gates unapproved.

## 2026-11-14 — Sequential campaign delivery policy
- Owner reports the **earlier short C1 correction prompt has already been sent**. Its completion/result has **not yet been verified**; do not launch a parallel C1-R on the same branch.
- New [Autonomous Delivery Runbook](AUTONOMOUS_DELIVERY_RUNBOOK.md) maps C0–C9 with work packages, small internal checkpoints, automated tests, guarded merges, and grouped PO acceptance gates.
- [Queued extended C1-R Issue #6](https://github.com/abuhmaid28/homesets/issues/6) is **continuation AFTER the small run**. Inspect newest Draft PR #5 head; skip previously fixed findings and do remaining long design/visual QA tasks. No extra prompt until current run reports.
- GitHub issues and documents do not by themselves start an Antigravity session. A future launch/resume requires the agent to receive a single next-campaign instruction and active local workspace.

## C1 small correction run completed — independent GitHub post-check (2026-11-14)
- User supplied full Antigravity correction run output (local campaign report). GitHub independently confirms **Draft PR #5** still OPEN/unmerged, head `db5036a1e3e9892f9eb6b53ee29500c17708150d` (6 commits total, 32 changed paths).
- `docs/reviews/C1_CORRECTION_MATRIX.md` exists. Revisions to R01–R06 text are in the PR. **14 real PNG screenshots are committed** under `design/screenshots/` and independently retrieved/visually inspected by ChatGPT using GitHub file content (not mere file presence).
- [Independent post-correction Review #5906201631](https://github.com/abuhmaid28/homesets/pull/5#pullrequestreview-5906201631): correction pass accepted as **pushed/delivered**, but **C1 OWNER DESIGN GATE REMAINS OPEN**. Remaining visual QA: full-screen clean screenshots without proposal banners, separate rest timer state, remove blue thumb-zone diagnostic guide, 1.5× text-scale checks, synthetic fixture labeling, reproducible contrast script not in committed PR.
- **Issue #6 now READY for sequential execution** as a longer, non-duplicative C1 design/UX/QA campaign on the same Draft PR. Do not run it concurrently with another active PR #5 edit.
- No Flutter application, CI or final brand approval. Logo reference exact PNG still absent from GitHub. No actual Honor device test before final release acceptance (GOV07).

## 2026-11-14 — C1-R delivered, independent visual QA, longer C1-V2 mission
- [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5) **open/unmerged** at head `78282819f781a1dd66204aeec2ea6ade812882d1`, 8 commits, 73 changed paths. Agent supplied C1-R checkpoint and 24 gallery PNG files; GitHub verifies these are present and readable. **No Flutter production code, no active CI.**
- [C1-R Issue #6](https://github.com/abuhmaid28/homesets/issues/6) closed as campaign *deliverable* complete. **This does NOT signify G1–G5 product/brand/UX approval**.
- Independent screenshot inspection found P0 broken AR/English Progress header, awkward English workout name wrapping, empty Workout center space, crowded/rest text and inconsistent Today information density. See [C1 post-marathon visual QA](reviews/C1_POST_MARATHON_VISUAL_QA.md).
- **Next substantial delegation:** [C1-V2 Issue #7](https://github.com/abuhmaid28/homesets/issues/7), a **12-package autonomous design, offline interactive prototype, reproducible responsive/RTL/large-type QA and C2 architecture/CI-preflight campaign**. It is **prepared, NOT executed**. Same Draft PR #5; no merge, new Flutter production code or dependencies before design/safety/privacy gates.
- Owner explicitly wants long productive campaigns without repetitive approvals. Time quota/runtime cannot guarantee fixed hours. Continue all in-scope packages autonomously with checkpoints; stop only at real PO/safety/security/dependency gates.
- Blockers: exact preferred PNG still missing from GitHub; app CI absent; Product Owner must choose actual visual direction after one grouped comparison; workout safety/backup privacy architecture remain proposed. Final physical Honor acceptance remains at release.

## C1-V2 complete in scoped outputs; C2-MEGA queued (2026-11-15)
- [PR #5](https://github.com/abuhmaid28/homesets/pull/5) still **Draft / unmerged**; head `8a0e1cf3eaed81ad51104c44168b97d8ddcfe996`, 13 commits, 112 changed paths; includes proposed A/B visuals and offline demo. Device runtime unverified; brand/product visual gate OPEN.
- [Issue #7](https://github.com/abuhmaid28/homesets/issues/7) closed as **scoped task delivery only**. [Independent review](reviews/C1_V2_INDEPENDENT_DELIVERY_REVIEW.md) flags stale/obsolete sqlite3 Flutter libraries, invalid weighted pullup example, unsafe acute-pain auto replacement, inaccurate UUID determinism and backup atomicity / transfer assumptions.
- **Next prepared long campaign:** [C2-MEGA Issue #8](https://github.com/abuhmaid28/homesets/issues/8), 28 substantial work packages: architecture ADRs, safety-aware workout specifications, ≥100 structured scenario fixtures, backup/privacy/failure analysis, package/license review, **foundation-only GitHub Actions CI** with actual exact-head evidence if available, independent red-team QA and a combined PO gate package.
- C2-MEGA is **NOT executed**, and does not authorize Flutter app, dependency installation or merging the draft design. The agent will work on an isolated new branch off main, not overwrite C1 draft work.
- Pending brand source: exact preferred binary Pull-Up image still not in GitHub; no final vector icon approval. Automated checks cannot be treated as a real Honor phone test; owner approved only final device acceptance.

## 2026-11-15 — C2-MEGA independent review and Foundation CI repaired
- [Draft PR #9](https://github.com/abuhmaid28/homesets/pull/9) originally submitted at `ae9967e7254548d8ec6519b7a450eb61621bd72c` (40 changed paths). Antigravity's local `gh` token lacked `workflow` scope and `.github/workflows` push was rejected.
- **ChatGPT's separate connected GitHub App actually created** active `.github/workflows/foundation.yml` (PR-only, low usage, 10-minute bounded job) at commit `20994cab3f79f67f858000ce3019cf688e3cab05`; **first** [run #43660727324](https://github.com/abuhmaid28/homesets/actions/runs/43660727324) FAILED due to invalid `cache: false` in `actions/setup-python@v5`.
- ChatGPT fixed configuration at commit **`c43420af66108584a41cd2b061b13a30db77430e`**. Verified **exact-head GitHub Actions [run #43660778170](https://github.com/abuhmaid28/homesets/actions/runs/43660778170)** completed **SUCCESS**. All foundation fixture, link, hygiene steps passed. **This is NOT Flutter CI / app tests**.
- Subsequent source review detected missing semantic checks in fixture validator; exact duplicate scenario input+output pairs `SCEN-089/093`, `SCEN-090/094`, invalid catalog refs `pushup_decline_feet_elevated` and `pushup_band_resisted`, missing door-anchor equipment eligibility, unverified exercise-license provenance and unsupported Lite time/safety guarantees. **C2 acceptance is still OPEN.**
- [Independent source-grounded review](reviews/C2_MEGA_EXTERNAL_QA_2026-11-15.md) and [PR #9 review #5908324308](https://github.com/abuhmaid28/homesets/pull/9#pullrequestreview-5908324308) document exact findings. [C2-R Issue #10](https://github.com/abuhmaid28/homesets/issues/10) queues **20 productive WPs** for semantic validator hardening, catalog/safety repair, mutation tests and *new exact-head* CI regression on **same Draft PR #9**.
- **Critical local checkout note:** direct GitHub App commits moved branch to `c43420af` ahead of local Antigravity; agent must `git fetch` and safely fast-forward before writing, never force push/reset.
- No runtime Flutter app, APK or implementation CI. Both design PR #5 and architecture PR #9 are Draft/unmerged pending grouped major design/safety/privacy/dependency gate. Exact original Pull-Up PNG still missing from repo.

## 2026-11-15 — C2-R verified and transition to real Flutter proposed
- [PR #9](https://github.com/abuhmaid28/homesets/pull/9) C2-R original agent head verified as `93f15ee9209ca2154c751e49c3cb185603f3d066` (different from the full SHA pasted in Antigravity report). Foundation GitHub Actions [run #43662773807](https://github.com/abuhmaid28/homesets/actions/runs/43662773807) succeeded on this **exact** head (pull_request event). It verified fixture schema/21 validator mutation cases, links and hygiene, **not Dart/Flutter behavior**.
- Independent inspection of 106 scenario fixtures and 14 exercise catalog entries showed no identical input/output pairs and no broken named referenced exercise IDs; the 21 tests exercise validator inputs, not an implemented workout engine.
- **New unresolved P0 safety defect:** `pulldown_door_band` says required only bands while it actually requires verified overhead anchor; `row_table_inverted` requires verified load-bearing furniture while coded as bodyweight only; neutral vs underhand grips conflated. Default eligibility must exclude unverified physical setups. Current validator cannot guarantee runtime eligibility.
- **Owner decision misinformation corrected:** C2R decision package erroneously offered orange and amber/teal visual options, contradicted by actual C1 charcoal×Performance Lime A/B/Hybrid. Corrected the package **on Draft PR #9** in commit `fc5187d7f55272dfada19e7884f060dca13f9952`. It also now explicitly labels Android backup/restore as **planned/unverified**, not deployed/guaranteed, and describes conditional dependency allowlist. New CI run on corrected head must be verified separately; previous passing run is not proof of corrected head.
- Independent review saved to [C2R_EXTERNAL_FLUTTER_READINESS_2026-11-15.md](reviews/C2R_EXTERNAL_FLUTTER_READINESS_2026-11-15.md); [PR review #5908416675](https://github.com/abuhmaid28/homesets/pull/9#pullrequestreview-5908416675).
- **Next meaningful development, pending one major owner gate:** [C3-MEGA Issue #11](https://github.com/abuhmaid28/homesets/issues/11), **32 substantive work packages of real Flutter P0–P4 code + real analyze/test/APK/Flutter CI**, not another docs-only marathon. Planned design recommendation is Hybrid B Kinetic Depth charcoal/lime plus A tabular timers, safe equipment gating, local-only storage and version-verified minimal dependencies; **no owner approval yet**.
- C1 Draft PR #5 and C2 Draft PR #9 both remain unmerged pending grouped product/brand/safety/dependency gate. Exact preferred logo binary not yet on GitHub, use wordmark-only temporary placeholder if owner authorizes; no final app icon assertion. No APK, real Flutter CI or device test yet.

- **Correction recheck PASS:** [Run #43663431371](https://github.com/abuhmaid28/homesets/actions/runs/43663431371) completed SUCCESS on exact revised PR #9 head `fc5187d7f55272dfada19e7884f060dca13f9952` (pull_request). **Foundation-only CI**, no Flutter tests.

## 2026-11-15 — C3-MEGA owner gate explicitly approved
- [Decision Register GOV12–GOV19](DECISION_REGISTER.md) records **Ahmed's one-time explicit approval** of Hybrid B Kinetic Depth warm-charcoal/Performance-Lime + Direction A tabular counters, safe equipment/pain defaults, offline private storage, limited dependency allowlist conditional on compatibility/license validation, and autonomous real Flutter P0–P4 implementation.
- [C3-MEGA Issue #11](https://github.com/abuhmaid28/homesets/issues/11) updated to **AUTHORIZED / READY TO LAUNCH**, 32 substantial internal WPs; **NOT yet executed**, no Flutter app/APK or app CI verified.
- Separate [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5) (C1 design) and [Draft PR #9](https://github.com/abuhmaid28/homesets/pull/9) (C2 architecture) remain unmerged. Their reference designs/specs may be selectively adapted into C3 if consistent with newly confirmed decisions; don't blindly merge older draft inaccuracies.
- Last verified Foundation CI for updated C2 PR #9 [run #43663431371](https://github.com/abuhmaid28/homesets/actions/runs/43663431371) PASS on exact head `fc5187d7f55272dfada19e7884f060dca13f9952`; this is **not Flutter CI**. Implementation merges require separate real Flutter exact-head checks.
- C3 excludes P5 photos/weight graphs and P6 notifications/manual backup; only session/profile/set persistence in this campaign. Temporary wordmark allowed; original Pull-Up PNG vector/icon remains pending Issue #1. Final human Honor test unchanged at C9.
- Conditional packages and real app build/test/device behavior remain **unverified until executed**.

## 2026-11-15 — C3-MEGA independent code review and Flutter CI activation
- Owner explicitly approved C3 P0–P4 (GOV12–GOV19); Antigravity implemented real Flutter Android core on [Draft PR #12](https://github.com/abuhmaid28/homesets/pull/12). Source head at original agent report `9bcd72fefe1f43dbc7db2981837f65cc5886158b`; **do not mark merged or fully accepted**.
- ChatGPT created **actual** `.github/workflows/flutter.yml` on C3 branch (new head `e5914ae16b956f3662959bf60dae87a3b50bc290`) via connected GitHub App. Two GitHub Actions runs triggered ([PR run #43668524163](https://github.com/abuhmaid28/homesets/actions/runs/43668524163) and [push run #43668519943](https://github.com/abuhmaid28/homesets/actions/runs/43668519943)). At last inspection **in progress**, no full CI PASS. The old YAML under docs/quality was merely a proposal.
- Independent source review [C3 code+CI audit](reviews/C3_INDEPENDENT_CODE_CI_AUDIT_2026-11-15.md), [PR review #5908647769](https://github.com/abuhmaid28/homesets/pull/12#pullrequestreview-5908647769) **NO-GO**: empty eligible-exercise crash, routine A-only schedule and nondeterminism, incomplete session/crash resume incl Lite, pain STOP dialog before stop + no durable joint quarantine, missing capability gates, misleading Debug APK zero-INTERNET claim, weekly credit semantics, dependency allowlist reconciliation and unexercised 106 scenarios.
- [C3R-MEGA Issue #13](https://github.com/abuhmaid28/homesets/issues/13) **prepared but not executed** as one substantial autonomous 12-WP safety, reliability, UI, tests and CI correction campaign; stays in authorized P0–P4 scope; no routine approvals, no merge until test/review gates pass.
- Agent-reported local Flutter 22/22 test pass and 181.76 MB debug APK SHA are **not** independent CI or physical Honor acceptance; current CI exact-head must be checked for full completion and result.
- **No new human device test until final C9** under GOV07. No new authorization for P5–P8.

## C3R-MEGA independent post-CI review (2026-11-15)
- **Source head verified**: `0a584e32c38903c82b4f4a21e953b05a0c11e110` (the agent reported a mismatching *full* SHA). [Draft PR #12](https://github.com/abuhmaid28/homesets/pull/12) remains OPEN/unmerged; 94 changed paths / 10 commits.
- **GitHub exact-head CI VERIFIED PASS**: [PR run #43670559232](https://github.com/abuhmaid28/homesets/actions/runs/43670559232) and [push run #43670555345](https://github.com/abuhmaid28/homesets/actions/runs/43670555345) both completed successfully; both Flutter analyze/test/debug build and foundation quality jobs green. Actual GitHub evidence; local APK SHA and Honor operation not independently verified.
- **Technical gate STILL NO-GO** despite CI: [second independent PR review #5908809630](https://github.com/abuhmaid28/homesets/pull/12#pullrequestreview-5908809630) discovered double-rotation under <36h, misleading 106-scenario coverage (some expected-fixture checks only), silent legacy/corrupt saved-session substitution, phantom pain-stop reps and race, missing real progression wire-through, zero-set weekly credit, inaccurate dependency/manifest assertions.
- **Next long campaign**: [C3R2 Issue #14](https://github.com/abuhmaid28/homesets/issues/14) is prepared but NOT executed. It specifies 10 substantial work packages for in-scope P0–P4 fixes/tests/CI and independent review on same Draft PR #12. No merge until independent go decision and new exact-head green CI. No new owner approval for routine fixes.
- **Physical Honor acceptance** remains final C9 by GOV07. No new authorization for P5–P8. Issue #1 selected exact PNG still open.
