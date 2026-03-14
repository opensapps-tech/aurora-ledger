import 'dart:typed_data';

import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'package:aurora_ledger/core/errors/exceptions.dart';
import 'reed_solomon_codec.dart';

/// Splits an encrypted sync payload into QR-displayable frame chunks.
///
/// Pipeline: payload → split into chunks → RS ECC → frame envelopes
/// Each frame envelope contains: [version(1), frameIndex(2), totalFrames(2), payload, checksum(4)]
class QrFrameEncoder {
  const QrFrameEncoder(this._rsCodec);
  final ReedSolomonCodec _rsCodec;

  /// CRC32 lookup table (IEEE 802.3 polynomial: 0xEDB88320)
  static final List<int> _crcTable = _generateCrcTable();

  /// Encodes [payload] into a list of frame byte arrays.
  List<List<int>> encode(List<int> payload) {
    if (payload.isEmpty) {
      throw const SyncException('Cannot encode empty payload');
    }
    
    final chunks = _splitIntoChunks(payload, SyncConstants.targetFramePayloadBytes);
    final totalFrames = chunks.length;
    final frames = <List<int>>[];

    for (var i = 0; i < chunks.length; i++) {
      final eccChunk = _rsCodec.encode(chunks[i]);
      final frame = _buildFrameEnvelope(
        frameIndex: i,
        totalFrames: totalFrames,
        data: eccChunk,
      );
      frames.add(frame);
    }
    
    return frames;
  }

  List<List<int>> _splitIntoChunks(List<int> data, int chunkSize) {
    final chunks = <List<int>>[];
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  List<int> _buildFrameEnvelope({
    required int frameIndex,
    required int totalFrames,
    required List<int> data,
  }) {
    // Format: version(1) | frameIndex(2 LE) | totalFrames(2 LE) | data | CRC32(4 LE)
    final buffer = BytesBuilder();
    
    // Protocol version (1 byte)
    buffer.addByte(SyncConstants.syncProtocolVersion);
    
    // Frame index as uint16 little-endian (2 bytes)
    buffer.add(_uint16LE(frameIndex));
    
    // Total frames as uint16 little-endian (2 bytes)
    buffer.add(_uint16LE(totalFrames));
    
    // Data payload
    buffer.add(data);
    
    // CRC32 of everything except itself (4 bytes, little-endian)
    final body = buffer.toBytes();
    final crc = _crc32(body);
    buffer.add(_uint32LE(crc));
    
    return buffer.toBytes();
  }

  /// Converts an integer to uint16 little-endian bytes.
  List<int> _uint16LE(int value) {
    final data = ByteData(2);
    data.setUint16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Converts an integer to uint32 little-endian bytes.
  List<int> _uint32LE(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Calculates CRC32 checksum.
  static int _crc32(List<int> data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc = (crc >> 8) ^ _crcTable[(crc ^ byte) & 0xFF];
    }
    return ~crc & 0xFFFFFFFF;
  }

  /// Generates CRC32 lookup table.
  static List<int> _generateCrcTable() {
    const polynomial = 0xEDB88320;
    final table = List<int>.filled(256, 0);
    
    for (var i = 0; i < 256; i++) {
      var crc = i;
      for (var j = 0; j < 8; j++) {
        if ((crc & 1) == 1) {
          crc = (crc >> 1) ^ polynomial;
        } else {
          crc >>= 1;
        }
      }
      table[i] = crc;
    }
    
    return table;
  }
}
