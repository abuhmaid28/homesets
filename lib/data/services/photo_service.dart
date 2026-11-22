import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Abstract service defining the app-private photo lifecycle (WP07, WP08, P5-R01, P5-R02).
abstract class PhotoService {
  /// Maximum permitted sanitized photo file size (15 MB) to prevent storage exhaustion and OOM.
  static const int maxSanitizedPhotoBytes = 15 * 1024 * 1024;

  /// Launches native system image selector and returns a private staged image path, or null if cancelled.
  Future<String?> pickPhotoFromGallery();

  /// Moves or copies [stagedPath] into the app-private `<appDocsDir>/progress_photos/<photoId>.jpg`
  /// sandbox and returns the relative path (`progress_photos/<photoId>.jpg`).
  Future<String> copyToPrivateSandbox(String stagedPath, String photoId);

  /// Resolves the absolute on-disk path for [relativePath].
  Future<String> getAbsolutePath(String relativePath);

  /// Deletes the private photo file corresponding to [relativePath].
  Future<bool> deletePrivatePhoto(String relativePath);

  /// Removes any unreferenced files in `progress_photos/` that are not listed in [validRelativePaths].
  Future<int> cleanupOrphanPhotos(List<String> validRelativePaths);

  /// Registers an in-flight import to prevent concurrent orphan sweeper races (P5-FINAL-02).
  void markImportPending(String relativePath);

  /// Unregisters an in-flight import once committed to SQLite or rolled back (P5-FINAL-02).
  void completePendingImport(String relativePath);

  static final RegExp canonicalRelativePathPattern =
      RegExp(r'^progress_photos/[a-zA-Z0-9_\-]+\.(jpg|jpeg)$');
  static final RegExp canonicalFilenamePattern =
      RegExp(r'^[a-zA-Z0-9_\-]+\.(jpg|jpeg)$');

  /// Verifies that [path] conforms to the canonical app-private photo relative path:
  /// `progress_photos/<photoId>.(jpg|jpeg)` with no directory traversal, backslashes,
  /// drive letters, URI schemes, or rollback directory references (P6-EXIT-03).
  static bool isValidCanonicalPath(String path) {
    if (path.contains('..') ||
        path.contains('\\') ||
        path.startsWith('/') ||
        path.contains(':') ||
        path.contains('progress_photos_rollback')) {
      return false;
    }
    return canonicalRelativePathPattern.hasMatch(path);
  }

  /// Verifies that [file] exists on disk, is within size bounds (16 bytes to 15 MB),
  /// contains valid image magic header bytes, and for JPEG files, ends with the
  /// End-Of-Image marker (0xFF, 0xD9) to catch truncated, incomplete, or corrupted writes (P6-EXIT-03).
  static Future<bool> isCompleteImageFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length < 16 || length > maxSanitizedPhotoBytes) return false;

      final raf = await file.open(mode: FileMode.read);
      try {
        final header = await raf.read(12);
        if (header.length < 4) return false;

        // JPEG: FF D8 FF
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
          // Check JPEG EOI marker in the final 2 bytes (0xFF, 0xD9)
          await raf.setPosition(length - 2);
          final footer = await raf.read(2);
          if (footer.length == 2 && footer[0] == 0xFF && footer[1] == 0xD9) {
            return true;
          }
          return false; // Truncated or incomplete JPEG
        }

        // PNG: 89 50 4E 47
        if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
          return true;
        }

        // WEBP: RIFF .... WEBP
        if (header.length >= 12 &&
            header[0] == 0x52 &&
            header[1] == 0x49 &&
            header[2] == 0x46 &&
            header[3] == 0x46 &&
            header[8] == 0x57 &&
            header[9] == 0x45 &&
            header[10] == 0x42 &&
            header[11] == 0x50) {
          return true;
        }

        return false;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// Validates magic header bytes (JPEG, PNG, WEBP) to ensure file is a genuine image.
  static bool isValidImageBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    // WEBP: RIFF .... WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }
}

/// Production Android implementation using platform MethodChannel and private directory sandbox.
class AndroidPhotoService implements PhotoService {
  static const MethodChannel _channel = MethodChannel('com.abuhmaid.homesets/media');
  static final Set<String> _pendingImports = <String>{};
  final Future<Directory> Function()? baseDirResolver;
  final Future<void> Function(File source, String destination)? copyOverride;

  const AndroidPhotoService({this.baseDirResolver, this.copyOverride});

  @override
  void markImportPending(String relativePath) {
    _pendingImports.add(relativePath);
  }

  @override
  void completePendingImport(String relativePath) {
    _pendingImports.remove(relativePath);
  }

