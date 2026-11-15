# HOMESETS — Physique Photo Privacy & Android OS Exposure Audit

**Document Status:** [Active Security Architecture]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Target Platform:** Android 12+ through Android 16 (Honor X9e Pro / MagicOS 10)  
**Authority Reference:** `DECISION_REGISTER.md` (D02, D13, D18, E01, O06), `docs/PROJECT_RULES.md`  

---

## 1. Threat Model & Privacy Requirements

Ahmed uses HOMESETS to document physique transformation photos (D13). Because physique photos are sensitive and private:
- Photos must **NEVER** appear in the general phone gallery (Google Photos, Honor Gallery).
- Photos must **NEVER** be accessible to other installed Android apps (e.g., social media file pickers, WhatsApp gallery view).
- Photos must **NEVER** be silently extracted by automated cloud auto-sync services without the user's explicit, encrypted export.
- **Zero Photos in Git:** In compliance with `PROJECT_RULES.md`, no private physique photos are ever committed to version control.

---

## 2. Android Scoped Storage & Sandbox Enforcement

### 2.1 File Storage Location: `Context.getFilesDir()`
In Flutter, `path_provider` resolves `getApplicationDocumentsDirectory()` directly to the internal app sandbox:
`/data/user/0/com.abuhmaid.homesets/files/physique_photos/`

```text
Android File Hierarchy:
/storage/emulated/0/DCIM/              <--- FORBIDDEN (Publicly visible to all apps)
/storage/emulated/0/Pictures/          <--- FORBIDDEN (Scanned by MediaStore)

/data/user/0/com.abuhmaid.homesets/    <--- ENFORCED APP SANDBOX
└── files/
    ├── homesets.db
    └── physique_photos/
        ├── .nomedia                   <--- Prevents OS media indexers
        ├── photo_20261115_front.jpg
        └── photo_20261115_side.jpg
```

### 2.2 Security Controls:
1. **App-Private Permissions:** Files stored in `files/` have Linux file permissions `0700` (`rwx------`). Other third-party apps running with distinct Linux UIDs receive `EACCES (Permission Denied)` if attempting to read this path on non-rooted devices.
2. **`.nomedia` Sentinel File:** A `.nomedia` file is placed in `physique_photos/` upon app initialization, instructing Android's `MediaScannerService` to skip indexing the directory.
3. **No MediaStore Registration:** The app never calls `MediaStore.Images.Media.insertImage()` or broadcasts `ACTION_MEDIA_SCANNER_SCAN_FILE`.

---

## 3. Android 12+ (API 31+) & Android 16 Data Extraction Rules

### 3.1 Addressing Architecture Blocker §6 (TRUTH-05)
Prior drafts claimed `android:allowBackup="false"` was a "universal guarantee against extraction." 
**This is incorrect on modern Android.**
Starting in Android 12 (API 31), Android decoupled cloud backups from Device-to-Device (D2D) migration. Even if `android:allowBackup="false"` is set, Android D2D transfer tools (such as cable migration or Wi-Fi transfer to a new phone) can still copy internal app data unless explicitly blocked via XML `dataExtractionRules`.

### 3.2 Required Manifest & XML Configuration:

```xml
<!-- AndroidManifest.xml -->
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    ... >
```

```xml
<!-- res/xml/data_extraction_rules.xml -->
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <!-- Block all automatic cloud backups to Google Drive -->
        <exclude path="." />
    </cloud-backup>
    <device-transfer>
        <!-- Block automatic device-to-device unencrypted extraction -->
        <exclude path="." />
    </device-transfer>
</data-extraction-rules>
```

---

## 4. Platform Verification Matrix: Guarantee vs. Assumption vs. Unverified

| Layer | Privacy Claim | Status on Stock Android 12–16 | Status on Honor MagicOS 10 |
| :--- | :--- | :--- | :--- |
| **Sandbox Isolation** | Photos in internal `files/` cannot be read by third-party apps. | **Guaranteed** (Linux kernel UID separation on non-rooted devices). | **Guaranteed** (Standard Android AOSP kernel boundary). |
| **Gallery Invisibility** | Photos do not appear in Google Photos or phone gallery. | **Guaranteed** (Private storage is outside MediaStore query scope). | **Guaranteed** (Verified across standard OEM media scanners). |
| **Cloud Auto-Sync** | Photos are never uploaded to Google Drive auto-backup. | **Guaranteed** via `dataExtractionRules` `<exclude path="." />`. | **Guaranteed** on standard AOSP backup handlers. |
| **Honor OEM Cloud** | Honor MagicOS Cloud Backup does not bypass `dataExtractionRules`. | *Assumption:* Follows AOSP extraction rules. | **UNVERIFIED.** Honor proprietary cloud backup hooks must be physically audited during final release acceptance. |
