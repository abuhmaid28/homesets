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
}

/// A file entry inside a ZIP container.
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

/// Lightweight, zero-dependency ZIP encoder and decoder.
///
/// Encodes with standard STORE (uncompressed) or DEFLATE, and decodes both.
/// Adheres strictly to PKWARE ZIP specification for universal compatibility.
class ZipCodec {
  static const int _localHeaderSig = 0x04034b50;
  static const int _centralDirSig = 0x02014b50;
  static const int _eocdSig = 0x06054b50;

  /// Encodes a list of [ZipEntry] items into a standard ZIP archive binary.
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

  /// Decodes a ZIP archive binary into a list of [ZipEntry] items.
  /// Throws [FormatException] on invalid or truncated data.
  static List<ZipEntry> decode(Uint8List zipBytes) {
    final byteData = ByteData.sublistView(zipBytes);
    final len = zipBytes.length;
    if (len < 22) {
      throw const FormatException('File too small to be a valid ZIP archive');
    }

    // Search for End of Central Directory (EOCD) signature from the back
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
    final cdSize = byteData.getUint32(eocdOffset + 12, Endian.little);
    final cdOffset = byteData.getUint32(eocdOffset + 16, Endian.little);

    if (cdOffset + cdSize > len) {
      throw const FormatException('Corrupt ZIP: Central directory extends beyond archive boundary');
    }

    final entries = <ZipEntry>[];
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

      // Read from Local Header to extract file data
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
        decompressed = Uint8List.fromList(ZLibDecoder(raw: true).convert(rawBytes));
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
