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

  const AndroidPhotoService();

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

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/progress_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final destPath = '${photosDir.path}/$photoId.jpg';
    await stagedFile.copy(destPath);

    // Clean up temporary staged file
    try {
      await stagedFile.delete();
    } catch (_) {}

    return 'progress_photos/$photoId.jpg';
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    _assertSafeRelativePath(relativePath);
    final docsDir = await getApplicationDocumentsDirectory();
    return '${docsDir.path}/$relativePath';
  }

  @override
  Future<bool> deletePrivatePhoto(String relativePath) async {
    _assertSafeRelativePath(relativePath);
    final absPath = await getAbsolutePath(relativePath);
    final file = File(absPath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  @override
  Future<int> cleanupOrphanPhotos(List<String> validRelativePaths) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/progress_photos');
    if (!await photosDir.exists()) return 0;

    final validBasenames = validRelativePaths.map((p) => p.split('/').last).toSet();
    int cleaned = 0;

    await for (final entity in photosDir.list()) {
      if (entity is File) {
        final filename = entity.path.replaceAll('\\', '/').split('/').last;
        if (!validBasenames.contains(filename)) {
          try {
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

/// In-memory and temporary mock for unit and widget testing (WP08, WP10, P5-R02).
class MockPhotoService implements PhotoService {
  final Map<String, Uint8List> storedFiles = {};
  String? mockPickResult;

  MockPhotoService({this.mockPickResult});

  void seedVirtualFile(String relativePath, List<int> bytes) {
    storedFiles[relativePath] = Uint8List.fromList(bytes);
  }

  @override
  Future<String?> pickPhotoFromGallery() async {
    return mockPickResult;
  }

  @override
  Future<String> copyToPrivateSandbox(String stagedPath, String photoId) async {
    // Synthetic JPEG header for valid test mock
    final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    storedFiles['progress_photos/$photoId.jpg'] = sampleBytes;
    return 'progress_photos/$photoId.jpg';
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    return '/mock/sandbox/$relativePath';
  }

  @override
  Future<bool> deletePrivatePhoto(String relativePath) async {
    if (storedFiles.containsKey(relativePath)) {
      storedFiles.remove(relativePath);
      return true;
    }
    return false;
  }

  @override
  Future<int> cleanupOrphanPhotos(List<String> validRelativePaths) async {
    final validSet = validRelativePaths.toSet();
    final initialCount = storedFiles.length;
    storedFiles.removeWhere((key, _) => !validSet.contains(key));
    return initialCount - storedFiles.length;
  }
}
