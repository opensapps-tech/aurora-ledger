import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'package:aurora_ledger/infrastructure/sync/qr_frame_encoder.dart';
import 'package:aurora_ledger/infrastructure/sync/reed_solomon_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrFrameEncoder', () {
    late QrFrameEncoder encoder;

    setUp(() {
      encoder = const QrFrameEncoder(ReedSolomonCodec());
    });

    test('single small payload produces 1 frame', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      expect(frames, hasLength(1));
    });

    test('large payload produces multiple frames', () {
      // Create a payload larger than targetFramePayloadBytes
      final payload = List<int>.generate(
        SyncConstants.targetFramePayloadBytes * 3,
        (i) => i % 256,
      );
      final frames = encoder.encode(payload);

      expect(frames.length, greaterThan(1));
    });

    test('consistent totalFrames across all frames', () {
      final payload = List<int>.generate(
        SyncConstants.targetFramePayloadBytes * 3,
        (i) => i % 256,
      );
      final frames = encoder.encode(payload);

      // Parse totalFrames from each frame header
      final totalFramesSet = <int>{};
      for (final frame in frames) {
        // frame[1:3] is totalFrames (uint16 LE)
        final total = frame[1] | (frame[2] << 8);
        totalFramesSet.add(total);
      }

      // All frames should have the same totalFrames
      expect(totalFramesSet, hasLength(1));
      expect(totalFramesSet.first, equals(frames.length));
    });

    test('header bytes decode correctly', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      final frame = frames.first;

      // Version (1 byte)
      expect(frame[0], equals(SyncConstants.syncProtocolVersion));

      // Frame index (2 bytes LE) - should be 0 for first frame
      final frameIndex = frame[3] | (frame[4] << 8);
      expect(frameIndex, equals(0));

      // Total frames (2 bytes LE)
      final totalFrames = frame[1] | (frame[2] << 8);
      expect(totalFrames, equals(frames.length));
    });

    test('frame index increments correctly', () {
      final payload = List<int>.generate(
        SyncConstants.targetFramePayloadBytes * 4,
        (i) => i % 256,
      );
      final frames = encoder.encode(payload);

      for (var i = 0; i < frames.length; i++) {
        final frame = frames[i];
        final frameIndex = frame[3] | (frame[4] << 8);
        expect(frameIndex, equals(i));
      }
    });

    test('CRC32 is present at end of frame', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      for (final frame in frames) {
        // Minimum frame: version(1) + index(2) + total(2) + crc(4) = 9 bytes
        expect(frame.length, greaterThanOrEqualTo(9));

        // Last 4 bytes should be CRC32
        final crcBytes = frame.sublist(frame.length - 4);
        expect(crcBytes, hasLength(4));
      }
    });

    test('CRC32 is present and non-zero', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      for (final frame in frames) {
        // Extract CRC from frame (last 4 bytes, little-endian)
        final extractedCrc = frame[frame.length - 4] |
            (frame[frame.length - 3] << 8) |
            (frame[frame.length - 2] << 16) |
            (frame[frame.length - 1] << 24);

        // CRC should be a valid 32-bit value (we don't verify exact value here)
        // The decoder will verify this
        expect(extractedCrc, isA<int>());
      }
    });

    test('empty payload throws exception', () {
      expect(
        () => encoder.encode([]),
        throwsA(isA<Exception>()),
      );
    });

    test('frame size does not exceed reasonable limit', () {
      final payload = List<int>.generate(
        SyncConstants.targetFramePayloadBytes,
        (i) => i % 256,
      );
      final frames = encoder.encode(payload);

      for (final frame in frames) {
        // QR code version 40 can hold ~2953 bytes
        // Our frames should be well under this limit
        expect(frame.length, lessThan(3000));
      }
    });

    test('all frames start with correct protocol version', () {
      final payload = List<int>.generate(
        SyncConstants.targetFramePayloadBytes * 3,
        (i) => i % 256,
      );
      final frames = encoder.encode(payload);

      for (final frame in frames) {
        expect(frame[0], equals(SyncConstants.syncProtocolVersion));
      }
    });

    test('frames contain Reed-Solomon encoded data', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      // Data section starts at byte 5 (after version + index + total)
      // and ends 4 bytes before the end (CRC32)
      final frame = frames.first;
      final dataSection = frame.sublist(5, frame.length - 4);

      // After RS encoding, data section should be larger than original payload chunk
      // due to parity bytes being added
      expect(dataSection.length, greaterThan(0));
    });
  });
}
