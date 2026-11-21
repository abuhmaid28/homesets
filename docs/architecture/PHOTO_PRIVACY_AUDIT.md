# HOMESETS Photo Privacy & Storage Architecture Audit (WP11, P5-R01 to P5-R09)

**Date:** 2026-11-21  
**Campaign:** P5 (Progress Tracking) — Post-Review Corrections  
**Author:** Lead Implementation Agent  
**Review Status:** P5-R01 through P5-R09 Implemented — Ready for Independent Lead Review  

---

## 1. Executive Summary

Physique progress photos represent sensitive, intimate user health data. Training at home without external scrutiny requires verifiable, defense-in-depth privacy guarantees. HOMESETS adheres to an uncompromising offline, zero-permission, app-private architecture.

Under decisions **GOV15, GOV16, GOV20, GOV21, and GOV22**, HOMESETS enforces:
1. **0 Android Permissions:** Release `AndroidManifest.xml` retains strictly zero `<uses-permission>` tags.
2. **0 Network Access:** No `INTERNET` permission, zero network calls, zero analytics, telemetry, or remote crash reporting SDKs.
3. **0 Broad Media Permissions:** Photos are selected via Android's native system content selector (`Intent.ACTION_GET_CONTENT` with `CATEGORY_OPENABLE`). The app never requests or receives `READ_EXTERNAL_STORAGE` or `READ_MEDIA_IMAGES`.
4. **Bounded Off-Thread Processing & EXIF Stripping (P5-R01):** Raw inputs are capped at 25 MB, decoded off the main UI thread with `inSampleSize` downsampling to prevent OOM, rotated per EXIF orientation, and re-encoded to clean raster JPEG pixels, completely stripping all EXIF, GPS, camera model, and personal tracking tags.
5. **Two-Phase Lifecycle & Startup Orphan Cleanup (P5-R02):** Atomic compensating rollback deletes any newly copied sandbox file if database insertion fails. Deletions are failure-tolerant, and startup orphan sweeps purge untracked files once database integrity is verified.
6. **Comprehensive Android Backup / Data Extraction Exclusions (P5-R04):** `android:allowBackup="false"`, `android:fullBackupContent="@xml/backup_rules"`, and `android:dataExtractionRules="@xml/data_extraction_rules"` explicitly exclude `database`, `file`, `root`, and `sharedpref` domains from both cloud backup and device-to-device transfers.

---

## 2. Threat Modeling & Defense Verification

| Threat / Attack Vector | Threat Level | Defense Implementation | Verification Status |
| :--- | :--- | :--- | :--- |
| **Broad Storage Permission Leak** | Critical | 0 permissions in manifest. System picker handles image selection out-of-process. | **PASS** |
| **EXIF & GPS Location Leakage** | Critical | Native `Bitmap.compress(JPEG, 90, out)` raster re-encode completely strips all EXIF/GPS metadata tags. | **PASS (P5-R01)** |
| **OOM / Huge Image Crash** | High | Stream capped at 25 MB; `BitmapFactory.Options.inJustDecodeBounds` + `inSampleSize` (max 2048px); background executor. | **PASS (P5-R01)** |
| **Unbounded Dart Heap Consumption** | High | Dart side inspects file size bounds (max 15 MB) and reads only 16-byte magic header stream before copying. | **PASS (P5-R01)** |
| **Orphaned Photo Binary on DB Error** | High | Two-phase photo save with compensating rollback: deletes sandbox file immediately if SQLite insert throws. | **PASS (P5-R02)** |
| **Untracked Photo Residue on Crash** | Medium | Startup orphan cleanup (`cleanupOrphanPhotos`) wired to app initialization in `main.dart` and `ProgressHubScreen`. | **PASS (P5-R02)** |
| **Public Gallery Leakage (DCIM)** | Critical | Photos stored exclusively in private sandbox (`<appDocsDir>/progress_photos/<photoId>.jpg`). | **PASS** |
| **Cloud Backup & D2D Exfiltration** | High | `allowBackup="false"`, `data_extraction_rules.xml` and `backup_rules.xml` exclude `database`, `file`, `root`, `sharedpref`. | **PASS (P5-R04)** |
| **Path Traversal Attacks** | High | Relative paths validated against `progress_photos/`; strictly rejects `..` and external traversal. | **PASS** |
| **Absolute Privacy Overpromise in UI** | Medium | Replaced "100% Private" with truthful localized "App-Private" badge and explicit copy detailing sandbox boundaries. | **PASS (P5-R09)** |

