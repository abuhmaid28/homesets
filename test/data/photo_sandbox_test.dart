import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/data/services/photo_service.dart';

void main() {
  group('PhotoService & Sandbox Lifecycle Tests (WP07, WP08)', () {
    test('Magic header byte validation recognizes JPEG, PNG, WEBP and rejects invalid files', () {
      // Valid JPEG header
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      expect(PhotoService.isValidImageBytes(jpegBytes), isTrue);

      // Valid PNG header
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(PhotoService.isValidImageBytes(pngBytes), isTrue);

      // Valid WEBP header: RIFF .... WEBP
      final webpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x20, 0x00, 0x00, 0x00, // size
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(PhotoService.isValidImageBytes(webpBytes), isTrue);

      // Invalid text file
      final textBytes = Uint8List.fromList('Hello World'.codeUnits);
      expect(PhotoService.isValidImageBytes(textBytes), isFalse);

      // Too short
      expect(PhotoService.isValidImageBytes(Uint8List.fromList([0xFF, 0xD8])), isFalse);

      // Empty
      expect(PhotoService.isValidImageBytes(Uint8List(0)), isFalse);
    });

    test('MockPhotoService stores, resolves and deletes files in memory', () async {
      final mock = MockPhotoService(mockPickResult: '/tmp/test_image.jpg');

      final picked = await mock.pickPhotoFromGallery();
      expect(picked, equals('/tmp/test_image.jpg'));

      final relativePath = await mock.copyToPrivateSandbox(picked!, 'photo_123');
      expect(relativePath, equals('progress_photos/photo_123.jpg'));
      expect(mock.storedFiles.containsKey(relativePath), isTrue);

      final absPath = await mock.getAbsolutePath(relativePath);
      expect(absPath, contains('photo_123.jpg'));

      // Clean orphan check
      final cleaned = await mock.cleanupOrphanPhotos([relativePath]);
      expect(cleaned, equals(0), reason: 'Valid path was not deleted');

      final cleanedAll = await mock.cleanupOrphanPhotos([]);
      expect(cleanedAll, equals(1), reason: 'Orphan was deleted');
      expect(mock.storedFiles.isEmpty, isTrue);

      // Delete
      mock.storedFiles['progress_photos/test.jpg'] = Uint8List(10);
      final deleted = await mock.deletePrivatePhoto('progress_photos/test.jpg');
      expect(deleted, isTrue);
      expect(mock.storedFiles.isEmpty, isTrue);
    });

    test('Path traversal protection rejects relative paths with .. or outside progress_photos', () async {
      const service = AndroidPhotoService();

      expect(() => service.getAbsolutePath('../secret.txt'), throwsArgumentError);
      expect(() => service.getAbsolutePath('user_profile/pass.txt'), throwsArgumentError);
      expect(() => service.getAbsolutePath('progress_photos/../../etc/passwd'), throwsArgumentError);
      expect(() => service.deletePrivatePhoto('../secret.txt'), throwsArgumentError);
    });

    test('copyToPrivateSandbox rejects non-existent or corrupted files', () async {
      const service = AndroidPhotoService();

      await expectLater(
        () => service.copyToPrivateSandbox('non_existent_path.jpg', 'photo_1'),
        throwsA(isA<FileSystemException>()),
      );

      // Create a temporary non-image file
      final tempDir = Directory.systemTemp.createTempSync('homesets_test');
      try {
        final badFile = File('${tempDir.path}${Platform.pathSeparator}bad.txt');
        badFile.writeAsStringSync('NOT AN IMAGE');

        await expectLater(
          () => service.copyToPrivateSandbox(badFile.path, 'photo_2'),
          throwsA(isA<FormatException>()),
        );
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
