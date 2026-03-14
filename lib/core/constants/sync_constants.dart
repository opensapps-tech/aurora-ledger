/// QR optical sync pipeline constants.
class SyncConstants {
  SyncConstants._();

  // QR frame sizing
  /// Target payload bytes per frame (80% of QR v40 medium-ECC capacity).
  static const int targetFramePayloadBytes = 1480;
  static const int qrDisplayFps = 4;
  static const int minScanFps = 2;

  // Reed-Solomon: RS(32, 24) = 8 parity bytes per 24 data bytes (25% overhead)
  static const int rsBlockN = 32;
  static const int rsBlockK = 24;

  // Zstandard
  static const int zstdCompressionLevel = 3;
  static const String zstdDictionaryAssetPath = 'assets/zstd_dictionary/aurora_ops.dict';

  // Session
  static const int syncSessionTimeoutSeconds = 120;
  static const int frameRepeatCount = 2;
  static const int syncProtocolVersion = 1;
}
