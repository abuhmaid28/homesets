# HOMESETS Campaign P6 — Reliability Mega Campaign Checkpoint & Acceptance Ledger

**Campaign:** P6 (Reliability: Manual Backup/Restore & Local Reminders)  
**Date:** 2026-11-21  
**Master Issue:** [#17](https://github.com/abuhmaid28/homesets/issues/17)  
**Governance Authority:** Confirmed Decisions GOV23 & GOV24  
**Feature Branch:** `campaign/p6-reliability`  
**Base Commit on `main`:** `162854f7832626ba0a32d665796a32d1e9fec5a9`  
**Baseline CI Status:** [Run #44941791205 (SUCCESS)](https://github.com/abuhmaid28/homesets/actions/runs/44941791205)  
**Pull Request:** Draft PR targeting `main` (Pending open)  
**Merge Policy:** GOV08 — Guarded merges only; no merge until independent ChatGPT approval.  

---

## 1. 20-WP Execution Acceptance Matrix

| WP | Focus Area | Status | Deliverables & Verification Evidence |
| :--- | :--- | :--- | :--- |
| **WP01** | Baseline & Repo Preflight | **IN PROGRESS** | Clean branch `campaign/p6-reliability` from verified `main` (`162854f`); baseline CI green (#44941791205); checkpoint established. |
| **WP02** | Architecture & Threat Model | **PENDING** | `docs/architecture/BACKUP_RESTORE_THREAT_MODEL.md` documenting trust boundaries, zip-slip, decompression bombs, and rollback rules. |
| **WP03** | Dependency/License/Permission Packet | **PENDING** | `docs/proposals/P6_DEPENDENCY_AND_PERMISSION_PROPOSAL.md` evaluating `archive`, `crypto`, `flutter_local_notifications`, `POST_NOTIFICATIONS`. |
| **WP04** | Full Data Snapshot Contract | **PENDING** | `lib/domain/backup/backup_models.dart` defining complete P0–P5 snapshot contract across all SQLite tables. |
| **WP05** | Backup Manifest & Integrity Checks | **PENDING** | Deterministic manifest schema, SHA-256 checksums, version checks, file inventory. |
| **WP06** | Bounded Archive Serialization | **PENDING** | Bounded memory/size archive container format, path traversal protection, duplicate entry rejection. |
| **WP07** | Private Photo Inclusion & Consistency | **PENDING** | Inclusion of tracked app-private photos, checksum matching, missing file handling, no gallery leak. |
| **WP08** | Secure Local Export Staging | **PENDING** | Temporary staging in app-private storage, atomic finish, cleanup on error/cancellation. |
| **WP09** | Android Scoped SAF Document Picker | **PENDING** | Storage Access Framework `ACTION_CREATE_DOCUMENT` via platform channel; 0 broad storage permissions. |
| **WP10** | Export UI, Privacy Warning & Copy | **PENDING** | Settings UI, sensitive data privacy disclosure, progress & cancellation, Arabic RTL & English. |
| **WP11** | Backup Import Selection & Validation | **PENDING** | SAF `ACTION_OPEN_DOCUMENT`, hostile archive validation, size/ratio/member bomb checks. |
| **WP12** | Dry-Run Preview & Explicit Consent | **PENDING** | Restore preview dialog with record counts, date, and explicit user confirmation before any data mutation. |
| **WP13** | Transactional SQLite Restoration | **PENDING** | Isolated/transactional restoration with automatic rollback on error; zero corruption to existing DB. |
| **WP14** | Recoverable Photo Restore & 2-Phase Commit | **PENDING** | Staging restored photos, two-resource commit, rollback compensation across DB and filesystem. |
| **WP15** | Restore Failure & Corruption Exercises | **PENDING** | Hostile test suite: truncated, wrong checksums, bombs, path traversal, disk-full, restart recovery. |
| **WP16** | Reminder Settings & Persistence | **PENDING** | Optional daily reminder (default 15:30), toggle, time picker, shame-free Egyptian Arabic & English UX. |
| **WP17** | Android Local Scheduling & Permissions | **PENDING** | Local notification channel, schedule/cancel, permission denied fallback, zero remote push. |
| **WP18** | Timezone, Clock Changes & Limitations | **PENDING** | Daylight savings, clock shift handling; Honor background limitation documented as UNVERIFIED. |
| **WP19** | Full UX, Accessibility & Responsiveness | **PENDING** | 360/390/412dp layouts, 1.5x font scale safety, Egyptian Arabic RTL & English LTR, zero leaks. |
| **WP20** | Two-Round Internal Review, QA & Delivery | **PENDING** | Hostile Security Review + User Journey QA, full analyzer/tests/APK/CI, PR delivery report. |

---

## 2. Technical & Privacy Boundaries (GOV24 & GOV25-PENDING)

1. **Zero Unapproved Dependencies:** Preauthorized lockfile (`intl: ^0.20.1`, `sqflite: ^2.4.6`, `path_provider: ^2.1.6`) remains enforced. Proposal for any additional package will be grouped in WP03.
2. **Zero Unapproved Permissions:** Release `AndroidManifest.xml` currently has 0 permissions.
3. **100% Offline Architecture:** Zero network calls, zero accounts, zero cloud sync, zero analytics SDKs.
4. **Manual-Only Backup:** Backups are user-initiated only; never automatic or written to public storage without explicit user document selection.
5. **Informed Consent for Restore:** Explicit in-app preview dialog and warning required before replacing local data.
6. **Physical Phone Status:** Honor MagicOS 10 physical device testing remains explicitly **UNVERIFIED** until C9 final acceptance gate per GOV07/GOV22.
