# HOMESETS Backup & Restore Architecture and Threat Model (WP02)

**Campaign:** P6 (Reliability)  
**Date:** 2026-11-21  
**Master Issue:** [#17](https://github.com/abuhmaid28/homesets/issues/17)  
**Governance Authority:** Confirmed Decisions GOV15, GOV21, GOV24  
**Audit Target:** Manual Local Backup/Export & Validated Restoration  

---

## 1. Architectural Principles & Trust Boundaries

HOMESETS is an uncompromisingly private, offline-first calisthenics progression tracker. It does not possess cloud backends, user accounts, analytics, or background synchronizations. All user data—including sensitive physique photos, bodyweight logs, and workout history—resides exclusively on the local Android device.

```
+-----------------------------------------------------------------------------------+
|                              USER DEVICE ENVIRONMENT                              |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                        HOMESETS APP PRIVATE SANDBOX                         |  |
|  |                                                                             |  |
|  |   SQLite Database (v2)              Private Photos Directory                |  |
|  |   - user_profile                    <appDocsDir>/progress_photos/          |  |
|  |   - equipment_inventory               photo_1.jpg                           |  |
|  |   - completed_workout_sessions        photo_2.jpg                           |  |
|  |   - set_logs                                                                |  |
|  |   - active_workout_session          Isolated Backup Staging Area            |  |
|  |   - salvaged_session_archives       <appDocsDir>/backup_staging/            |  |
|  |   - weight_entries                    export_temp/                          |  |
|  |   - progress_photos                   restore_temp/                         |  |
|  |   - daily_meal_checks                                                       |  |
|  |   - reminder_settings                                                       |  |
|  +-----------------------------------------------------------------------------+  |
|                                       ^                                           |
|               User-Initiated Export   |   User-Initiated Import                   |
|               via Android SAF         |   via Android SAF                         |
|               (ACTION_CREATE_DOC)     |   (ACTION_OPEN_DOC)                       |
|                                       v                                           |
|  +-----------------------------------------------------------------------------+  |
|  |                   EXTERNAL STORAGE / USER-CHOSEN LOCATION                   |  |
|  |                                                                             |  |
|  |   homesets_backup_YYYYMMDD_HHMM.homesets (Single Archive Container)          |  |
|  |   - manifest.json (formatVersion, schemaVersion, SHA-256 hashes, file table)|  |
|  |   - data.json (Full P0-P5 JSON snapshot of all SQLite tables)               |  |
|  |   - progress_photos/*.jpg (Sanitized private photo binaries)                |  |
|  +-----------------------------------------------------------------------------+  |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

### Trust Boundary Rules:
1. **Manual-Only Initiation:** Backups are NEVER generated automatically, on timers, or in the background. The user must navigate to Settings and explicitly initiate "Export Backup" or "Restore Backup".
2. **Zero Broad Storage Permissions:** HOMESETS relies strictly on Android's **Storage Access Framework (SAF)** via `ACTION_CREATE_DOCUMENT` and `ACTION_OPEN_DOCUMENT`. The app requests 0 storage permissions (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, or `MANAGE_EXTERNAL_STORAGE`).
3. **External Disclosure:** Once an archive is written to a user-chosen destination (e.g. Downloads, USB drive, Google Drive), it exits the HOMESETS app-private sandbox. Other apps or cloud providers with access to that destination may inspect it. The UI must explicitly warn the user before export.
4. **Untrusted Import Boundary:** Every imported file is treated as **hostile input until proven valid**. An import file must undergo structural, size, checksum, and semantic validation before any existing local database or photo file is touched.
5. **No Blind Data Destruction:** Restoration is destructive to current local state. An in-app dry-run preview is mandatory, and the user must explicitly confirm data replacement.

---

## 2. Threat Modeling & Defense Matrix

| Threat ID | Threat Vector | Risk Level | Attack Description | Architectural Defense Implementation |
| :--- | :--- | :--- | :--- | :--- |
| **THREAT-01** | **Path Traversal / Zip-Slip** | **CRITICAL** | Hostile archive contains file paths with `../`, absolute paths (`/`), Windows drive letters (`C:\`), or arbitrary nested paths designed to overwrite arbitrary app or system files. | **Strict Path Whitelisting:** Entry paths are checked prior to extraction. Only exact matches or prefixes are permitted:<br>1. `manifest.json`<br>2. `data.json`<br>3. `progress_photos/<photo_id>.jpg` (where `<photo_id>` must match regex `^[a-zA-Z0-9_\-]+$` and end with `.jpg`).<br>Any entry containing `..`, backslashes `\`, leading slashes `/`, or unauthorized directories triggers immediate rejection and purge of staging. |
| **THREAT-02** | **Decompression Bomb (Zip Bomb) & Stream Accumulation** | **CRITICAL** | Hostile archive expands massively, exhausting memory or disk. Accumulating output callbacks buffer entire members into heap. | **True Incremental Streaming & Quotas:**<br>1. Max archive container size: **250 MB**.<br>2. Max total uncompressed size: **500 MB**.<br>3. Max single-entry uncompressed: **250 MB**.<br>4. Max compression expansion ratio: **100:1**.<br>5. Max member files: **1,000**.<br>Incremental chunked decompression sink (`_IncrementalDecompressionSink`) writes directly to disk streams without intermediate chunk buffering. Quota, byte limit, and expansion ratio checks run on every chunk as bytes arrive. Output backpressure honored via periodic 2MB flushes. |
| **THREAT-03** | **Data Corruption / Tampering Detection** | **HIGH** | Corrupted download, incomplete transfer, or modified archive members. | **Deterministic Checksum Verification (`homesets-v1-digest`):** `manifest.json` contains 256-bit hexadecimal checksums for `data.json` and photo binaries computed via streaming chunks. During import validation, digests are computed and compared before any commit. Note: This checksum is designed for accidental corruption detection; it is non-cryptographic and does not provide cryptographic authentication. |
| **THREAT-04** | **Schema Incompatibility / Future Version** | **HIGH** | Attempting to restore a backup created by a newer, incompatible app version or an invalid format. | **Strict Version Gates:** `manifest.json` specifies `formatVersion` (current: 1) and `schemaVersion` (current: 2). If `formatVersion > supportedMax` or `schemaVersion > currentAppSchema`, restore fails closed with a clear localized error message without touching local data. |
| **THREAT-05** | **Dangling Photo References** | **HIGH** | `data.json` references a photo ID whose binary file is missing from the archive, or archive contains unreferenced photo binaries. | **Two-Phase Referential Validation:** The validator cross-checks all `progress_photos` table records in `data.json` against the archive's actual photo members. Missing files are flagged in the preview; if photos are missing, restore fails closed unless explicitly reported and handled safely. |
| **THREAT-06** | **Accidental Data Overwrite** | **HIGH** | User initiates restore by mistake, destroying current progression or workouts. | **In-App Dry-Run Preview & Informed Consent:** Restore parses the backup into memory/staging and displays a modal summary (record counts, backup timestamp, app version) with an unmistakable destructive warning. Restoration requires explicit tap of "Replace Data" or "استبدال البيانات". |
| **THREAT-07** | **Partial Restore / Inconsistent State** | **CRITICAL** | App crashes, phone runs out of battery, or disk fills up midway through writing database or photos. | **Two-Resource Transactional Commit:**<br>1. Restore occurs in `<appDocsDir>/backup_staging/`.<br>2. SQLite restoration is wrapped in an atomic `db.transaction(...)`. If any write fails, transaction rolls back cleanly.<br>3. Original photos are preserved in a backup staging swap until the new photos are verified in place.<br>4. Original state is preserved if any failure occurs. |
| **THREAT-08** | **Public Leak of Intimate Physique Photos** | **CRITICAL** | Restored photos leak into public Android Gallery (`DCIM`, `Pictures`) or are indexed by media scanners. | **App-Private Storage Isolation:** Photos are restored strictly to `<appDocsDir>/progress_photos/`. This directory is inside internal app storage, has no `.nomedia` dependency (since media scanner does not index internal app storage), and is explicitly excluded from Android cloud backup and D2D cloning via `data_extraction_rules.xml` and `backup_rules.xml`. |

---

## 3. Archive Container Format Specification (`.homesets`)

A HOMESETS backup is a deterministic compressed archive container with extension `.homesets` (internally adhering to standard ZIP container specifications for universal parser reliability).

### Directory Hierarchy:
```
homesets_backup.homesets
├── manifest.json       (Metadata, format version, SHA-256 hashes, file inventory)
├── data.json           (Complete normalized JSON snapshot of all SQLite tables)
└── progress_photos/    (App-private physique photos)
    ├── photo_1700000001.jpg
    └── photo_1700000002.jpg
```

### Manifest Schema (`manifest.json`):
```json
{
  "formatVersion": 1,
  "appVersion": "1.0.0+1",
  "databaseSchemaVersion": 2,
  "createdAt": "2026-11-21T18:00:00.000Z",
  "devicePlatform": "android",
  "dataSnapshotChecksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "recordCounts": {
    "userProfile": 1,
    "equipmentInventory": 1,
    "completedWorkouts": 14,
    "setLogs": 56,
    "activeSession": 0,
    "salvagedSessions": 1,
    "weightEntries": 28,
    "progressPhotos": 6,
    "dailyMealChecks": 45,
    "reminderSettings": 1
  },
  "files": [
    {
      "relativePath": "progress_photos/photo_1700000001.jpg",
      "byteLength": 1048576,
      "sha256": "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"
    }
  ],
  "totalFilesCount": 1,
  "totalUncompressedBytes": 1153432
}
```

---

## 4. Rollback and Recovery State Machine

```
              [Import File Selected]
                         │
                         ▼
             [Stage in backup_staging/]
                         │
           Hostile Validation Fails
       ┌─────────────────┴─────────────────┐
       ▼                                   ▼
 [Purge Staging]                  [Validation Passes]
 [Leave Existing Data Intact]              │
                                           ▼
                                [Show Dry-Run Preview]
                                           │
                         User Cancels      │ User Confirms
                     ┌─────────────────────┴─────────────────────┐
                     ▼                                           ▼
              [Purge Staging]                        [Begin 2-Phase Commit]
              [No Data Mutated]                                  │
                                                                 ▼
                                                    [SQLite db.transaction]
                                                                 │
                                                 DB Error        │ DB Success
                                             ┌───────────────────┴───────────────────┐
                                             ▼                                       ▼
                                     [Rollback SQLite]                     [Swap Photo Binaries]
                                     [Restore Old State]                             │
                                     [Purge Staging]                  Photo Error    │ Photo Success
                                                                  ┌──────────────────┴──────────────────┐
                                                                  ▼                                     ▼
                                                          [Rollback SQLite]                    [Commit Successful]
                                                          [Revert Photos]                      [Purge Staging]
                                                          [Purge Staging]                      [Reload UI Data]
```
