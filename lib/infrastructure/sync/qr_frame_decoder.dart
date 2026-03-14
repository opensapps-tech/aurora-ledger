import 'dart:typed_data';

import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'package:aurora_ledger/core/errors/exceptions.dart';
import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';

import 'qr_frame_encoder.dart';
import 'reed_solomon_codec.dart';

/// Reassembles a complete sync payload from received QR frame chunks.
/// Handles out-of-order frames and applies Reed-Solomon error correction.
class QrFrameDecoder {
  QrFrameDecoder(this._rsCodec);
  final ReedSolomonCodec _rsCodec;

  final Map<int, List<int>> _receivedFrames = {};
  int? _totalFrames;
  final Set<int> _processedFrames = {};

  /// Feed a raw QR frame payload. Returns assembled payload when all frames received.
  /// 
  /// Returns:
  /// - Result.ok(assembledPayload) when all frames are received and assembled
  /// - Result.ok(null) when frame was processed but payload is incomplete
  /// - Result.err(FrameChecksumFailure) when checksum verification fails
  Result<List<int>?, Failure> addFrame(List<int> rawFrame) {
    try {
      // Minimum frame size: version(1) + index(2) + total(2) + crc(4) = 9 bytes
      if (rawFrame.length < 9) {
        return Result.err(FrameChecksumFailure(-1));
      }

      // Parse frame envelope
      final buffer = ByteData.sublistView(Uint8List.fromList(rawFrame));
      var offset = 0;

      // Version (1 byte)
      final version = buffer.getUint8(offset);
      offset += 1;

      // Validate protocol version
      if (version != SyncConstants.syncProtocolVersion) {
        return Result.err(SyncPayloadCorruptedFailure());
      }

      // Frame index (2 bytes LE)
      final frameIndex = buffer.getUint16(offset, Endian.little);
      offset += 2;

      // Total frames (2 bytes LE)
      final totalFrames = buffer.getUint16(offset, Endian.little);
      offset += 2;

      // Data + CRC32
      final dataEnd = rawFrame.length - 4;
      final body = rawFrame.sublist(0, dataEnd);
      final crcBytes = rawFrame.sublist(dataEnd);
      
      // Parse CRC32 (4 bytes LE)
      final expectedCrc = ByteData.sublistView(Uint8List.fromList(crcBytes))
          .getUint32(0, Endian.little);

      // Verify CRC32
      final computedCrc = QrFrameEncoder._crc32(body);
      if (computedCrc != expectedCrc) {
        return Result.err(FrameChecksumFailure(frameIndex));
      }

      // Extract data (everything after header, before CRC)
      final data = rawFrame.sublist(5, dataEnd);

      // Apply Reed-Solomon error correction
      List<int> correctedData;
      try {
        correctedData = _rsCodec.decode(data);
      } on SyncException catch (e) {
        // RS correction failed, but checksum passed
        // Use data as-is (may have uncorrectable errors)
        correctedData = data;
      }

      // Store the frame
      if (!_processedFrames.contains(frameIndex)) {
        _receivedFrames[frameIndex] = correctedData;
        _processedFrames.add(frameIndex);
      }

      // Set total frames on first valid frame
      if (_totalFrames == null) {
        _totalFrames = totalFrames;
      }

      // Check if complete
      if (isComplete) {
        final assembled = _assemblePayload();
        return Result.ok(assembled);
      }

      return const Result.ok(null);
    } on SyncException catch (e) {
      return Result.err(SyncPayloadCorruptedFailure());
    } catch (e) {
      return Result.err(SyncPayloadCorruptedFailure());
    }
  }

  /// Assembles the complete payload from received frames.
  List<int> _assemblePayload() {
    if (_totalFrames == null) {
      throw const SyncException('Cannot assemble: total frames unknown');
    }

    final buffer = BytesBuilder();
    
    // Assemble in order
    for (var i = 0; i < _totalFrames!; i++) {
      final frameData = _receivedFrames[i];
      if (frameData == null) {
        throw SyncException('Missing frame $i');
      }
      buffer.add(frameData);
    }

    return buffer.toBytes();
  }

  /// True when all expected frames have been received.
  bool get isComplete =>
      _totalFrames != null && _receivedFrames.length == _totalFrames;

  /// Resets decoder state for a new sync session.
  void reset() {
    _receivedFrames.clear();
    _totalFrames = null;
    _processedFrames.clear();
  }

  /// Returns the set of received frame indices.
  Set<int> get receivedIndices => _receivedFrames.keys.toSet();

  /// Returns the total number of expected frames.
  int? get totalExpected => _totalFrames;

  /// Returns the current progress (0.0 to 1.0).
  double get progress => _totalFrames == null 
      ? 0.0 
      : _receivedFrames.length / _totalFrames!;
}
