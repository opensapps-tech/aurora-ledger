import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'reed_solomon_codec.dart';

/// Reassembles a complete sync payload from received QR frame chunks.
/// Handles out-of-order frames and applies Reed-Solomon error correction.
class QrFrameDecoder {
  QrFrameDecoder(this._rsCodec);
  final ReedSolomonCodec _rsCodec;

  final Map<int, List<int>> _receivedFrames = {};
  int? _totalFrames;

  /// Feed a raw QR frame payload. Returns assembled payload when all frames received.
  Result<List<int>?, Failure> addFrame(List<int> rawFrame) {
    // TODO: parse frame envelope, verify checksum, apply RS correction
    // Update _receivedFrames and _totalFrames
    // Return Result.ok(null) if incomplete, Result.ok(assembled) when done
    throw UnimplementedError('Frame decoding not yet implemented');
  }

  /// True when all expected frames have been received.
  bool get isComplete =>
      _totalFrames != null && _receivedFrames.length == _totalFrames;

  /// Resets decoder state for a new sync session.
  void reset() {
    _receivedFrames.clear();
    _totalFrames = null;
  }

  Set<int> get receivedIndices => _receivedFrames.keys.toSet();
  int? get totalExpected => _totalFrames;
  double get progress => _totalFrames == null ? 0.0 : _receivedFrames.length / _totalFrames!;
}
