<!-- Canonical campaign brief mirrored from GitHub Issue #2 for local Antigravity access. GitHub issue status controls execution tracking. -->

# G0-CAMPAIGN-01 — Antigravity autonomous HOMESETS foundation verification

**Status: Authorized owner-approved campaign brief; NOT YET EXECUTED.**
**Current approved policy:** [docs/AGENT_AUTONOMY_POLICY.md](AGENT_AUTONOMY_POLICY.md), [GOV06–GOV11](DECISION_REGISTER.md). Ahmed is Product Owner, not operator.

## Goal
In one uninterrupted Antigravity campaign, verify that the selected local **homesets** workspace is attached only to the correct private GitHub repository, all persistent rules load, and the docs/quality foundation is consistent. Complete all safe internal substeps without asking Ahmed to approve each ordinary operation. **No Flutter product code or APK yet.**

## Context
- Exact remote: `https://github.com/abuhmaid28/homesets.git`, expected `main`.
- `AGENTS.md` and `PROJECT_RULES.md` now exist on GitHub.
- Master, decisions, [Roadmap](ROADMAP.md), Brand Direction and Current Status already exist.
- Manual phone testing is now **final-only**; ignore old superseded instructions that require a physical test after each small milestone.
- Code merges may be automatic **only** after actual CI is operational and all exact-head checks pass; there is no established CI yet, so **do not merge any app runtime code**.
- Exact owner-preferred PNG has a fingerprint in Asset Manifest, but is **not** yet available in GitHub. Do not substitute any similar image or claim it was uploaded.

## Authorized scope / work sequence
1. Inspect the selected workspace absolute path and existing files first (read-only).
2. Run and save raw `git rev-parse --show-toplevel`, `git remote -v`, `git branch --show-current`, `git status --short --branch`, `git log -1 --oneline`. Redact credentials if embedded.
3. If correct HOMESETS clone already exists, use it. If empty non-git folder, safely clone HOMESETS without destroying or replacing anything. If unrelated/dirty/ambiguous state, **STOP with one precise blocker**, do not delete/reinitialize.
4. Read `AGENTS.md`, `PROJECT_RULES.md`, `docs/DECISION_REGISTER.md`, `docs/AGENT_AUTONOMY_POLICY.md`, `docs/PROJECT_STATUS.md`, and `docs/MASTER_PROJECT_INITIALIZATION_PROMPT.txt`. Verify which rules are actually loaded by this Antigravity version.
5. Inspect current HOMESETS-only agent permission preset / non-workspace access policy. **Do not enable global Turbo/unrestricted file access**; record which project-scoped Auto/sandbox/deny options are available, and any unavoidable one-time host consent.
6. Double-check repository docs for contradictions against GOV06–GOV11, path/asset provenance, privacy & security, dependency constraints, no backend, safety rules, and new final-only phone test schedule. Document findings in `docs/reviews/`, with raw evidence and severity; propose any sensitive policy change instead of making it.
7. Assess GitHub CI and conditional merge prerequisites. If CI is absent, document its setup plan and the correct Flutter check matrix for the upcoming P0 coding campaign. **Do not pretend missing CI passed**.
8. Check whether the **exact** preferred logo image is actually present locally, with expected dimensions 1254×1254, size 2,018,426 bytes, SHA-256 `95822f54686cc17b7878322dc23607af04a010e073ffd722b91c2bc012d1596b`. If not, record `ASSET_SOURCE_UNAVAILABLE`, continue other safe audit tasks and do not use a lookalike. If yes, commit it unchanged in the reference location with accurate source/hash records (Issue #1).
9. For allowed documentation/provenance corrections only, use a feature branch with short commits, actual diff/format/link checks (`git diff --check`), and optionally a PR. Documentation-only PR may be merged if checks are real and green, no scope or policy decision changes, and GitHub permissions support normal merging. No force push, no branch deletion, no runtime-code merge.
10. Update the status file with **verified facts only**, summarize all substeps and stop.

## Out of scope
Flutter scaffolding/implementation; paid services; dependencies or SDK upgrades; cloud/backend; redesigning the logo; overriding confirmed product/design/training-safety decisions; unrelated repo access; destructive commands; global security bypass; bypassing CI; blind merges.

## Mandatory deliverable
- Absolute workspace path; actual origin/branch/status/root/log outputs.
- Actual Antigravity rule discovery result and permission/preset scope (or `unverified`).
- Verifiable changed files, test/check commands with raw outputs and exit codes, commits, PR/merge link if any.
- Asset checksum verification if exact binary available; otherwise explicit blocker.
- Unresolved issues, priority order, proposed next autonomous campaign (without starting Flutter code).
- Clear DONE/PARTIAL/BLOCKED, no invented results.

## Stop conditions
Wrong repository; non-empty unrelated directory, irreversible data loss, authentication failure requiring manual account setup, unexpected global permissions, required secret/paid service, change to approved product/brand rules, or inability to verify all exact-head checks before merge.

**Execution notice:** GitHub issue creation does not launch the locally installed Antigravity agent. The agent must receive an instruction in the `homesets` workspace once to start this campaign. It may then work continuously within scope.

---

Tracking issue: https://github.com/abuhmaid28/homesets/issues/2
