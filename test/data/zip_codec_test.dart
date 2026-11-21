import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/data/services/zip_codec.dart';

void main() {
  group('ZipCodec Unit Tests', () {
    test('Crc32 computes correct checksum for known strings', () {
      // Known CRC-32: "123456789" -> 0xCBF43926
      final bytes = utf8.encode('123456789');
      final crc = Crc32.compute(bytes);
      expect(crc, equals(0xCBF43926));

      // Empty string -> 0
      expect(Crc32.compute([]), equals(0));
    });

    test('Round-trips entries with STORE (uncompressed)', () {
      final entries = [
        ZipEntry(
          path: 'manifest.json',
          data: Uint8List.fromList(utf8.encode('{"formatVersion":1}')),
        ),
        ZipEntry(
          path: 'data.json',
          data: Uint8List.fromList(utf8.encode('{"userProfile":{"goal":"MUSCLE_BUILDING"}}')),
        ),
        ZipEntry(
          path: 'progress_photos/photo_1.jpg',
          data: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]),
        ),
      ];

      final encoded = ZipCodec.encode(entries, compress: false);
      expect(encoded.length, greaterThan(0));

      final decoded = ZipCodec.decode(encoded);
      expect(decoded.length, equals(3));
      expect(decoded[0].path, equals('manifest.json'));
      expect(utf8.decode(decoded[0].data), equals('{"formatVersion":1}'));
      expect(decoded[1].path, equals('data.json'));
      expect(decoded[2].path, equals('progress_photos/photo_1.jpg'));
      expect(decoded[2].data, equals([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]));
    });

    test('Round-trips entries with DEFLATE (compressed)', () {
      // Create a compressible repetitive string
      final repeatedString = 'HOMESETS_PRIVATE_DATA_REPETITION_' * 100;
      final entries = [
        ZipEntry(
          path: 'large_data.json',
          data: Uint8List.fromList(utf8.encode(repeatedString)),
        ),
      ];

      final encoded = ZipCodec.encode(entries, compress: true);
      // Compressed size should be noticeably smaller than original data
      expect(encoded.length, lessThan(repeatedString.length));

      final decoded = ZipCodec.decode(encoded);
      expect(decoded.length, equals(1));
      expect(decoded[0].path, equals('large_data.json'));
      expect(utf8.decode(decoded[0].data), equals(repeatedString));
    });

    test('Fails on truncated or non-zip bytes', () {
      expect(() => ZipCodec.decode(Uint8List.fromList([1, 2, 3])), throwsFormatException);

      final garbage = Uint8List(100);
      expect(() => ZipCodec.decode(garbage), throwsFormatException);
    });

    test('Fails when CRC-32 is corrupted', () {
      final entries = [
        ZipEntry(
          path: 'test.txt',
          data: Uint8List.fromList(utf8.encode('Hello World')),
        ),
      ];
      final encoded = ZipCodec.encode(entries);

      // Corrupt the data byte inside the archive
      final corrupted = Uint8List.fromList(encoded);
      // Find 'Hello World' and change a character
      final idx = corrupted.indexOf(utf8.encode('Hello')[0]);
      expect(idx, isNonNegative);
      corrupted[idx] = corrupted[idx] ^ 0xFF;

      expect(() => ZipCodec.decode(corrupted), throwsFormatException);
    });
  });
}
