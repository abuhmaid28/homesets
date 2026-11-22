import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Standard CRC-32 calculation (IEEE 802.3).
class Crc32 {
  static final List<int> _table = _initTable();

  static List<int> _initTable() {
    final table = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var c = i;
      for (var k = 0; k < 8; k++) {
        c = (c & 1 != 0) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      }
      table[i] = c;
    }
    return table;
  }

  static int compute(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (var i = 0; i < bytes.length; i++) {
      crc = _table[(crc ^ bytes[i]) & 0xFF] ^ (crc >>> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  static int update(int currentCrc, List<int> bytes) {
    var crc = currentCrc;
    for (var i = 0; i < bytes.length; i++) {
      crc = _table[(crc ^ bytes[i]) & 0xFF] ^ (crc >>> 8);
    }
    return crc;
  }

  static int finalizeCrc(int currentCrc) {
    return (currentCrc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}

/// A file entry inside an in-memory ZIP container.
class ZipEntry {
  final String path;
  final Uint8List data;
  final int compressionMethod; // 0 = STORE, 8 = DEFLATE

  const ZipEntry({
    required this.path,
    required this.data,
    this.compressionMethod = 0,
  });
}

/// A physical file input descriptor for streaming ZIP archive creation (P6-FINAL-05).
class ZipFileInput {
  final String path;
  final File file;

  const ZipFileInput({
    required this.path,
    required this.file,
  });
}

class _ZipEntryDescriptor {
  final String path;
  final int method;
  final int crc;
  final int compressedSize;
  final int uncompressedSize;
  final int localHeaderOffset;

  const _ZipEntryDescriptor({
    required this.path,
    required this.method,
    required this.crc,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.localHeaderOffset,
  });
}

/// Lightweight, zero-dependency ZIP encoder and decoder.
///
/// Encodes with standard STORE (uncompressed) or DEFLATE, and decodes both.
/// Adheres strictly to PKWARE ZIP specification for universal compatibility.
/// Supports bounded O(1) buffer streaming directly to/from disk files (P6-FINAL-05).
class ZipCodec {
  static const int _localHeaderSig = 0x04034b50;
  static const int _centralDirSig = 0x02014b50;
  static const int _eocdSig = 0x06054b50;

  static const int defaultMaxFileCount = 1000;
  static const int defaultMaxArchiveBytes = 250 * 1024 * 1024; // 250 MB
  static const int defaultMaxUncompressedBytes = 500 * 1024 * 1024; // 500 MB
  static const int defaultMaxEntryUncompressedBytes = 250 * 1024 * 1024; // 250 MB
  static const int defaultMaxExpansionRatio = 100;

  /// Streams archive creation directly from disk to output file with bounded O(1) buffer allocations (P6-FINAL-05).
  static Future<void> createArchiveFileStream({
    required File outputFile,
    required List<ZipFileInput> files,
    int maxArchiveBytes = defaultMaxArchiveBytes,
  }) async {
    if (await outputFile.exists()) {
      await outputFile.delete();
    }
    await outputFile.parent.create(recursive: true);

    final outRaf = await outputFile.open(mode: FileMode.write);
    try {
      final cdEntries = <Uint8List>[];
      var currentOffset = 0;

      for (final item in files) {
        final pathBytes = utf8.encode(item.path);
        final fileLength = await item.file.length();

        // Calculate CRC-32 by streaming the file in 64KB chunks
        var runningCrc = 0xFFFFFFFF;
        final readStream = item.file.openRead();
        await for (final chunk in readStream) {
          runningCrc = Crc32.update(runningCrc, chunk);
        }
        final crc = Crc32.finalizeCrc(runningCrc);

        // Write Local File Header (30 bytes + name length)
        final lhData = ByteData(30);
        lhData.setUint32(0, _localHeaderSig, Endian.little);
        lhData.setUint16(4, 20, Endian.little);
        lhData.setUint16(6, 0, Endian.little);
        lhData.setUint16(8, 0, Endian.little); // STORE
        lhData.setUint16(10, 0, Endian.little);
        lhData.setUint16(12, 0, Endian.little);
        lhData.setUint32(14, crc, Endian.little);
        lhData.setUint32(18, fileLength, Endian.little);
        lhData.setUint32(22, fileLength, Endian.little);
        lhData.setUint16(26, pathBytes.length, Endian.little);
        lhData.setUint16(28, 0, Endian.little);

        await outRaf.writeFrom(lhData.buffer.asUint8List());
        await outRaf.writeFrom(pathBytes);

        // Stream file content directly into archive
        final copyStream = item.file.openRead();
        await for (final chunk in copyStream) {
          await outRaf.writeFrom(chunk);
        }

        // Build Central Directory Record (46 bytes + name length)
        final cdData = ByteData(46);
        cdData.setUint32(0, _centralDirSig, Endian.little);
        cdData.setUint16(4, 20, Endian.little);
        cdData.setUint16(6, 20, Endian.little);
        cdData.setUint16(8, 0, Endian.little);
        cdData.setUint16(10, 0, Endian.little);
        cdData.setUint16(12, 0, Endian.little);
        cdData.setUint16(14, 0, Endian.little);
        cdData.setUint32(16, crc, Endian.little);
        cdData.setUint32(20, fileLength, Endian.little);
        cdData.setUint32(24, fileLength, Endian.little);
        cdData.setUint16(28, pathBytes.length, Endian.little);
        cdData.setUint16(30, 0, Endian.little);
        cdData.setUint16(32, 0, Endian.little);
        cdData.setUint16(34, 0, Endian.little);
        cdData.setUint16(36, 0, Endian.little);
        cdData.setUint32(38, 0, Endian.little);
        cdData.setUint32(42, currentOffset, Endian.little);

        final cdEntry = BytesBuilder();
        cdEntry.add(cdData.buffer.asUint8List());
        cdEntry.add(pathBytes);
        cdEntries.add(cdEntry.toBytes());

        currentOffset += 30 + pathBytes.length + fileLength;

        if (currentOffset > maxArchiveBytes) {
          throw FormatException('Archive size limit exceeded during creation ($currentOffset > $maxArchiveBytes bytes)');
        }
      }

      // Write Central Directory block
      final cdOffset = currentOffset;
      var cdTotalSize = 0;
      for (final cdEntry in cdEntries) {
        await outRaf.writeFrom(cdEntry);
        cdTotalSize += cdEntry.length;
      }

      // Write End of Central Directory Record (22 bytes)
      final eocd = ByteData(22);
      eocd.setUint32(0, _eocdSig, Endian.little);
      eocd.setUint16(4, 0, Endian.little);
      eocd.setUint16(6, 0, Endian.little);
      eocd.setUint16(8, files.length, Endian.little);
      eocd.setUint16(10, files.length, Endian.little);
      eocd.setUint32(12, cdTotalSize, Endian.little);
      eocd.setUint32(16, cdOffset, Endian.little);
      eocd.setUint16(20, 0, Endian.little);

      await outRaf.writeFrom(eocd.buffer.asUint8List());
      await outRaf.flush();
      await outRaf.close();
    } catch (e) {
      await outRaf.close();
      try {
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
      } catch (_) {}
      rethrow;
    }
  }

  /// Streams archive extraction directly to disk with bounded O(1) buffer allocations (P6-FINAL-05).
  static Future<List<File>> extractArchiveFileStream({
    required File archiveFile,
    required Directory targetDir,
    int maxFileCount = defaultMaxFileCount,
    int maxArchiveBytes = defaultMaxArchiveBytes,
    int maxUncompressedBytes = defaultMaxUncompressedBytes,
    int maxEntryUncompressedBytes = defaultMaxEntryUncompressedBytes,
    int maxExpansionRatio = defaultMaxExpansionRatio,
  }) async {
    final len = await archiveFile.length();
    if (len > maxArchiveBytes) {
      throw FormatException('Archive exceeds maximum allowed size ($len > $maxArchiveBytes bytes)');
    }
    if (len < 22) {
      throw const FormatException('File too small to be a valid ZIP archive');
    }

    final raf = await archiveFile.open(mode: FileMode.read);
    try {
      // Find EOCD from the back
      final searchLen = len < 65557 ? len : 65557;
      await raf.setPosition(len - searchLen);
      final tailBytes = await raf.read(searchLen);
      final byteData = ByteData.sublistView(tailBytes);

      var eocdRelativeOffset = -1;
      for (var i = searchLen - 22; i >= 0; i--) {
        if (byteData.getUint32(i, Endian.little) == _eocdSig) {
          eocdRelativeOffset = i;
          break;
        }
      }

      if (eocdRelativeOffset == -1) {
        throw const FormatException('ZIP End of Central Directory (EOCD) record not found');
      }

      final totalEntries = byteData.getUint16(eocdRelativeOffset + 10, Endian.little);
      if (totalEntries > maxFileCount) {
        throw FormatException('Archive contains $totalEntries entries, exceeding maximum file count of $maxFileCount');
      }

      final cdSize = byteData.getUint32(eocdRelativeOffset + 12, Endian.little);
      final cdOffset = byteData.getUint32(eocdRelativeOffset + 16, Endian.little);

      if (cdOffset + cdSize > len) {
        throw const FormatException('Corrupt ZIP: Central directory extends beyond archive boundary');
      }

      // Read Central Directory entries
      await raf.setPosition(cdOffset);
      final cdBytes = await raf.read(cdSize);
      if (cdBytes.length != cdSize) {
        throw const FormatException('Corrupt ZIP: Could not read central directory');
      }
      final cdData = ByteData.sublistView(cdBytes);

      final entryDescriptors = <_ZipEntryDescriptor>[];
      final seenPaths = <String>{};
      var cumulativeUncompressed = 0;
      var cdCursor = 0;

      for (var i = 0; i < totalEntries; i++) {
        if (cdCursor + 46 > cdSize) {
          throw const FormatException('Corrupt ZIP: Truncated central directory header');
        }

        final sig = cdData.getUint32(cdCursor, Endian.little);
        if (sig != _centralDirSig) {
          throw FormatException('Invalid central directory signature at offset $cdCursor: 0x${sig.toRadixString(16)}');
        }

        final method = cdData.getUint16(cdCursor + 10, Endian.little);
        final crc = cdData.getUint32(cdCursor + 16, Endian.little);
        final compressedSize = cdData.getUint32(cdCursor + 20, Endian.little);
        final uncompressedSize = cdData.getUint32(cdCursor + 24, Endian.little);
        final nameLen = cdData.getUint16(cdCursor + 28, Endian.little);
        final extraLen = cdData.getUint16(cdCursor + 30, Endian.little);
        final commentLen = cdData.getUint16(cdCursor + 32, Endian.little);
        final localHeaderOffset = cdData.getUint32(cdCursor + 42, Endian.little);

        final nameStart = cdCursor + 46;
        if (nameStart + nameLen > cdSize) {
          throw const FormatException('Corrupt ZIP: Entry path extends beyond central directory');
        }

        final path = utf8.decode(cdBytes.sublist(nameStart, nameStart + nameLen));
        cdCursor += 46 + nameLen + extraLen + commentLen;

        // Threat validations before extracting
        if (path.contains('..') || path.startsWith('/') || path.startsWith('\\') || path.contains(':')) {
          throw FormatException('Path traversal attempt in entry: $path');
        }
        if (!seenPaths.add(path)) {
          throw FormatException('Duplicate entry path in archive: $path');
        }
        if (uncompressedSize > maxEntryUncompressedBytes) {
          throw FormatException('Entry $path uncompressed size ($uncompressedSize) exceeds limit ($maxEntryUncompressedBytes)');
        }
        cumulativeUncompressed += uncompressedSize;
        if (cumulativeUncompressed > maxUncompressedBytes) {
          throw FormatException('Archive cumulative uncompressed size exceeds limit ($maxUncompressedBytes bytes)');
        }
        if (compressedSize > 0 && (uncompressedSize ~/ compressedSize) > maxExpansionRatio) {
          throw FormatException('Suspicious compression ratio (zip bomb) in $path: $uncompressedSize / $compressedSize');
        }

        entryDescriptors.add(_ZipEntryDescriptor(
          path: path,
          method: method,
          crc: crc,
          compressedSize: compressedSize,
          uncompressedSize: uncompressedSize,
          localHeaderOffset: localHeaderOffset,
        ));
      }

      // Stream each entry directly to target directory
      final extractedFiles = <File>[];
      var actualCumulativeUncompressed = 0;
      for (final desc in entryDescriptors) {
        if (desc.localHeaderOffset + 30 > len) {
          throw const FormatException('Corrupt ZIP: Local header offset extends beyond archive');
        }

        await raf.setPosition(desc.localHeaderOffset);
        final lhBytes = await raf.read(30);
        if (lhBytes.length != 30) {
          throw const FormatException('Corrupt ZIP: Could not read local header');
        }
        final lhData = ByteData.sublistView(lhBytes);
        if (lhData.getUint32(0, Endian.little) != _localHeaderSig) {
          throw FormatException('Invalid local header signature at ${desc.localHeaderOffset}');
        }

        final localNameLen = lhData.getUint16(26, Endian.little);
        final localExtraLen = lhData.getUint16(28, Endian.little);
        final dataStart = desc.localHeaderOffset + 30 + localNameLen + localExtraLen;

        if (dataStart + desc.compressedSize > len) {
          throw const FormatException('Corrupt ZIP: Entry data extends beyond archive');
        }

        await raf.setPosition(dataStart);

        final targetFile = File('${targetDir.path}/${desc.path}');
        await targetFile.parent.create(recursive: true);
        final outSink = targetFile.openWrite();

        var computedRunningCrc = 0xFFFFFFFF;
        var uncompressedBytesWritten = 0;

        try {
          if (desc.method == 0) {
            // STORE: Read in 64KB chunks directly into output sink
            var remaining = desc.compressedSize;
            while (remaining > 0) {
              final toRead = remaining < 65536 ? remaining : 65536;
              final chunk = await raf.read(toRead);
              if (chunk.isEmpty) break;
              outSink.add(chunk);
              computedRunningCrc = Crc32.update(computedRunningCrc, chunk);
              uncompressedBytesWritten += chunk.length;
              actualCumulativeUncompressed += chunk.length;
              if (actualCumulativeUncompressed > maxUncompressedBytes) {
                throw FormatException(
                  'Archive cumulative uncompressed size exceeds limit ($maxUncompressedBytes bytes)',
                );
              }
              remaining -= chunk.length;
            }
          } else if (desc.method == 8) {
            // DEFLATE: Stream compressed chunks into ZLibDecoder and write directly to outSink incrementally (P6-CLOSE-01)
            final incrementalSink = _IncrementalDecompressionSink(
              outSink: outSink,
              path: desc.path,
              declaredUncompressedSize: desc.uncompressedSize,
              maxEntryUncompressedBytes: maxEntryUncompressedBytes,
              maxCumulativeBytes: maxUncompressedBytes,
              maxExpansionRatio: maxExpansionRatio,
              onBytesDecompressed: (delta) {
                actualCumulativeUncompressed += delta;
              },
              getCumulativeBytes: () => actualCumulativeUncompressed,
            );
            final decoderInput = ZLibDecoder(raw: true).startChunkedConversion(incrementalSink);

            var remaining = desc.compressedSize;
            var bytesSinceLastFlush = 0;
            while (remaining > 0) {
              final toRead = remaining < 65536 ? remaining : 65536;
              final chunk = await raf.read(toRead);
              if (chunk.isEmpty) break;
              incrementalSink.compressedBytesFed += chunk.length;
              decoderInput.add(chunk);
              remaining -= chunk.length;

              // Honor output backpressure by flushing every 2MB
              if (incrementalSink.bytesWritten - bytesSinceLastFlush >= 2 * 1024 * 1024) {
                await outSink.flush();
                bytesSinceLastFlush = incrementalSink.bytesWritten;
              }
            }
            decoderInput.close();
            uncompressedBytesWritten = incrementalSink.bytesWritten;
            computedRunningCrc = incrementalSink.runningCrc;
          } else {
            throw FormatException('Unsupported ZIP compression method: ${desc.method}');
          }

          await outSink.flush();
          await outSink.close();
        } catch (e) {
          try {
            await outSink.close();
          } catch (_) {}
          rethrow;
        }

        if (uncompressedBytesWritten != desc.uncompressedSize) {
          throw FormatException(
            'Decompressed size mismatch for ${desc.path}: expected ${desc.uncompressedSize}, got $uncompressedBytesWritten',
          );
        }

        final finalCrc = Crc32.finalizeCrc(computedRunningCrc);
        if (finalCrc != desc.crc) {
          throw FormatException(
            'CRC-32 checksum mismatch for ${desc.path}: expected 0x${desc.crc.toRadixString(16)}, got 0x${finalCrc.toRadixString(16)}',
          );
        }

        extractedFiles.add(targetFile);
      }

      await raf.close();
      return extractedFiles;
    } catch (e) {
      await raf.close();
      try {
        if (await targetDir.exists()) {
          await targetDir.delete(recursive: true);
        }
      } catch (_) {}
      rethrow;
    }
  }

  /// Encodes a list of [ZipEntry] items into a standard ZIP archive binary in memory.
  static Uint8List encode(List<ZipEntry> entries, {bool compress = false}) {
    final localHeaders = <Uint8List>[];
    final centralEntries = <Uint8List>[];
    var currentOffset = 0;

    for (final entry in entries) {
      final nameBytes = utf8.encode(entry.path);
      final rawData = entry.data;
      final crc = Crc32.compute(rawData);

      int method;
      Uint8List fileData;
      if (compress && rawData.isNotEmpty) {
        final compressed = Uint8List.fromList(ZLibEncoder(raw: true).convert(rawData));
        if (compressed.length < rawData.length) {
          method = 8;
          fileData = compressed;
        } else {
          method = 0;
          fileData = rawData;
        }
      } else {
        method = 0;
        fileData = rawData;
      }

      // Build Local File Header (30 bytes + name length)
      final localHeader = BytesBuilder();
      final lhData = ByteData(30);
      lhData.setUint32(0, _localHeaderSig, Endian.little);
      lhData.setUint16(4, 20, Endian.little); // version needed
      lhData.setUint16(6, 0, Endian.little); // flags
      lhData.setUint16(8, method, Endian.little); // method
      lhData.setUint16(10, 0, Endian.little); // mod time
      lhData.setUint16(12, 0, Endian.little); // mod date
      lhData.setUint32(14, crc, Endian.little);
      lhData.setUint32(18, fileData.length, Endian.little); // compressed size
      lhData.setUint32(22, rawData.length, Endian.little); // uncompressed size
      lhData.setUint16(26, nameBytes.length, Endian.little);
      lhData.setUint16(28, 0, Endian.little); // extra length

      localHeader.add(lhData.buffer.asUint8List());
      localHeader.add(nameBytes);
      localHeader.add(fileData);

      final localBytes = localHeader.toBytes();
      localHeaders.add(localBytes);

      // Build Central Directory Record (46 bytes + name length)
      final cdData = ByteData(46);
      cdData.setUint32(0, _centralDirSig, Endian.little);
      cdData.setUint16(4, 20, Endian.little); // version made by
      cdData.setUint16(6, 20, Endian.little); // version needed
      cdData.setUint16(8, 0, Endian.little); // flags
      cdData.setUint16(10, method, Endian.little);
      cdData.setUint16(12, 0, Endian.little); // mod time
      cdData.setUint16(14, 0, Endian.little); // mod date
      cdData.setUint32(16, crc, Endian.little);
      cdData.setUint32(20, fileData.length, Endian.little);
      cdData.setUint32(24, rawData.length, Endian.little);
      cdData.setUint16(28, nameBytes.length, Endian.little);
      cdData.setUint16(30, 0, Endian.little); // extra len
      cdData.setUint16(32, 0, Endian.little); // comment len
      cdData.setUint16(34, 0, Endian.little); // disk start
      cdData.setUint16(36, 0, Endian.little); // int attrs
      cdData.setUint32(38, 0, Endian.little); // ext attrs
      cdData.setUint32(42, currentOffset, Endian.little); // local header offset

      final cdBuilder = BytesBuilder();
      cdBuilder.add(cdData.buffer.asUint8List());
      cdBuilder.add(nameBytes);
      centralEntries.add(cdBuilder.toBytes());

      currentOffset += localBytes.length;
    }

    // Build Central Directory block
    final cdOffset = currentOffset;
    final cdBuilder = BytesBuilder();
    for (final b in centralEntries) {
      cdBuilder.add(b);
    }
    final centralDirBytes = cdBuilder.toBytes();

    // Build End of Central Directory Record (22 bytes)
    final eocd = ByteData(22);
    eocd.setUint32(0, _eocdSig, Endian.little);
    eocd.setUint16(4, 0, Endian.little); // disk number
    eocd.setUint16(6, 0, Endian.little); // cd disk
    eocd.setUint16(8, entries.length, Endian.little); // entries this disk
    eocd.setUint16(10, entries.length, Endian.little); // total entries
    eocd.setUint32(12, centralDirBytes.length, Endian.little); // cd size
    eocd.setUint32(16, cdOffset, Endian.little); // cd offset
    eocd.setUint16(20, 0, Endian.little); // comment len

    final out = BytesBuilder();
    for (final lh in localHeaders) {
      out.add(lh);
    }
    out.add(centralDirBytes);
    out.add(eocd.buffer.asUint8List());

    return out.toBytes();
  }

  /// Decodes a ZIP archive binary into a list of [ZipEntry] items in memory.
  static List<ZipEntry> decode(
    Uint8List zipBytes, {
    int maxFileCount = defaultMaxFileCount,
    int maxArchiveBytes = defaultMaxArchiveBytes,
    int maxUncompressedBytes = defaultMaxUncompressedBytes,
    int maxEntryUncompressedBytes = defaultMaxEntryUncompressedBytes,
    int maxExpansionRatio = defaultMaxExpansionRatio,
  }) {
    final len = zipBytes.length;
    if (len > maxArchiveBytes) {
      throw FormatException('Archive exceeds maximum allowed size ($len > $maxArchiveBytes bytes)');
    }
    if (len < 22) {
      throw const FormatException('File too small to be a valid ZIP archive');
    }

    final byteData = ByteData.sublistView(zipBytes);

    var eocdOffset = -1;
    for (var i = len - 22; i >= 0 && i >= len - 65557; i--) {
      if (byteData.getUint32(i, Endian.little) == _eocdSig) {
        eocdOffset = i;
        break;
      }
    }

    if (eocdOffset == -1) {
      throw const FormatException('ZIP End of Central Directory (EOCD) record not found');
    }

    final totalEntries = byteData.getUint16(eocdOffset + 10, Endian.little);
    if (totalEntries > maxFileCount) {
      throw FormatException('Archive contains $totalEntries entries, exceeding maximum file count of $maxFileCount');
    }

    final cdSize = byteData.getUint32(eocdOffset + 12, Endian.little);
    final cdOffset = byteData.getUint32(eocdOffset + 16, Endian.little);

    if (cdOffset + cdSize > len) {
      throw const FormatException('Corrupt ZIP: Central directory extends beyond archive boundary');
    }

    final entries = <ZipEntry>[];
    final seenPaths = <String>{};
    var cumulativeUncompressedBytes = 0;
    var offset = cdOffset;

    for (var i = 0; i < totalEntries; i++) {
      if (offset + 46 > len) {
        throw const FormatException('Corrupt ZIP: Truncated central directory header');
      }

      final sig = byteData.getUint32(offset, Endian.little);
      if (sig != _centralDirSig) {
        throw FormatException('Invalid central directory signature at offset $offset: 0x${sig.toRadixString(16)}');
      }

      final method = byteData.getUint16(offset + 10, Endian.little);
      final crc = byteData.getUint32(offset + 16, Endian.little);
      final compressedSize = byteData.getUint32(offset + 20, Endian.little);
      final uncompressedSize = byteData.getUint32(offset + 24, Endian.little);
      final nameLen = byteData.getUint16(offset + 28, Endian.little);
      final extraLen = byteData.getUint16(offset + 30, Endian.little);
      final commentLen = byteData.getUint16(offset + 32, Endian.little);
      final localHeaderOffset = byteData.getUint32(offset + 42, Endian.little);

      final nameStart = offset + 46;
      if (nameStart + nameLen > len) {
        throw const FormatException('Corrupt ZIP: Entry path extends beyond archive');
      }

      final path = utf8.decode(zipBytes.sublist(nameStart, nameStart + nameLen));
      offset += 46 + nameLen + extraLen + commentLen;

      if (path.contains('..') || path.startsWith('/') || path.startsWith('\\') || path.contains(':')) {
        throw FormatException('Path traversal attempt in entry: $path');
      }
      if (!seenPaths.add(path)) {
        throw FormatException('Duplicate entry path in archive: $path');
      }
      if (uncompressedSize > maxEntryUncompressedBytes) {
        throw FormatException('Entry $path uncompressed size ($uncompressedSize) exceeds limit ($maxEntryUncompressedBytes)');
      }
      cumulativeUncompressedBytes += uncompressedSize;
      if (cumulativeUncompressedBytes > maxUncompressedBytes) {
        throw FormatException('Archive cumulative uncompressed size exceeds limit ($maxUncompressedBytes bytes)');
      }
      if (compressedSize > 0 && (uncompressedSize ~/ compressedSize) > maxExpansionRatio) {
        throw FormatException('Suspicious compression ratio (zip bomb) in $path: $uncompressedSize / $compressedSize');
      }

      if (localHeaderOffset + 30 > len) {
        throw const FormatException('Corrupt ZIP: Local header offset extends beyond archive');
      }

      final localSig = byteData.getUint32(localHeaderOffset, Endian.little);
      if (localSig != _localHeaderSig) {
        throw FormatException('Invalid local header signature at $localHeaderOffset: 0x${localSig.toRadixString(16)}');
      }

      final localNameLen = byteData.getUint16(localHeaderOffset + 26, Endian.little);
      final localExtraLen = byteData.getUint16(localHeaderOffset + 28, Endian.little);
      final dataStart = localHeaderOffset + 30 + localNameLen + localExtraLen;

      if (dataStart + compressedSize > len) {
        throw const FormatException('Corrupt ZIP: File data extends beyond archive');
      }

      final rawBytes = zipBytes.sublist(dataStart, dataStart + compressedSize);
      Uint8List decompressed;

      if (method == 0) {
        decompressed = rawBytes;
      } else if (method == 8) {
        final out = BytesBuilder(copy: false);
        final sink = _IncrementalMemoryDecompressionSink(
          out: out,
          path: path,
          declaredUncompressedSize: uncompressedSize,
        );
        final inputSink = ZLibDecoder(raw: true).startChunkedConversion(sink);
        inputSink.add(rawBytes);
        inputSink.close();
        decompressed = out.toBytes();
      } else {
        throw FormatException('Unsupported ZIP compression method: $method');
      }

      if (decompressed.length != uncompressedSize) {
        throw FormatException(
          'Decompressed size mismatch for $path: expected $uncompressedSize, got ${decompressed.length}',
        );
      }

      final actualCrc = Crc32.compute(decompressed);
      if (actualCrc != crc) {
        throw FormatException(
          'CRC-32 checksum mismatch for $path: expected 0x${crc.toRadixString(16)}, got 0x${actualCrc.toRadixString(16)}',
        );
      }

      entries.add(ZipEntry(
        path: path,
        data: decompressed,
        compressionMethod: method,
      ));
    }

    return entries;
  }
}

/// An incremental chunked decompression sink that streams decompressed bytes directly to disk.
/// Enforces uncompressed bounds, cumulative bounds, and streaming expansion ratios as bytes arrive.
class _IncrementalDecompressionSink implements ChunkedConversionSink<List<int>> {
  final IOSink outSink;
  final String path;
  final int declaredUncompressedSize;
  final int maxEntryUncompressedBytes;
  final int maxCumulativeBytes;
  final int maxExpansionRatio;
  final void Function(int delta) onBytesDecompressed;
  final int Function() getCumulativeBytes;

  int bytesWritten = 0;
  int runningCrc = 0xFFFFFFFF;
  int compressedBytesFed = 0;
  bool isClosed = false;

  _IncrementalDecompressionSink({
    required this.outSink,
    required this.path,
    required this.declaredUncompressedSize,
    required this.maxEntryUncompressedBytes,
    required this.maxCumulativeBytes,
    required this.maxExpansionRatio,
    required this.onBytesDecompressed,
    required this.getCumulativeBytes,
  });

  @override
  void add(List<int> chunk) {
    if (isClosed) {
      throw StateError('Cannot add chunk to closed decompression sink for $path');
    }
    if (chunk.isEmpty) return;

    bytesWritten += chunk.length;

    // Check entry uncompressed bounds immediately as bytes arrive
    if (bytesWritten > declaredUncompressedSize) {
      throw FormatException(
        'Decompressed bytes exceed declared header size in $path ($bytesWritten > $declaredUncompressedSize)',
      );
    }
    if (bytesWritten > maxEntryUncompressedBytes) {
      throw FormatException(
        'Entry $path decompressed size ($bytesWritten) exceeds entry limit ($maxEntryUncompressedBytes)',
      );
    }

    // Check cumulative archive bounds immediately
    onBytesDecompressed(chunk.length);
    if (getCumulativeBytes() > maxCumulativeBytes) {
      throw FormatException(
        'Archive cumulative uncompressed size exceeds limit ($maxCumulativeBytes bytes)',
      );
    }

    // Check streaming expansion ratio for zip-bomb protection
    if (bytesWritten > 1024 * 1024) {
      final effectiveCompressed = compressedBytesFed > 0 ? compressedBytesFed : 1;
      final currentRatio = bytesWritten ~/ effectiveCompressed;
      if (currentRatio > maxExpansionRatio) {
        throw FormatException(
          'Suspicious compression ratio (zip bomb) in $path: $bytesWritten uncompressed from $effectiveCompressed compressed ($currentRatio:1 > $maxExpansionRatio:1)',
        );
      }
    }

    // Direct write to disk stream - zero chunk accumulation in heap
    outSink.add(chunk);
    runningCrc = Crc32.update(runningCrc, chunk);
  }

  @override
  void close() {
    isClosed = true;
  }
}

/// An incremental chunked decompression sink for in-memory byte decoding with bounded heap checks.
class _IncrementalMemoryDecompressionSink implements ChunkedConversionSink<List<int>> {
  final BytesBuilder out;
  final String path;
  final int declaredUncompressedSize;
  int written = 0;
  bool isClosed = false;

  _IncrementalMemoryDecompressionSink({
    required this.out,
    required this.path,
    required this.declaredUncompressedSize,
  });

  @override
  void add(List<int> chunk) {
    if (isClosed) throw StateError('Decompression sink is closed for $path');
    if (chunk.isEmpty) return;

    written += chunk.length;
    if (written > declaredUncompressedSize) {
      throw FormatException('Decompressed bytes exceed declared header size in $path');
    }
    out.add(chunk);
  }

  @override
  void close() {
    isClosed = true;
  }
}