---

## 3. Android Platform Audit & Implementation Details

### 3.1 AndroidManifest.xml Verification

Inspection of `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="homesets"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:fullBackupContent="@xml/backup_rules"
        android:dataExtractionRules="@xml/data_extraction_rules">
        ...
    </application>
</manifest>
```
- **`<uses-permission>` tags:** Exactly **0**.
- **`android:allowBackup`:** `"false"`.
- **`android:fullBackupContent`:** `"@xml/backup_rules"`.
- **`android:dataExtractionRules`:** `"@xml/data_extraction_rules"`.

### 3.2 Data Extraction Rules Across All Domains (`data_extraction_rules.xml` & `backup_rules.xml`)

`android/app/src/main/res/xml/data_extraction_rules.xml` (Android 12+, API 31+):
```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
    </device-transfer>
</data-extraction-rules>
```

`android/app/src/main/res/xml/backup_rules.xml` (Pre-Android 12 fallback):
```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="root" path="." />
    <exclude domain="file" path="." />
    <exclude domain="database" path="." />
    <exclude domain="sharedpref" path="." />
</full-backup-content>
```

> [!NOTE]
> **OEM Device-to-Device Verification Notice:**
> While standard Android platform rules explicitly forbid D2D data extraction across all domains, proprietary OEM migration tools (such as Honor MagicOS Device Clone) operate outside standard Android framework APIs. Full physical device verification remains deferred to the integrated C9 physical acceptance gate (GOV07/GOV22).

### 3.3 Native System Image Selector & EXIF Stripping (`MainActivity.kt`)

Rather than importing unvetted third-party plugins that require broad permissions, HOMESETS utilizes standard Android platform APIs:
- Selection: `Intent.ACTION_GET_CONTENT` with `addCategory(Intent.CATEGORY_OPENABLE)` and `type = "image/*"`.
- Off-Thread Execution: `Executors.newSingleThreadExecutor()` executes bounded stream copying and bitmap compression off the Activity UI thread.
- Bounded Reading: Maximum 25 MB raw input limit. If exceeded, the stream is aborted and temporary files deleted.
- Memory Bounding: `BitmapFactory.Options.inJustDecodeBounds` inspects dimensions. Images larger than 2048px are downsampled via `inSampleSize`.
- EXIF Orientation: Handled via standard `android.media.ExifInterface`.
- Re-Encoding: `Bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)` writes pure raster pixels to a private cache file, stripping all EXIF and GPS tags.

---

## 4. Hardware & Camera Implementation Status (P5-R08)

> [!IMPORTANT]
> **Direct Camera Capture Status: BLOCKED / NOT IMPLEMENTED**
> Under project governance rules (GOV16/GOV21 zero new permissions, zero new dependencies), integrating direct in-app camera capture requires either `android.permission.CAMERA` (strictly prohibited) or delegating to the system camera via `MediaStore.ACTION_IMAGE_CAPTURE` with an `androidx.core.content.FileProvider`. Without adding AndroidX dependencies or device permissions, direct camera capture cannot be safely implemented.
> 
> Therefore, direct camera capture is officially recorded as **BLOCKED / NOT IMPLEMENTED**, and gallery/file selection via `ACTION_GET_CONTENT` is the approved photo input channel.

---

## 5. UI Copy & Truthful Privacy Disclosures (P5-R09)

The Progress Hub AppBar displays the localized badge `l10n.appPrivateBadge` ("App-Private" / "حفظ محلي خاص") rather than an overpromising "100% Private" banner. Tapping the badge opens a disclosure dialog:

> *"App-Private: Copied photos are kept in local offline app storage. Note: Originals in your device gallery or cloud backups are not managed by this app."*