  @override
  Future<String?> pickPhotoFromGallery() async {
    try {
      final result = await _channel.invokeMethod<String>('pickImage');
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }

  @override
  Future<String> copyToPrivateSandbox(String stagedPath, String photoId) async {
    final relPath = 'progress_photos/$photoId.jpg';
    markImportPending(relPath);

    String? destPath;
    try {
      final stagedFile = File(stagedPath);
      if (!await stagedFile.exists()) {
        throw FileSystemException('Staged file does not exist', stagedPath);
      }

      final length = await stagedFile.length();
      if (length == 0) {
        try {
          await stagedFile.delete();
        } catch (_) {}
        throw const FormatException('Selected image is empty');
      }

      if (length > PhotoService.maxSanitizedPhotoBytes) {
        try {
          await stagedFile.delete();
        } catch (_) {}
        throw const FormatException('File exceeds maximum allowed size of 15MB');
      }

      // Stream-bound header check: only read the first 16 bytes rather than loading the whole file into Dart heap
      final headerChunk = await stagedFile.openRead(0, 16).first;
      if (!PhotoService.isValidImageBytes(headerChunk)) {
        try {
          await stagedFile.delete();
        } catch (_) {}
        throw const FormatException('Invalid image format. Only JPEG, PNG, and WEBP are supported.');
      }

      final docsDir = baseDirResolver != null
          ? await baseDirResolver!()
          : await getApplicationDocumentsDirectory();
      final photosDir = Directory('${docsDir.path}/progress_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      destPath = '${photosDir.path}/$photoId.jpg';
      if (copyOverride != null) {
        await copyOverride!(stagedFile, destPath);
      } else {
        await stagedFile.copy(destPath);
      }

      // Clean up temporary staged file
      try {
        await stagedFile.delete();
      } catch (_) {}

      return relPath;
    } catch (_) {
      completePendingImport(relPath);
      // P5-CLOSE-02: Safely remove any partial private destination file on failure
      if (destPath != null) {
        try {
          final destFile = File(destPath);
          if (await destFile.exists()) {
            await destFile.delete();
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    _assertSafeRelativePath(relativePath);
    final docsDir = baseDirResolver != null
        ? await baseDirResolver!()
        : await getApplicationDocumentsDirectory();
    return '${docsDir.path}/$relativePath';
  }

  @override
  Future<bool> deletePrivatePhoto(String relativePath) async {
    _assertSafeRelativePath(relativePath);
    final absPath = await getAbsolutePath(relativePath);
    final file = File(absPath);
    if (await file.exists()) {
      try {
        await file.delete();
        return true;
      } catch (_) {
        return false;
      }
    }
    return true; // Already deleted / absent from disk
  }

  @override
  Future<int> cleanupOrphanPhotos(List<String> validRelativePaths) async {
    final docsDir = baseDirResolver != null
        ? await baseDirResolver!()
        : await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/progress_photos');
    if (!await photosDir.exists()) return 0;

    final protectedBasenames = {
      ...validRelativePaths,
      ..._pendingImports,
    }.map((p) => p.split('/').last).toSet();

    final now = DateTime.now();
    int cleaned = 0;

    await for (final entity in photosDir.list()) {
      if (entity is File) {
        final filename = entity.path.replaceAll('\\', '/').split('/').last;
        if (!protectedBasenames.contains(filename)) {
          try {
            // P5-FINAL-02: Grace window: only clean files modified at least 60 seconds ago
            final stat = await entity.stat();
            if (now.difference(stat.modified).inSeconds < 60) {
              continue;
            }
            await entity.delete();
            cleaned++;
          } catch (_) {}
        }
      }
    }
    return cleaned;
  }

  void _assertSafeRelativePath(String relativePath) {
    if (!relativePath.startsWith('progress_photos/') || relativePath.contains('..')) {
      throw ArgumentError('Unsafe relative path detected: $relativePath');
    }
  }
}

/// In-memory and temporary mock for unit and widget testing (WP08, WP10, P5-R02, P5-FINAL-01, P5-FINAL-02).
class MockPhotoService implements PhotoService {
  final Map<String, Uint8List> storedFiles = {};
  final Set<String> _pendingImports = {};
  String? mockPickResult;
  bool shouldFailDeletion = false;

  MockPhotoService({this.mockPickResult});

  void seedVirtualFile(String relativePath, List<int> bytes) {
    storedFiles[relativePath] = Uint8List.fromList(bytes);
  }

  @override
  void markImportPending(String relativePath) {
    _pendingImports.add(relativePath);
  }

  @override
  void completePendingImport(String relativePath) {
    _pendingImports.remove(relativePath);
  }

  @override
  Future<String?> pickPhotoFromGallery() async {
    return mockPickResult;
  }

  @override
  Future<String> copyToPrivateSandbox(String stagedPath, String photoId) async {
    final relPath = 'progress_photos/$photoId.jpg';
    markImportPending(relPath);
    // Synthetic JPEG header for valid test mock
    final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    storedFiles[relPath] = sampleBytes;
    return relPath;
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    return '/mock/sandbox/$relativePath';
  }

  @override
  Future<bool> deletePrivatePhoto(String relativePath) async {
    if (shouldFailDeletion) return false;
    if (storedFiles.containsKey(relativePath)) {
      storedFiles.remove(relativePath);
      return true;
    }
    return true; // Already deleted / absent
  }

  @override
  Future<int> cleanupOrphanPhotos(List<String> validRelativePaths) async {
    final protectedSet = {...validRelativePaths, ..._pendingImports}.toSet();
    final initialCount = storedFiles.length;
    storedFiles.removeWhere((key, _) => !protectedSet.contains(key));
    return initialCount - storedFiles.length;
  }
}
