# HOMESETS — C2 Source-of-Truth & Governance Preflight Audit

**Document Status:** [Active Preflight Baseline]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Branch:** `campaign/c2-mega-foundation`  
**Base Commit (origin/main):** `e0dc686c44054f38b3a9cf5f425f69628aa43f93`  
**C1 Proposal Reference:** [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5) head `8a0e1cf3eaed81ad51104c44168b97d8ddcfe996`  

---

## 1. Repository Identity & Point-in-Time Verification

Before initiating Campaign C2-MEGA, the local and remote environment state was audited:

- **Git Root:** `C:\Users\TopOne MM\Documents\homesets`
- **Origin Remote:** `https://github.com/abuhmaid28/homesets.git` (Verified fetch & push)
- **Starting Base:** Branch `campaign/c2-mega-foundation` created directly from verified `origin/main` commit `e0dc686`.
- **Tree Status:** 100% clean, zero untracked files, zero dirty modifications.
- **Active Issues Ledger:**
  - Issue #1: `[BLOCKED] Exact reference logo PNG missing from repository` (Status: OPEN / `ASSET_SOURCE_UNAVAILABLE`)
  - Issue #4: `Campaign C1: Product Blueprint, Brand Guidelines, and UX Foundation` (Status: OPEN / Proposed in PR #5)
  - Issue #6: `C1-R: Responsive Polish & Independent QA` (Status: CLOSED as deliverable complete)
  - Issue #7: `C1-V2: 12-Work-Package Visual Directions & Prototype` (Status: CLOSED as deliverable complete)
  - Issue #8: `C2-MEGA: 28-Work-Package Engineering Foundation & CI` (Status: OPEN / Active Campaign)
- **Active Pull Requests Ledger:**
  - PR #3: `Campaign G0-CAMPAIGN-01 Foundation Review` (Status: MERGED to `main` at `9265e6f`)
  - PR #5: `[DRAFT] Campaign C1 / C1-V2 Design Foundation` (Status: OPEN / DRAFT, head `8a0e1cf`, NOT merged)

---

## 2. Multi-Document Authority & Precedence Matrix

In accordance with `AGENTS.md` and `PROJECT_RULES.md`, conflicts across repository documents are governed by strict hierarchy:

```text
[ Level 1: Immutable Baseline ] 
  docs/MASTER_PROJECT_INITIALIZATION_PROMPT.txt (Historical original)
           │
           ▼
[ Level 2: Authoritative Living Registers ]
  docs/DECISION_REGISTER.md (Later explicit Confirmed entries supersede conflicting process rules)
  docs/AGENT_AUTONOMY_POLICY.md (Workflow, guarded merges, final phone acceptance)
  PROJECT_RULES.md (Absolute boundaries, offline privacy, safety invariants)
           │
           ▼
[ Level 3: Status & Roadmaps ]
  docs/PROJECT_STATUS.md
  docs/ROADMAP.md
  docs/MASTER_EXECUTION_PLAN.md
  docs/AUTONOMOUS_DELIVERY_RUNBOOK.md
           │
           ▼
[ Level 4: Proposed Campaigns (Draft PRs) ]
  Draft PR #5 / C1-V2 Drafts (Proposals awaiting Product Owner gate review; NOT approved authority)
```

---

## 3. Detailed Reconciliation & Resolution of Contradictions

The following 8 critical architecture, safety, and governance contradictions were identified during the pre-C2 audit:

| Contradiction / Issue ID | Conflicting Sources | Root Cause Analysis | Binding Resolution for Campaign C2 |
| :--- | :--- | :--- | :--- |
| **TRUTH-01** | `docs/quality/C2_CI_PREFLIGHT.md` (ENG-01) vs `DECISION_REGISTER.md` (D09) | Draft C2 test plan proposed `+1.25kg` load increments for pull-ups. D09 strictly confirms: *"Pull-up bar and resistance bands; no dumbbells, no backpack loading."* | **RESOLVED:** External weight increments (`+1.25kg`) are strictly expunged from all specifications, fixtures, and tests. Pull-up progression is governed solely by bodyweight rep brackets, pause cadence, and band assistance/resistance rungs. |
| **TRUTH-02** | `docs/quality/C2_CI_PREFLIGHT.md` (ENG-05) vs `PROJECT_RULES.md` (§Absolute safety) | Draft ENG-05 suggested auto-substituting lateral raises or band pull-aparts immediately following acute joint pain during overhead pressing. | **RESOLVED:** Violates the stop-first principle. Acute joint pain requires an immediate halt to all provocative loaded work for that kinetic chain. The app must never automatically prescribe an alternate loaded movement on the spot. |
| **TRUTH-03** | `docs/architecture/C2_READINESS_REVIEW.md` vs Algorithmic Determinism (D17) | Draft readiness review claimed `uuid v4` generation is "deterministic". RFC 4122 v4 UUIDs are pseudo-random. | **RESOLVED:** True engine input/output logic must be 100% pure and deterministic. Random UUIDs are restricted strictly to persistence row identification in SQLite, decoupled from plan calculation. |
| **TRUTH-04** | C1-V2 Staged Database Swap vs Filesystem Failure Realities | Draft C1-V2 claimed staging DB swap "guarantees atomicity across photos and database". SQLite WAL mode and multi-file directories do not possess atomic cross-file guarantees under sudden OS power loss. | **RESOLVED:** Replace the unverified "atomicity guarantee" with a resilient, failure-aware two-phase journal and recovery model that explicitly handles crash consistency and rollback. |
| **TRUTH-05** | Android `allowBackup="false"` vs Android 12+ D2D Transfer Rules | Draft stated `allowBackup="false"` provides a universal guarantee against cloud or transfer extraction. | **RESOLVED:** Android 12+ (API 31+) and Android 16 introduce `dataExtractionRules` where device-to-device (D2D) migration bypasses `allowBackup="false"` unless explicitly disabled via XML rules. Both flags must be specified and documented with OEM caveats. |
| **TRUTH-06** | Package candidate `sqlite3_flutter_libs` vs Upstream Deprecation | C1-V2 proposed `sqlite3_flutter_libs ^0.5.24`, which upstream states is obsolete after `sqlite3` 3.x; Drift versions were stale. | **RESOLVED:** Perform an authoritative truth audit of package compatibility on pub.dev. Propose the smallest modern Android-only dependency footprint without installing packages in `pubspec.yaml`. |
| **TRUTH-07** | C1-V2 Visual Directions vs Owner Brand Gate Approval | C1-V2 generated Direction A (Stealth) and Direction B (Kinetic Depth) as proposals on Draft PR #5. | **RESOLVED:** The visual directions remain proposals pending Ahmed's explicit review. Campaign C2 operates strictly within headless engineering specifications and foundation CI, without assuming visual gate approval. |
| **TRUTH-08** | Code Merge Authority vs CI Availability | GOV08 authorizes automatic merge only after exact-head CI passes; no Flutter CI exists yet. | **RESOLVED:** Implementation Flutter code remains prohibited. Campaign C2 establishes a foundation-only GitHub Actions workflow for documentation and fixture validation; Flutter app merges remain blocked. |

---

## 4. Verification Checkpoint

This audit establishes the immutable constraints under which all subsequent C2 work packages will be authored. No unverified assumptions from earlier drafts will be propagated.
