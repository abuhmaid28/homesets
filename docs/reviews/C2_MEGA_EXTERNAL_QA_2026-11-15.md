# HOMESETS — Independent C2-MEGA Audit (2026-11-15)

**Reviewer:** ChatGPT — independent GitHub evidence and source-file inspection.
**C2 PR:** [Draft #9](https://github.com/abuhmaid28/homesets/pull/9)
**Antigravity original handoff head:** `ae9967e7254548d8ec6519b7a450eb61621bd72c`
**CI repair head:** `c43420af66108584a41cd2b061b13a30db77430e`
**Disposition:** **C2 deliverables submitted and Foundation CI RUNNING/PASS**, but **C2 engineering/safety/fixture acceptance remains BLOCKED pending corrections**. No Flutter production source, no owner design/safety/dependency approval, no app CI, no APK or phone check.

## 1. Independently verified GitHub facts
- Draft PR #9 was open/unmerged; initial 40 files, 5 commits (agent's delivered `ae9967e`).
- Agent initially could not push `.github/workflows/foundation.yml` using local `gh` token lacking `workflow` scope. Source `docs/quality/workflows/foundation.yml` existed but no active workflow.
- ChatGPT used its connected GitHub App (separate from local `gh` OAuth token) to **actually create** `.github/workflows/foundation.yml` on `campaign/c2-mega-foundation`, commit `20994cab3f79f67f858000ce3019cf688e3cab05`. Edited trigger to **PR-only** to limit private-repo CI minute usage.
- First actual GitHub Actions run #43660727324 **failed** because `actions/setup-python@v5` parsed YAML `cache: false` as unsupported string `'false'`. Verified raw job logs.
- ChatGPT removed `cache: false` in commit `c43420af66108584a41cd2b061b13a30db77430e`.
- Second **actual exact-PR-head** [GitHub Actions Run #43660778170](https://github.com/abuhmaid28/homesets/actions/runs/43660778170) had `event=pull_request`, `head_sha=c43420af66108584a41cd2b061b13a30db77430e`, `status=completed`, **`conclusion=success`**. All job steps including fixtures, Markdown links, hygiene and full suite green.
- This is **Foundation Docs/Fixture CI, NOT Flutter app-code CI**. It cannot authorize merging an app implementation PR under GOV08.
- Private repository GitHub Actions consumes included compute minutes and possibly paid overage depending account/billing configuration; no account settings or payment configuration changed. Keep low use, PR-only trigger, 10-minute job limit. See https://docs.github.com/en/actions/concepts/billing-and-usage

## 2. Critical deficits in apparently green fixture audit

**R-C2-01 — Validator checks ID uniqueness, not semantic completeness (High).**
`tools/quality/validate_fixtures.py` only checks presence of seven fields, 100+ count, distinct scenario **IDs** and nonzero positive/negative counts. It does **not** validate IDs/reference integrity, types, outcomes/expected action enums, contradictions or whether examples meaningfully differ. “106 validated” only means minimal syntax/schema hygiene, **NOT 106 exercise-engine behavioral tests**. Add strict relational and semantic validations and actual validator-negative self-tests.

**R-C2-02 — At least two exact scenario input/output duplicates (Medium/High).**
In actual `docs/domain/fixtures/engine_scenarios.json`: `SCEN-089` and `SCEN-093` have identical serialized input_state and expected_output; `SCEN-090` and `SCEN-094` likewise. Different prose descriptions don't make them distinct behavior test vectors. Replace with new, independently testable boundary cases or explicitly classify intentional duplicate and adjust the unique count. Preserve ≥100 *meaningfully distinct* cases.

**R-C2-03 — Test outcomes refer to catalog exercises not defined (High).**
Scenario `SCEN-006` outputs `pushup_decline_feet_elevated`, but catalog lacks it. `SCEN-041` through `SCEN-044` refer to `pushup_band_resisted`, also absent in the 12-exercise catalog. Either define/review equipment-safe catalog entries with prerequisites and safety flags, or rewrite expectations to existing valid entries. Require relational validation both for input and output references.

**R-C2-04 — Equipment/provenance contradictions (High).**
Catalog `pulldown_door_band` requires `door_anchor`, which is NOT in D09 owner's confirmed equipment list (bar+bands only). It may remain **unavailable unless explicitly owned**, never silently scheduled. `row_table_inverted` may require suitable/stable load-bearing furniture, not established safe as “no equipment”; no automatic substitution without explicit suitability. `chinup_neutral` grip type cannot be assumed supported by unspecified pull-up bar. Audit every exercise's real required equipment and support path.
Catalog header simultaneously says “Public Domain Biomechanical Knowledge” and `license: CC-BY-4.0` with no real upstream attribution or proof. These are incompatible provenance claims if used to imply third-party rights. Clearly distinguish **original authored catalog entries**, general exercise facts, and any third-party exercise imagery/video (none licensed yet). Don't invent a public domain/licensed source.

**R-C2-05 — Unsupported scientific/safety guarantees (High).**
`docs/domain/LITE_MODE_SPEC.md` describes a fixed “mathematical proof” and “safety guarantee” that Lite fits 12–15 minutes. Arithmetic is an illustrative estimate based on assumed 40-second sets and 90-second rests; it is **not a real-time upper bound** or guarantee for all users. Remove forced 15-minute ceiling and avoid high-intensity requirement. `docs/domain/SAFETY_INVARIANTS.md` invokes risk of rhabdomyolysis as though the arbitrary 35–50% deload rule were medically validated. Present recovery thresholds and progression speeds as conservative **proposals pending qualified exercise-science/safety review**, not clinical guarantees.

**R-C2-06 — Dependency table still asserts compatibility it did not prove (Medium).**
`docs/architecture/DEPENDENCY_TRUTH_TABLE.md` uses `drift ^2.24.0`, `drift_flutter ^0.2.0`, `flutter_local_notifications ^18.0.1` while earlier review discussed newer versions and potential Android/Gradle differences. Verify exact current candidate package versions and compatibility from package versions/pubspectra and tested `flutter pub get` in a **disposable, approved** later gate, not assumed from generic Dart minimums. Obsolete sqlite3_flutter_libs is correctly excluded (official https://pub.dev/packages/sqlite3_flutter_libs). No package approval yet.

**R-C2-07 — Archive restore and OS backup remain unverified (Medium/High).**
The staged rollback specification is useful but not an implemented transaction across SQLite DB/photos; power-loss behavior, WAL, D2D transfer and OEM behavior have not been tested on actual Android. Keep “failure-aware design” not “guaranteed atomic/zero extraction”. Official Android policy: https://developer.android.com/identity/data/autobackup.

## 3. Must-fix before owner architecture gate
1. Fix R-C2-01–R-C2-05 and re-run strengthened, **mutation-tested** fixture validator in exact-head CI; no false assurance from syntax-only tests.
2. Explicitly distinguish **approved D decisions**, **recommended default** and **unverified/safety proposed** threshold assumptions.
3. Correct overly strong backup/privacy and dependency compatibility claims; no runtime code.
4. Make scenario references and equipment inventory consistent.
5. Update `docs/campaigns/C2-MEGA_CHECKPOINT.md` to note CI is **now active and green at c43420af**; ensure Antigravity fetches latest remote head first to avoid stale-branch overwrite.
6. Deliver one grouped PO decision package. C1 Draft PR #5 visual direction still pending; C2 Draft PR #9 stays unmerged until design/safety/data/dependencies gate.

## 4. Approval boundary
**Technically verified:** PR exists, fixture/links/hygiene CI green **on c43420af**.
**Not verified:** domain correctness, exercise safety, real workout engine/Flutter tests, database backup recovery, Android notification behavior, data-extraction on Honor, logo asset, APK.
**No implementation merge permitted** until actual Flutter CI (not just foundation CI) and relevant owner gates.
