# HOMESETS — Long-Run Agent Autonomy Protocol (PROPOSED)

Date: 2026-11-14.
**NOT ACTIVE** until the owner reviews how it conflicts with previously confirmed per-milestone phone testing.

## Desired experience
Ahmed stays Product Owner. ChatGPT leads architecture, design review, governance and QA. Antigravity can run **long autonomous campaigns** covering multiple small sub-tasks without routine prompts. A task has internal checkpoints instead of repeated owner approvals.

## Safe autonomy without manual micromanagement
Antigravity may, after owner approval of a campaign:
- Inspect and manage files **inside the HOMESETS repo only**.
- Create/modify documentation, sketches, assets, feature branches and implementation within approved scope.
- Run analyzers, tests, builds, lint and device-independent verification as often as useful.
- Iterate on failing tests without asking each time.
- Commit and push on **feature branches**, update issues/status, prepare PRs.
- Provide an end-of-campaign evidence bundle: real logs, test outputs, diff, commit, APK when relevant.

Never authorize unrelated-project access, deletion of other workspaces, exposing secrets, installing paid dependencies, changing confirmed scope, force pushing, deleting refs, bypassing failed checks, or blind irreversible migrations.

## Merge policy options to make explicit
**Option A (recommended):** auto-merge *documentation-only* PRs when diff checks pass; runtime changes merged only after mechanical tests + product/phone gate. Longer tasks still run between gates.
**Option B (higher risk):** merge implementation PRs with green static/unit/widget/integration CI and no manual phone check; defer phone acceptance to the end. Requires explicit override to D20 and Master §0 rule 2, plus reproducible rollback and careful use of staging/release tags. Device-specific issues discovered late may be expensive to locate.

Important: `allow_auto_merge` currently false for GitHub repo; private GitHub plan may not include platform auto-merge. Antigravity can potentially perform merges via normal Git/GitHub permissions after approval and mechanical gates; this is different from GitHub's built-in auto-merge setting.

## Long campaigns, small internal gates
A campaign can contain many independently testable slices. Example:
- Campaign C0: Git linking + persistent agent rules + logo asset preservation + repo governance verification (**no app code**).
- Campaign C1: brand and UX prototype document drafts / multiple alternatives (**no Flutter code**).
- Campaign C2: architecture plan + deterministic exercise schema and safety test cases (**no code until approved gates**).
- Campaign C3+: bounded implementation slices with tests, commits and report artifacts.

Do not claim that a model/session will reliably work for a fixed number of hours; quotas, model interruptions and tool limits are not under ChatGPT's control.

## Execution guardrails
- Prefer project-specific `Auto` if available and sandboxed; on Windows older builds may show `Always Proceed` instead. Check the exact UI and configuration rather than guessing.
- Restrict non-workspace access; use a deny/ask rule for destructive or external operations.
- Long run should never span a planned owner acceptance gate that hasn't been satisfied.
- If `git remote` is wrong, workspace contains unrelated files, repo permissions fail, assets unavailable, package licensing unclear, or safety assumptions are ambiguous: **STOP and surface one blocker, not repeated questions**.
- Require no secrets, signing keys, paid services, cloud app backend, public publishing or unattended changes to non-HOMESETS repos.

## Current approval status
- **Confirmed owner preference:** avoid repetitive approvals, prefer multi-hour high-autonomy execution, with broad project work delegated.
- **Conflict awaiting informed decision:** per-milestone real-device acceptance (confirmed) versus only final phone test (new preference).
- **Not yet confirmed:** blanket merge authority for all runtime code; still requires selected policy with disclosed consequences.
