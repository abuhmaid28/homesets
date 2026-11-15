# C1-V2 — Independent delivery and safety/architecture gate review

**Date:** 2026-11-15
**Source:** GitHub Draft PR #5 head `8a0e1cf3eaed81ad51104c44168b97d8ddcfe996`; latest C1-V2 owner package and C2 technical preflight; actual A/B Today/Workout/Rest PNGs retrieved from GitHub.
**Disposition:** **C1-V2 scoped deliverables were pushed. G1–G5 design approval and G6 safety/privacy/architecture approval remain OPEN.** PR #5 Draft/unmerged.

## Verified scope
- GitHub reports PR #5: 13 commits, 112 changed paths. C1-V2 artifacts include A/B source HTML, offline JS design prototype, screenshot gallery and C2 readiness docs.
- A/B PNGs are actual in-repo screenshots; both directions preserve charcoal/lime preference. These are *proposals*, not approved UI or proof of Flutter behavior.
- No Flutter runtime code, APK or app-code CI proven.

## Issues to resolve before approving C2 production code
1. `docs/quality/C2_CI_PREFLIGHT.md` ENG-01 specifies adding `+1.25kg` external pull-up load despite the confirmed equipment restriction; removed from any future implementation decision. **High — training policy consistency.**
2. ENG-05 auto-prescribes lateral raises/band pull-aparts immediately after joint-pain STOP, contradicting prior stop-first proposal. **High — safety.**
3. ENG-06 defines high-intensity compounds with a strict 15min cap without establishing tolerance; Lite duration is an estimate, safety first. **High.**
4. `docs/architecture/C2_READINESS_REVIEW.md` claims UUID v4 generation is deterministic — incorrect; randomness belongs in persistence ID generation, not plan engine logic. **Medium.**
5. Backup design calls DB swapping and photos `atomic` and Google/cloud protection `guaranteed` without fault-injection/target-device evidence; verify Android 12+ device-transfer and data extraction semantics. **High — privacy/data loss.**
6. Package candidate `sqlite3_flutter_libs ^0.5.24` is obsolete under `sqlite3` 3.x; need current Flutter/Dart/Android compatibility/licensing evidence for a minimal stack. Official: https://pub.dev/packages/sqlite3_flutter_libs, https://pub.dev/packages/drift/versions, https://pub.dev/packages/drift_flutter/versions. **High — dependency correctness.**
7. A/B visual screen captures still show diagnostic labels (`DIRECTION A/B`, `STEALTH-01` / `KINETIC-02`) and mixed technical English in core AR flows. Visual polish required for a *final* branded owner choice; otherwise label clearly as prototypes. **Medium — copy/UX.**
8. Original owner-selected exact Pull-Up PNG is still missing from repo, so no final logo/adaptive icon acceptance. **Blocking for G2.**

## Next campaign
[C2-MEGA Issue #8](https://github.com/abuhmaid28/homesets/issues/8): **28 substantial WPs** on a *separate branch* for architecture decisions, deterministic workout rules + ≥100 negative/positive fixtures, privacy/backup spec, dependency verification, real foundation-only CI and independent QA. **No Flutter production code, no unapproved dependencies, no merge or implied owner approval.** Works independently while PR #5 stays Draft for one grouped Product Owner visual gate.

## Authority and decision status
User strongly prefers long autonomous Antigravity campaigns and final-only phone tests. This preference never silently changes confirmed product equipment, safe training policy, brand selection or dependency approval. No exact runtime-hours can be guaranteed; evidence-driven work and periodic checkpoints are required.
