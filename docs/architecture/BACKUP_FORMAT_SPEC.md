# HOMESETS — Backup Archive Format, Security & Integrity Specification

**Document Status:** [Active Engineering Architecture]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D02, D18), `docs/PROJECT_RULES.md`  

---

## 1. Export Archive Structure (`.hsbk` / `.zip`)

HOMESETS backups are user-initiated, self-contained ZIP archives carrying a versioned manifest, a cold SQLite database snapshot, and associated sandboxed physique photos:

```text
homesets_backup_20261115_153000.hsbk (ZIP container)
├── manifest.json                  # Schema metadata, timestamps, and file SHA-256 hashes
├── homesets_export.db             # Cold, WAL-checkpointed SQLite database file
└── photos/                        # Sandboxed physique photos
    ├── photo_20261101_front.jpg
    ├── photo_20261108_front.jpg
    └── photo_20261115_front.jpg
```

---

## 2. Manifest Schema (`manifest.json`)

```json
{
  "format_version": 1,
  "app_version": "1.0.0",
  "exported_at_utc": "2026-11-15T13:30:00Z",
  "database_schema_version": 1,
  "database_file": {
    "name": "homesets_export.db",
    "size_bytes": 147456,
    "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  },
  "photos_manifest": [
    {
      "relative_path": "photos/photo_20261101_front.jpg",
      "size_bytes": 412850,
      "sha256": "4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a"
    }
  ],
  "total_uncompressed_bytes": 560306,
  "is_encrypted": false
}
```

---

## 3. Defense Against Malicious or Corrupted Archives

Because users can import backup files from unverified external storage (Downloads, Telegram, USB drives), the import parser enforces strict security boundaries:

### 3.1 Zip-Slip Path Traversal Defense
Malicious archives can contain filenames with directory traversal sequences (e.g. `../../../../system/bin/` or `../../shared_prefs/`).
**Enforced Invariant:**
```dart
// Pseudo-code security boundary in import handler:
for (final file in archive) {
  final destinationFile = File(path.join(stagingDir.path, file.name));
  final canonicalDestination = destinationFile.resolveSymbolicLinksSync();
  final canonicalStaging = stagingDir.resolveSymbolicLinksSync();
  
  if (!canonicalDestination.startsWith(canonicalStaging)) {
    throw SecurityException('ZIP-SLIP ATTEMPT DETECTED: Invalid path traversal: ${file.name}');
  }
}
```

### 3.2 Zip Expansion Bomb Defense
An archive of a few kilobytes can decompress into hundreds of gigabytes, exhausting device storage and crashing the operating system.
**Enforced Caps:**
- `MAX_TOTAL_UNCOMPRESSED_BYTES`: **500 MB** (524,288,000 bytes)
- `MAX_TOTAL_FILES`: **500 files**
- If the uncompressed byte tally exceeds 500 MB during extraction, decompression aborts immediately and staging storage is wiped.

---

## 4. Encryption Architecture: Optional AES-256 vs. Plaintext Export

- **Standard Export (Zero-Password):** Standard ZIP format. Easily inspectable by the user, but carries a prominent in-app warning:
  > *"تحذير أمني: هذا الملف يحتوي على بيانات تمرينك وصورك الخاصة غير مشفرة. إذا قمت برفعه على جوجل درايف أو إرساله عبر تيليجرام، سيكون مرئياً لأي شخص يملك الملف."*
- **Optional Encrypted Export (Future P7 Milestone):** Password-based encryption using standard pure-Dart AES-GCM with PBKDF2 key derivation. Allows users to safely archive backups to cloud storage without exposing naked photos.
