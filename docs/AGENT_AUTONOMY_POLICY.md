# HOMESETS — Approved Agent Autonomy & Merge Policy

**Status: [Confirmed], approved by Ahmed (Product Owner) on 2026-11-14.**
Decision source: `docs/DECISION_REGISTER.md` GOV06–GOV11. This **supersedes the human device-testing timing** in original D20, Master Prompt §0 rule 2 and the original P0–P8 schedule. It does not modify confirmed product requirements or waive automated test evidence.

## Responsibilities
- **Ahmed — Product Owner:** choose product direction and review major brand/product decisions at designated gates; perform one integrated hands-on acceptance on Honor X9e Pro near release. No routine GitHub uploads, commands, or agent prompts per subtask.
- **ChatGPT — Lead and independent reviewer:** maintain project source-of-truth, plan campaign scope, prepare exact agent briefs, review evidence and discrepancies, keep GitHub issues/status updated when tools permit.
- **Antigravity — Execution agent:** execute approved long campaigns in the HOMESETS-only workspace; safely edit files, run automated checks, fix failures, create Git commits, push branches, open PRs, and **merge passing scoped work automatically** after all gates below.

## Uninterrupted campaigns, small internal checkpoints
- A **campaign** is a long-running authorization with a written goal, exact permitted file areas, excluded areas, acceptance tests, dependencies, and stop conditions. Target continuous work as far as tool quota/runtime permits; never promise guaranteed hours.
- Internally divide into small revertible slices with commits, logs, tests and change summaries. Continue automatically from slice to slice while in scope and checks are green.
- No repeated approvals for routine edits, test fixes, formatting, Git commits, PR creation, or quality re-runs within the campaign.
- The agent may improve the implementation of approved functionality; may **not** decide new MVP features, product goals, training safety rules, final brand assets, novel dependencies, external services, or destructive system changes.
- If an unattended run is interrupted, resume from a verified branch/commit and current state. Do not fabricate completion, retries or evidence.

## Automated gate for every implementation merge
All of these must be true **before** Antigravity can merge code:
1. **Repo identity verified:** exact owner/repo `abuhmaid28/homesets`; intended base `main`; clean and reviewed change set.
2. **Within authorized scope:** all changed paths and dependency deltas reviewed against the approved campaign; no secrets or personal fitness photos in Git.
3. **Actual tests:** `flutter analyze`, `flutter test` (relevant unit/widget/data/RTL tests), `flutter build apk` as applicable, plus scenario/security/migration/backup tests for touched features. Capture full raw logs and exit codes.
4. **Exact-head CI:** a working GitHub Actions workflow runs the relevant checks on the exact PR head commit and reports **green**. A missing, skipped, stale or inaccessible check is **NOT PASS**.
5. **Regression & quality:** fix critical test, data-loss, privacy, permission, unsafe-training, localization and build failures. Review API/dependency/license changes before inclusion. No unresolved critical finding.
6. **Approvals where required:** major product/brand/safety/design gates explicitly approved beforehand. This workflow approval does not silently grant approval to build beyond an unapproved gate.
7. **Traceability:** PR description links the relevant campaign/issue, displays file list, exact head SHA, test artifacts, known limitations and rollback plan.
8. **Merge method:** permitted normal non-force GitHub PR merge into `main` after the above. If platform Auto-merge is unavailable (private repository plan or `allow_auto_merge` false), agent may execute normal merge **only if all conditions hold and permissions permit**; never enable paid features or bypass checks.

If CI is not yet configured, **implementation merges are blocked until it is working**; a green local command alone does not authorize code merge. Documentation-only changes may be maintained within their own scope and proof of content review, but never assert CI is green if it is absent.

## Deferred physical acceptance — explicitly chosen tradeoff
- **No human phone test at P0/P1/... between milestones.** Use automated unit/widget/integration tests, builds and CI throughout; collect APK artifacts where practical.
- **Final integrated acceptance on Honor X9e Pro** (Android 16, MagicOS 10), transferred wirelessly; no USB.
- Verify actual install, end-to-end session and Lite mode, missed-day logic, interruptions/restart, RTL and accessibility, private progress photos, trends, manual backup/restore, reminder behavior, data persistence, signed APK update without loss, fully offline behavior.
- Until the device gate is completed, any physical-device performance, notifications, hardware/storage or installation claims are **UNVERIFIED**. Device-specific failures may require rework even if automation passed.
- Never claim full MVP Done or final release accepted until Ahmed reports the phone results and any failures are resolved.

## Absolute stop conditions (not delegated)
- Unrelated repository/directory, unclear Git origin, existing data may be overwritten.
- Force push, workspace/branch deletion, destructive cleanup, secrets, signing keys in Git, external access, public repo change, payment/paid service, cloud/backend.
- A dependency or SDK change without prior explicit authorization.
- Conflicts with confirmed MVP/brand decisions; unsafe exercise progression or unreviewed medical claims; unresolved security/privacy risk.
- Missing test logs, failed or skipped required CI, ambiguous merge target, lack of required approval.
- Access outside HOMESETS workspace or an agent prompt requesting to defeat security controls.

## Agent settings (verify locally; do not presume)
On current Antigravity versions, **Auto** with project-scoped workspace boundaries is preferable; **Turbo** has unrestricted filesystem access and does not fit this project's safety boundary. Exact Windows capabilities depend on version, sandbox availability and user's account, and may still prompt for sensitive host/network operations. Do not modify global permissions simply to suppress all prompts. No tool can guarantee a continuous multi-hour run.

## GitHub baseline limitation
As of initial audit: `allow_auto_merge: false`, branch protection inaccessible via this connection, no CI workflow, no implementation PR. The approved authority is **conditional**, not a statement that GitHub automatically merges today.

## Campaign sequence
- **C0:** verify local clone/origin and workspace rules, preserve exact logo reference; document/configure gate tooling. No Flutter product code.
- **C1:** draft and refine branding/UX/design system for owner review, no Flutter UI implementation before applicable owner gates.
- **C2:** architecture, dependency/license/security and deterministic training test plan for owner review.
- **C3+:** scoped P0–P8 implementation campaigns with internal tests and conditional merges, without intermediate human device tests.
- **Final:** single integrated phone acceptance, rework/regression if necessary, then signed private APK release.

Related: `docs/ROADMAP.md`, `PROJECT_RULES.md`, `docs/PROJECT_STATUS.md`.
