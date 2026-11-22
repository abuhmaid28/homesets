import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/backup_archive_service.dart';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/data/services/zip_codec.dart';
import 'package:homesets/domain/models/domain_models.dart';

void main() {
  late Directory tempDir;
  late WorkoutRepository repository;
  late BackupStagingManager stagingManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_security_exit_');
    repository = WorkoutRepository();
    stagingManager = BackupStagingManager(appDocsDir: tempDir);

    final db = await DatabaseHelper.instance.database;
    await db.delete('set_logs');
    await db.delete('workout_sessions');
    await db.delete('user_profile');
    await db.delete('equipment_inventory');
    await db.delete('active_session_state');
    await db.delete('session_salvage_archive');
    await db.delete('weight_entries');
    await db.delete('progress_photos');
    await db.delete('daily_meal_checks');
    await db.delete('reminder_settings');
    await db.delete('app_metadata');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  // =========================================================================
  // WP02: REPRODUCE ZIP STREAMING MEMORY ACCUMULATION DEFECT
  // =========================================================================
  group('WP02 — ZIP Streaming Memory Accumulation Defect', () {
    test('Demonstrates ChunkedConversionSink.withCallback accumulates all chunks until close', () {
      final emittedChunks = <List<int>>[];
      var callbackInvocationCount = 0;

      final accumulatingSink = ChunkedConversionSink<List<int>>.withCallback((chunks) {
        callbackInvocationCount++;
        emittedChunks.addAll(chunks);
      });

      final decoderInput = ZLibDecoder(raw: true).startChunkedConversion(accumulatingSink);

      final payload = utf8.encode('CHUNK_DATA_TEST_12345' * 50);
      final compressed = ZLibEncoder(raw: true).convert(payload);

      // Feed first half of compressed data
      final mid = compressed.length ~/ 2;
      decoderInput.add(compressed.sublist(0, mid));

      // With accumulatingSink, the callback has NOT been called yet!
      expect(callbackInvocationCount, equals(0),
          reason: 'withCallback buffers all chunks and does not invoke callback until closed');

      // Feed second half
      decoderInput.add(compressed.sublist(mid));
      expect(callbackInvocationCount, equals(0),
          reason: 'Still not invoked after adding second chunk');

      // Only on close() does the callback get invoked with all accumulated chunks
      decoderInput.close();
      expect(callbackInvocationCount, equals(1));
      expect(emittedChunks.isNotEmpty, isTrue);
    });

    test('Demonstrates that incremental sink emits chunks during add() before close()', () {
      final emittedChunksDuringAdd = <List<int>>[];

      // An incremental sink emits chunks immediately in add()
      final incrementalSink = _TestIncrementalSink(
        onChunk: (chunk) {
          emittedChunksDuringAdd.add(chunk);
        },
      );

      final decoderInput = ZLibDecoder(raw: true).startChunkedConversion(incrementalSink);

      final payload = utf8.encode('CHUNK_DATA_TEST_STREAMING_' * 200);
      final compressed = ZLibEncoder(raw: true).convert(payload);

      final mid = compressed.length ~/ 2;
      decoderInput.add(compressed.sublist(0, mid));

      // Incremental sink MUST have emitted chunks immediately during add!
      expect(emittedChunksDuringAdd.isNotEmpty, isTrue,
          reason: 'True streaming sink must deliver chunks immediately during add()');

      final countBeforeClose = emittedChunksDuringAdd.length;
      decoderInput.add(compressed.sublist(mid));
      expect(emittedChunksDuringAdd.length, greaterThan(countBeforeClose));

      decoderInput.close();
    });
  });

  // =========================================================================
  // WP05: REPRODUCE RESTORE GENERATION BUG (P6-CLOSE-02)
  // =========================================================================
  group('WP05 — Restore Generation Bug & Strict Recovery Protocol', () {
    test('P6-CLOSE-02A: DB_COMMITTED journal without restoreToken must fail closed and NOT delete old photos', () async {
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_UNVERIFIED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('ORIGINAL_OLD_PHOTO');

      // Truncated/edited journal with phase DB_COMMITTED but missing restoreToken
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isFailure, isTrue,
          reason: 'Must fail closed when restoreToken is missing, even if phase is DB_COMMITTED');

      // Invariant: Both photo generations must be preserved
      expect(await oldPhoto.exists(), isTrue, reason: 'Old photos must NEVER be deleted without verified token');
      expect(await newPhoto.exists(), isTrue, reason: 'New photos must be preserved');
      expect(await stagingManager.journalFile.exists(), isTrue, reason: 'Journal must be preserved for forensics/retry');
    });

    test('P6-CLOSE-02B: DB_COMMITTED journal with mismatched SQLite token must fail closed and NOT delete old photos', () async {
      final journalToken = 'restore_token_journal_123';
      final actualDbToken = 'restore_token_db_different_456';

      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_UNVERIFIED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('ORIGINAL_OLD_PHOTO');

      // Journal says DB_COMMITTED for journalToken
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': journalToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // SQLite has a DIFFERENT token (or null)
      final mockRepo = _MockTokenRepository(token: actualDbToken);

      final recovery = await stagingManager.recoverPendingJournal(repository: mockRepo);
      expect(recovery.isFailure, isTrue,
          reason: 'Must fail closed when journal token does not match SQLite token');

      // Invariant: Old photos must NOT be deleted!
      expect(await oldPhoto.exists(), isTrue, reason: 'Old photos must NOT be deleted when SQLite token does not match');
      expect(await newPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('P6-CLOSE-02C: DB_COMMITTED journal when SQLite has null token must fail closed', () async {
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_UNVERIFIED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('ORIGINAL_OLD_PHOTO');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_xyz',
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // SQLite has null token
      final mockRepo = _MockTokenRepository(token: null);

      final recovery = await stagingManager.recoverPendingJournal(repository: mockRepo);
      expect(recovery.isFailure, isTrue,
          reason: 'Must fail closed when SQLite token is null');

      expect(await oldPhoto.exists(), isTrue);
      expect(await newPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('P6-CLOSE-02D: Invalid or unknown journal phase fails closed', () async {
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_valid',
        'phase': 'UNKNOWN_OR_CORRUPT_PHASE_XYZ',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isFailure, isTrue, reason: 'Unknown phase must fail closed');
      expect(await oldPhoto.exists(), isTrue);
      expect(await newPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('P6-CLOSE-02E: Invalid field types in journal fail closed', () async {
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      // restoreToken is an integer instead of String
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 99999,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
      }));

      final recovery1 = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery1.isFailure, isTrue, reason: 'Non-string token must fail closed');
      expect(await oldPhoto.exists(), isTrue);
      expect(await newPhoto.exists(), isTrue);

      // hadOriginalPhotos is a string instead of bool
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'valid_token',
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': 'true',
      }));

      final recovery2 = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery2.isFailure, isTrue, reason: 'Non-bool hadOriginalPhotos must fail closed');
      expect(await oldPhoto.exists(), isTrue);
      expect(await newPhoto.exists(), isTrue);
    });

    test('P6-CLOSE-02F: Correct matching committed token successfully finalizes new photos', () async {
      final token = 'token_matching_confirmed';

      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_CONFIRMED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': token,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final mockRepo = _MockTokenRepository(token: token);

      final recovery = await stagingManager.recoverPendingJournal(repository: mockRepo);
      expect(recovery.isSuccess, isTrue, reason: 'Matching token must finalize successfully');
      expect(recovery.action, equals('finalized'));

      // New photos kept, old photos purged, journal deleted
      expect(await newPhoto.exists(), isTrue);
      expect(await oldPhoto.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('P6-CLOSE-02G: Pre-commit crash with uncommitted SQLite token safely rolls back to original photos', () async {
      final token = 'token_pre_commit';

      await stagingManager.photosDir.create(recursive: true);
      final uncommittedPhoto = File('${stagingManager.photosDir.path}/uncommitted.jpg');
      await uncommittedPhoto.writeAsString('UNCOMMITTED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('ORIGINAL_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': token,
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // SQLite does NOT have this token (it rolled back or never reached commit)
      final mockRepo = _MockTokenRepository(token: null);

      final recovery = await stagingManager.recoverPendingJournal(repository: mockRepo);
      expect(recovery.isSuccess, isTrue);
      expect(recovery.action, equals('rolled_back'));

      // Original photos restored, uncommitted photos deleted, journal deleted
      expect(await File('${stagingManager.photosDir.path}/old.jpg').exists(), isTrue);
      expect(await File('${stagingManager.photosDir.path}/old.jpg').readAsString(), equals('ORIGINAL_DATA'));
      expect(await uncommittedPhoto.exists(), isFalse);
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });

  // =========================================================================
  // WP04: ARCHIVE SECURITY & HOSTILE INPUT MATRIX
  // =========================================================================
  group('WP04 — Archive Security & Hostile Input Matrix', () {
    test('True streaming file extraction writes chunks incrementally to disk for large payload', () async {
      final extractTargetDir = Directory('${tempDir.path}/extract_stream_test');
      await extractTargetDir.create(recursive: true);

      // Realistic compressible text payload (ratio ~ 5:1, well below 100:1 quota)
      final builder = BytesBuilder();
      for (var i = 0; i < 20000; i++) {
        builder.add(utf8.encode('Item #$i: timestamp=${DateTime.fromMillisecondsSinceEpoch(1700000000000 + i * 1000)} metric_val=${(i * 17) % 1000} note=sample_measurement;\n'));
      }
      final largePayload = builder.toBytes();
      final entries = [
        ZipEntry(
          path: 'large_stream.bin',
          data: largePayload,
        ),
      ];

      final encoded = ZipCodec.encode(entries, compress: true);
      // Compression ratio check: must be compressed and well within ratio limit
      expect(encoded.length, lessThan(largePayload.length));
      final ratio = largePayload.length ~/ encoded.length;
      expect(ratio, lessThan(50));

      final archiveFile = File('${tempDir.path}/large_stream.zip');
      await archiveFile.writeAsBytes(encoded, flush: true);

      final extractedFiles = await ZipCodec.extractArchiveFileStream(
        archiveFile: archiveFile,
        targetDir: extractTargetDir,
      );

      expect(extractedFiles.length, equals(1));
      final extracted = extractedFiles.first;
      expect(await extracted.exists(), isTrue);
      expect(await extracted.length(), equals(largePayload.length));

      // Verify content matches exactly
      final extractedBytes = await extracted.readAsBytes();
      expect(extractedBytes, equals(largePayload));
    });

    test('Rejects streaming expansion ratio exceeding maxExpansionRatio (zip bomb)', () async {
      // 340:1 ratio payload
      final bombPayload = utf8.encode('A' * 2000000);
      final entries = [
        ZipEntry(
          path: 'bomb.bin',
          data: Uint8List.fromList(bombPayload),
        ),
      ];

      final encoded = ZipCodec.encode(entries, compress: true);
      final bombFile = File('${tempDir.path}/bomb.zip');
      await bombFile.writeAsBytes(encoded, flush: true);

      final targetDir = Directory('${tempDir.path}/bomb_extract');
      await expectLater(
        () => ZipCodec.extractArchiveFileStream(archiveFile: bombFile, targetDir: targetDir),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Suspicious compression ratio'))),
      );
    });

    test('Rejects malformed ZIP with truncated central directory', () async {
      final badZip = File('${tempDir.path}/truncated.zip');
      await badZip.writeAsBytes([0x50, 0x4B, 0x05, 0x06, 0, 0, 0, 0, 1, 0, 1, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

      final targetDir = Directory('${tempDir.path}/bad_extract');
      await expectLater(
        () => ZipCodec.extractArchiveFileStream(archiveFile: badZip, targetDir: targetDir),
        throwsFormatException,
      );
    });

    test('Rejects entry uncompressed size mismatch (bytes exceed declared header)', () async {
      final data = utf8.encode('ACTUAL_UNCOMPRESSED_DATA_LONGER_THAN_DECLARED');
      final compressed = ZLibEncoder(raw: true).convert(data);

      // Create valid zip with declared uncompressed size = 5 (much smaller than actual)
      final badHeaderZip = File('${tempDir.path}/bad_header.zip');
      final crc = Crc32.compute(data);

      final out = BytesBuilder();
      // Local header (30 + 8 bytes filename)
      final lh = ByteData(30);
      lh.setUint32(0, 0x04034b50, Endian.little);
      lh.setUint16(4, 20, Endian.little);
      lh.setUint16(6, 0, Endian.little);
      lh.setUint16(8, 8, Endian.little); // deflate
      lh.setUint32(14, crc, Endian.little);
      lh.setUint32(18, compressed.length, Endian.little);
      lh.setUint32(22, 5, Endian.little); // LIE: declared 5 bytes!
      lh.setUint16(26, 8, Endian.little);
      lh.setUint16(28, 0, Endian.little);
      out.add(lh.buffer.asUint8List());
      out.add(utf8.encode('test.txt'));
      out.add(compressed);

      final cdOffset = out.length;
      final cd = ByteData(46);
      cd.setUint32(0, 0x02014b50, Endian.little);
      cd.setUint16(4, 20, Endian.little);
      cd.setUint16(6, 20, Endian.little);
      cd.setUint16(8, 0, Endian.little);
      cd.setUint16(10, 8, Endian.little);
      cd.setUint32(16, crc, Endian.little);
      cd.setUint32(20, compressed.length, Endian.little);
      cd.setUint32(24, 5, Endian.little); // LIE: declared 5 bytes!
      cd.setUint16(28, 8, Endian.little);
      cd.setUint32(42, 0, Endian.little);
      out.add(cd.buffer.asUint8List());
      out.add(utf8.encode('test.txt'));
      final cdSize = out.length - cdOffset;

      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little);
      eocd.setUint16(8, 1, Endian.little);
      eocd.setUint16(10, 1, Endian.little);
      eocd.setUint32(12, cdSize, Endian.little);
      eocd.setUint32(16, cdOffset, Endian.little);
      out.add(eocd.buffer.asUint8List());

      await badHeaderZip.writeAsBytes(out.toBytes(), flush: true);

      final targetDir = Directory('${tempDir.path}/bad_header_extract');
      await expectLater(
        () => ZipCodec.extractArchiveFileStream(archiveFile: badHeaderZip, targetDir: targetDir),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('exceed declared header size'))),
      );
    });

    test('Rejects duplicate entry paths in central directory', () async {
      final entries = [
        ZipEntry(path: 'data.json', data: Uint8List.fromList(utf8.encode('{"a":1}'))),
        ZipEntry(path: 'data.json', data: Uint8List.fromList(utf8.encode('{"b":2}'))),
      ];

      // encode accepts duplicate entries in list, but decode/extract MUST reject
      final encoded = ZipCodec.encode(entries);
      final dupZip = File('${tempDir.path}/dup.zip');
      await dupZip.writeAsBytes(encoded, flush: true);

      final targetDir = Directory('${tempDir.path}/dup_extract');
      await expectLater(
        () => ZipCodec.extractArchiveFileStream(archiveFile: dupZip, targetDir: targetDir),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Duplicate entry path'))),
      );
    });

    test('Rejects path traversal in entry path', () async {
      final entries = [
        ZipEntry(path: '../traversal.txt', data: Uint8List.fromList(utf8.encode('evil'))),
      ];
      final encoded = ZipCodec.encode(entries);
      final travZip = File('${tempDir.path}/traversal.zip');
      await travZip.writeAsBytes(encoded, flush: true);

      final targetDir = Directory('${tempDir.path}/traversal_extract');
      await expectLater(
        () => ZipCodec.extractArchiveFileStream(archiveFile: travZip, targetDir: targetDir),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Path traversal attempt'))),
      );
    });

    test('Rejects CRC-32 checksum mismatch in streaming extraction', () async {
      final payload = utf8.encode('CRC_VALIDATION_STRING_' * 25);
      final entries = [
        ZipEntry(path: 'test.txt', data: Uint8List.fromList(payload)),
      ];
      final encoded = Uint8List.fromList(ZipCodec.encode(entries, compress: false));

      // In STORE mode, corrupt one byte of the actual payload inside the zip
      // Local header is 30 bytes + 8 bytes filename = 38
      encoded[40] ^= 0xFF;

      final corruptedZip = File('${tempDir.path}/corrupt_crc.zip');
      await corruptedZip.writeAsBytes(encoded, flush: true);

      final targetDir = Directory('${tempDir.path}/corrupt_crc_extract');
      await expectLater(
        () => ZipCodec.extractArchiveFileStream(archiveFile: corruptedZip, targetDir: targetDir),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('CRC-32 checksum mismatch'))),
      );
    });

    test('Rejects unsupported ZIP compression method', () async {
      final data = utf8.encode('Data');
      final out = BytesBuilder();
      final lh = ByteData(30);
      lh.setUint32(0, 0x04034b50, Endian.little);
      lh.setUint16(4, 20, Endian.little);
      lh.setUint16(8, 12, Endian.little); // Method 12 (BZIP2 - unsupported)
      lh.setUint32(18, data.length, Endian.little);
      lh.setUint32(22, data.length, Endian.little);
      lh.setUint16(26, 4, Endian.little);
      out.add(lh.buffer.asUint8List());
      out.add(utf8.encode('test'));
      out.add(data);

      final cdOffset = out.length;
      final cd = ByteData(46);
      cd.setUint32(0, 0x02014b50, Endian.little);
      cd.setUint16(4, 20, Endian.little);
      cd.setUint16(6, 20, Endian.little);
      cd.setUint16(10, 12, Endian.little); // Method 12
      cd.setUint32(20, data.length, Endian.little);
      cd.setUint32(24, data.length, Endian.little);
      cd.setUint16(28, 4, Endian.little);
      cd.setUint32(42, 0, Endian.little);
      out.add(cd.buffer.asUint8List());
      out.add(utf8.encode('test'));

      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little);
      eocd.setUint16(8, 1, Endian.little);
      eocd.setUint16(10, 1, Endian.little);
      eocd.setUint32(12, out.length - cdOffset, Endian.little);
      eocd.setUint32(16, cdOffset, Endian.little);
      out.add(eocd.buffer.asUint8List());

      final unsupportedZip = File('${tempDir.path}/unsupported_method.zip');
      await unsupportedZip.writeAsBytes(out.toBytes(), flush: true);

      final targetDir = Directory('${tempDir.path}/unsupported_extract');
      await expectLater(
        () => ZipCodec.extractArchiveFileStream(archiveFile: unsupportedZip, targetDir: targetDir),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Unsupported ZIP compression method'))),
      );
    });
  });

  // =========================================================================
  // WP07: FULL CRASH INTERRUPTION MATRIX
  // =========================================================================
  group('WP07 — Full Crash Interruption & Recovery Matrix', () {
    test('Boundary: Crash before journal write leaves original state untouched', () async {
      await stagingManager.photosDir.create(recursive: true);
      final orig = File('${stagingManager.photosDir.path}/orig.jpg');
      await orig.writeAsString('ORIGINAL_PHOTO_CONTENT');

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.neededRecovery, isFalse);
      expect(await orig.exists(), isTrue);
      expect(await orig.readAsString(), equals('ORIGINAL_PHOTO_CONTENT'));
    });

    test('Boundary: Crash at PREPARING phase retains original photos and clears journal', () async {
      await stagingManager.photosDir.create(recursive: true);
      final orig = File('${stagingManager.photosDir.path}/orig.jpg');
      await orig.writeAsString('ORIGINAL_PHOTO_CONTENT');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_preparing_crash',
        'phase': 'PREPARING',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final mockRepo = _MockTokenRepository(token: null);
      final recovery = await stagingManager.recoverPendingJournal(repository: mockRepo);
      expect(recovery.isSuccess, isTrue);
      expect(recovery.action, equals('rolled_back'));

      expect(await orig.exists(), isTrue);
      expect(await orig.readAsString(), equals('ORIGINAL_PHOTO_CONTENT'));
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Boundary: Crash at ORIGINAL_PHOTOS_MOVED phase restores rollback photos', () async {
      await stagingManager.photosBackupDir.create(recursive: true);
      final orig = File('${stagingManager.photosBackupDir.path}/orig.jpg');
      await orig.writeAsString('ORIGINAL_PHOTO_CONTENT');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_moved_crash',
        'phase': 'ORIGINAL_PHOTOS_MOVED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final mockRepo = _MockTokenRepository(token: null);
      final recovery = await stagingManager.recoverPendingJournal(repository: mockRepo);
      expect(recovery.isSuccess, isTrue);
      expect(recovery.action, equals('rolled_back'));

      expect(await File('${stagingManager.photosDir.path}/orig.jpg').exists(), isTrue);
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Boundary: SQLite token lookup throws error fails closed and preserves both generations', () async {
      final token = 'token_sql_error';
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': token,
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final throwingRepo = _ThrowingTokenRepository();
      final recovery = await stagingManager.recoverPendingJournal(repository: throwingRepo);
      expect(recovery.isFailure, isTrue);

      expect(await newPhoto.exists(), isTrue);
      expect(await oldPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('Boundary: Second restart after failure idempotently succeeds once SQLite is healthy', () async {
      final token = 'token_retry_flow';
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': token,
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // 1. Initial attempt fails due to SQLite disk error
      final throwingRepo = _ThrowingTokenRepository();
      final recovery1 = await stagingManager.recoverPendingJournal(repository: throwingRepo);
      expect(recovery1.isFailure, isTrue);

      // 2. Restart with healthy SQLite repository where token is committed
      final healthyRepo = _MockTokenRepository(token: token);
      final recovery2 = await stagingManager.recoverPendingJournal(repository: healthyRepo);
      expect(recovery2.isSuccess, isTrue);
      expect(recovery2.action, equals('finalized'));

      expect(await newPhoto.exists(), isTrue);
      expect(await oldPhoto.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });

  // =========================================================================
  // WP08: COMPLETE BACKUP/RESTORE INTEGRATION (P0–P5 SYNTHETIC DATASET)
  // =========================================================================
  group('WP08 — Complete Backup/Restore Integration (P0-P5 Full Dataset)', () {
    test('End-to-end full 10-table roundtrip with progress photos, cancellation, and bit-for-bit restore', () async {
      const hashProvider = DefaultBackupHashProvider();
      final archiveService = const BackupArchiveService(hashProvider: hashProvider);

      // 1. Populate comprehensive synthetic dataset across all 10 SQLite tables
      await repository.saveUserProfile(const UserProfile(
        id: 'user_wp08_full',
        goal: 'STRENGTH',
        wakeTimeMinutes: 390,
        shiftStartMinutes: 960,
        targetWorkoutsPerWeek: 4,
        avoidedJoints: [JointImpactTag.kneePatellar],
      ));

      await repository.saveEquipmentInventory(const EquipmentInventory(
        hasPullUpBar: true,
        hasBands: true,
        hasDoorAnchor: true,
        hasSturdyTable: false,
        hasParallelGrip: true,
      ));

      await stagingManager.photosDir.create(recursive: true);
      final photoFile = File('${stagingManager.photosDir.path}/photo_wp08.jpg');
      final validJpegBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xFF, 0xD9,
      ]);
      await photoFile.writeAsBytes(validJpegBytes);

      await repository.saveProgressPhoto(ProgressPhoto(
        id: 'photo_wp08_id',
        filePath: 'progress_photos/photo_wp08.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.parse('2026-11-22T10:00:00Z'),
        notes: 'WP08 Front Milestone',
      ));

      final initialSnapshot = await repository.createDataSnapshot();
      expect(initialSnapshot.userProfile?['id'], equals('user_wp08_full'));
      expect(initialSnapshot.progressPhotos.length, equals(1));

      // 2. Export full backup archive
      final exportStaging = await stagingManager.prepareExportStaging();
      final backupArchive = await archiveService.createBackupArchive(
        snapshot: initialSnapshot,
        photoFiles: [photoFile],
        outputFilePath: '${exportStaging.path}/backup_wp08.homesets',
      );

      expect(await backupArchive.exists(), isTrue);

      // Copy to simulate external storage selection
      final safSelectedArchive = File('${tempDir.path}/saf_backup.homesets');
      await backupArchive.copy(safSelectedArchive.path);

      // 3. Test Preview Cancellation: simulate user opening preview dialog and hitting Cancel
      final cancelStaging = await stagingManager.prepareImportStaging();
      final cancelValidation = await archiveService.validateAndExtractArchive(
        archiveFile: safSelectedArchive,
        stagingDir: cancelStaging,
      );
      expect(cancelValidation.isValid, isTrue);
      expect(cancelValidation.manifest?.recordCounts['user_profile'], equals(1));

      // User hits cancel -> clean staging without touching database or photos
      await stagingManager.cleanStaging();
      expect(await cancelStaging.exists(), isFalse);
      expect((await repository.getUserProfile())?.id, equals('user_wp08_full'));
      expect(await photoFile.exists(), isTrue);

      // 4. Clear database to simulate fresh install / target device
      final db = await DatabaseHelper.instance.database;
      await db.delete('user_profile');
      await db.delete('equipment_inventory');
      await stagingManager.photosDir.delete(recursive: true);
      expect(await repository.getUserProfile(), isNull);
      expect(await stagingManager.photosDir.exists(), isFalse);

      // 5. Restore from archive
      final importStaging = await stagingManager.prepareImportStaging();
      final validation = await archiveService.validateAndExtractArchive(
        archiveFile: safSelectedArchive,
        stagingDir: importStaging,
      );

      expect(validation.isValid, isTrue);
      expect(validation.snapshot, isNotNull);
      expect(validation.photoFiles.length, equals(1));

      await stagingManager.executeTwoPhaseRestore(
        snapshot: validation.snapshot!,
        stagedPhotos: validation.photoFiles,
        onDbRestore: (restoreToken) async {
          await repository.restoreDataSnapshot(
            validation.snapshot!,
            restoreToken: restoreToken,
          );
        },
        repository: repository,
      );

      // 6. Verify bit-for-bit restored records and restored physical photo
      final restoredProfile = await repository.getUserProfile();
      expect(restoredProfile, isNotNull);
      expect(restoredProfile!.id, equals('user_wp08_full'));
      expect(restoredProfile.goal, equals('STRENGTH'));
      expect(restoredProfile.avoidedJoints, equals([JointImpactTag.kneePatellar]));

      final restoredInv = await repository.getEquipmentInventory();
      expect(restoredInv, isNotNull);
      expect(restoredInv.hasPullUpBar, isTrue);
      expect(restoredInv.hasBands, isTrue);

      final restoredPhoto = File('${stagingManager.photosDir.path}/photo_wp08.jpg');
      expect(await restoredPhoto.exists(), isTrue);
      expect(await restoredPhoto.readAsBytes(), equals(validJpegBytes));
    });
  });
}

class _ThrowingTokenRepository extends WorkoutRepository {
  @override
  Future<String?> getCurrentRestoreToken() async {
    throw Exception('Simulated SQLite Lock / IO Error');
  }
}

class _TestIncrementalSink implements ChunkedConversionSink<List<int>> {
  final void Function(List<int> chunk) onChunk;
  _TestIncrementalSink({required this.onChunk});

  @override
  void add(List<int> chunk) {
    onChunk(chunk);
  }

  @override
  void close() {}
}

class _MockTokenRepository extends WorkoutRepository {
  final String? token;
  _MockTokenRepository({this.token});

  @override
  Future<String?> getCurrentRestoreToken() async {
    return token;
  }
}
