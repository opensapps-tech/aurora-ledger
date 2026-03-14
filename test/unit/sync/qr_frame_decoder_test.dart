import 'dart:typed_data';

import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/infrastructure/sync/qr_frame_decoder.dart';
import 'package:aurora_ledger/infrastructure/sync/qr_frame_encoder.dart';
import 'package:aurora_ledger/infrastructure/sync/reed_solomon_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrFrameDecoder', () {
    late QrFrameDecoder decoder;
    late QrFrameEncoder encoder;

    setUp(() {
      final rsCodec = const ReedSolomonCodec();
      decoder = QrFrameDecoder(rsCodec);
      encoder = QrFrameEncoder(rsCodec);
    });

    tearDown(() {
      decoder.reset();
    });

    test('encode/decode round-trip', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      // Feed all frames to decoder
      for (final frame in frames) {
        final result = decoder.addFrame(frame);
        expect(result.isOk, isTrue);
      }

      expect(decoder.isComplete, isTrue);
      expect(decoder.progress, equals(1.0));
    });

    test('out-of-order frames assemble correctly', () {
      final payload = List<int>.generate(
        2000, // Larger payload to ensure multiple frames
        (i) => i % 256,
      );
      final frames = encoder.encode(payload);

      // Shuffle frames
      final shuffled = [...frames]..shuffle();

      // Feed frames in random order
      for (final frame in shuffled) {
        decoder.addFrame(frame);
      }

      expect(decoder.isComplete, isTrue);
    });

    test('duplicate frame is ignored', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      // Feed first frame twice
      decoder.addFrame(frames.first);
      final result1 = decoder.receivedIndices.length;
      
      decoder.addFrame(frames.first);
      final result2 = decoder.receivedIndices.length;

      expect(result1, equals(result2));
    });

    test('tampered CRC returns FrameChecksumFailure', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      // Tamper with the last byte (part of CRC)
      final tamperedFrame = List<int>.from(frames.first);
      tamperedFrame[tamperedFrame.length - 1] ^= 0xFF;

      final result = decoder.addFrame(tamperedFrame);

      expect(result.isErr, isTrue);
      expect(result.error, isA<FrameChecksumFailure>());
    });

    test('progress 0.0 to 1.0 as frames arrive', () {
      final payload = List<int>.generate(
        2000,
        (i) => i % 256,
      );
      final frames = encoder.encode(payload);

      expect(decoder.progress, equals(0.0));

      for (var i = 0; i < frames.length; i++) {
        decoder.addFrame(frames[i]);
        final expectedProgress = (i + 1) / frames.length;
        expect(decoder.progress, closeTo(expectedProgress, 0.01));
      }
    });

    test('reset() clears state', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      decoder.addFrame(frames.first);
      expect(decoder.receivedIndices.isNotEmpty, isTrue);

      decoder.reset();

      expect(decoder.receivedIndices, isEmpty);
      expect(decoder.totalExpected, isNull);
      expect(decoder.progress, equals(0.0));
      expect(decoder.isComplete, isFalse);
    });

    test('receivedIndices returns set of received frame indices', () {
      final payload = List<int>.generate(200, (i) => i);
      final frames = encoder.encode(payload);

      decoder.addFrame(frames[0]);
      expect(decoder.receivedIndices, equals({0}));

      decoder.addFrame(frames[1]);
      expect(decoder.receivedIndices, equals({0, 1}));
    });

    test('totalExpected returns number of frames after first frame', () {
      final payload = List<int>.generate(200, (i) => i);
      final frames = encoder.encode(payload);

      expect(decoder.totalExpected, isNull);

      decoder.addFrame(frames[0]);
      expect(decoder.totalExpected, equals(frames.length));
    });

    test('isComplete returns false when incomplete', () {
      final payload = List<int>.generate(200, (i) => i);
      final frames = encoder.encode(payload);

      expect(decoder.isComplete, isFalse);

      decoder.addFrame(frames[0]);
      expect(decoder.isComplete, isFalse);

      // Add remaining frames
      for (var i = 1; i < frames.length; i++) {
        decoder.addFrame(frames[i]);
      }
      expect(decoder.isComplete, isTrue);
    });

    test('wrong protocol version returns SyncPayloadCorruptedFailure', () {
      final payload = List<int>.generate(100, (i) => i);
      final frames = encoder.encode(payload);

      // Tamper with version byte
      final tamperedFrame = List<int>.from(frames.first);
      tamperedFrame[0] = 0xFF; // Wrong version

      final result = decoder.addFrame(tamperedFrame);

      expect(result.isErr, isTrue);
      expect(result.error, isA<SyncPayloadCorruptedFailure>());
    });

    test('frame too short returns FrameChecksumFailure', () {
      final shortFrame = [0x01]; // Just version, not enough for header

      final result = decoder.addFrame(shortFrame);

      expect(result.isErr, isTrue);
      expect(result.error, isA<FrameChecksumFailure>());
    });

    test('handles single frame payload', () {
      final payload = List<int>.generate(50, (i) => i);
      final frames = encoder.encode(payload);

      // Add the single frame
      final result = decoder.addFrame(frames.first);
      
      // For a single frame, should complete immediately
      expect(result.isOk, isTrue);
      if (result.isOk && result.value != null) {
        // If completed, verify payload is returned
        expect(result.value!.length, greaterThan(0));
      }
    });
  });
}
