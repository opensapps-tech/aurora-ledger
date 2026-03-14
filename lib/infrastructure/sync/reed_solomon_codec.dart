// TODO: Use dart_reed_solomon package (or implement RS(32,24) over GF(256)).
// RS(n=32, k=24): 8 parity bytes per 24 data bytes = 25% overhead.
// Can recover up to 4 erased or corrupted bytes per block.

/// Reed-Solomon encoder/decoder for QR frame error correction.
class ReedSolomonCodec {
  const ReedSolomonCodec();

  static const int _n = 32; // block size
  static const int _k = 24; // data bytes per block

  /// Encodes [data] by appending RS parity bytes.
  List<int> encode(List<int> data) {
    // TODO: implement RS encoding over GF(2^8)
    // Process in blocks of _k bytes, append _n - _k parity bytes per block
    throw UnimplementedError('RS encoding not yet implemented');
  }

  /// Decodes and error-corrects [encoded] data.
  List<int> decode(List<int> encoded) {
    // TODO: implement RS decoding + correction
    throw UnimplementedError('RS decoding not yet implemented');
  }
}
