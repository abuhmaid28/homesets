import 'dart:io';

/// Interface for calculating file and memory checksums.
abstract class BackupHashProvider {
  String computeChecksum(List<int> bytes);
  Future<String> computeFileChecksum(File file);
}

/// Pure Dart deterministic 256-bit checksum implementation: "homesets-v1-digest" (P6-FINAL-07).
///
/// Uses four interleaved 64-bit non-linear rolling hash lanes to produce
/// a 256-bit (64-character hex) digest. Zero dependencies and works on all platforms.
/// Memory-bounded streaming via [computeFileChecksum] avoids loading large files into heap.
class DefaultBackupHashProvider implements BackupHashProvider {
  const DefaultBackupHashProvider();

  @override
  String computeChecksum(List<int> bytes) {
    // 4 independent 64-bit lanes (initialized with fractional golden ratio / primes)
    var h0 = 0x84222325cbbf39f0;
    var h1 = 0x9e3779b97f4a7c15;
    var h2 = 0xbf58476d1ce4e5b9;
    var h3 = 0x94d049bb133111eb;

    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      final lane = i % 4;
      if (lane == 0) {
        h0 = _mix64(h0 ^ b, h3);
      } else if (lane == 1) {
        h1 = _mix64(h1 ^ b, h0);
      } else if (lane == 2) {
        h2 = _mix64(h2 ^ b, h1);
      } else {
        h3 = _mix64(h3 ^ b, h2);
      }
    }

    // Final avalanche mixing
    h0 = _mix64(h0 ^ bytes.length, h1);
    h1 = _mix64(h1, h2);
    h2 = _mix64(h2, h3);
    h3 = _mix64(h3, h0);

    return '${_toHex64(h0)}${_toHex64(h1)}${_toHex64(h2)}${_toHex64(h3)}';
  }

  @override
  Future<String> computeFileChecksum(File file) async {
    var h0 = 0x84222325cbbf39f0;
    var h1 = 0x9e3779b97f4a7c15;
    var h2 = 0xbf58476d1ce4e5b9;
    var h3 = 0x94d049bb133111eb;
    var totalBytes = 0;

    final stream = file.openRead();
    await for (final chunk in stream) {
      for (var i = 0; i < chunk.length; i++) {
        final b = chunk[i];
        final lane = (totalBytes + i) % 4;
        if (lane == 0) {
          h0 = _mix64(h0 ^ b, h3);
        } else if (lane == 1) {
          h1 = _mix64(h1 ^ b, h0);
        } else if (lane == 2) {
          h2 = _mix64(h2 ^ b, h1);
        } else {
          h3 = _mix64(h3 ^ b, h2);
        }
      }
      totalBytes += chunk.length;
    }

    // Final avalanche mixing
    h0 = _mix64(h0 ^ totalBytes, h1);
    h1 = _mix64(h1, h2);
    h2 = _mix64(h2, h3);
    h3 = _mix64(h3, h0);

    return '${_toHex64(h0)}${_toHex64(h1)}${_toHex64(h2)}${_toHex64(h3)}';
  }

  static int _mix64(int h, int k) {
    var v = (h ^ k) & 0xFFFFFFFFFFFFFFFF;
    v = (v ^ (v >>> 30)) * 0xbf58476d1ce4e5b9 & 0xFFFFFFFFFFFFFFFF;
    v = (v ^ (v >>> 27)) * 0x94d049bb133111eb & 0xFFFFFFFFFFFFFFFF;
    return (v ^ (v >>> 31)) & 0xFFFFFFFFFFFFFFFF;
  }

  static String _toHex64(int val) {
    final high = (val >>> 32) & 0xFFFFFFFF;
    final low = val & 0xFFFFFFFF;
    return high.toRadixString(16).padLeft(8, '0') + low.toRadixString(16).padLeft(8, '0');
  }
}
