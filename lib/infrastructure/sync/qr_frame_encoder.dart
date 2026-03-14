import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'reed_solomon_codec.dart';

/// Splits an encrypted sync payload into QR-displayable frame chunks.
///
/// Pipeline: payload → split into chunks → RS ECC → frame envelopes
/// Each frame envelope contains: [version(1), frameIndex(2), totalFrames(2), payload, checksum(4)]
class QrFrameEncoder {
  const QrFrameEncoder(this._rsCodec);
  final ReedSolomonCodec _rsCodec;

  /// Encodes [payload] into a list of frame byte arrays.
  List<List<int>> encode(List<int> payload) {
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
    // TODO: implement frame envelope serialisation
    // Format: version(1) | frameIndex(2 LE) | totalFrames(2 LE) | data | CRC32(4 LE)
    throw UnimplementedError('Frame envelope serialisation not yet implemented');
  }
}
