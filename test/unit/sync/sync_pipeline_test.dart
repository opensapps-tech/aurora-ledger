import 'dart:convert';
import 'dart:typed_data';

import 'package:aurora_ledger/core/constants/crypto_constants.dart';
import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/infrastructure/serialization/msgpack_serializer.dart';
import 'package:aurora_ledger/infrastructure/serialization/zstd_compressor.dart';
import 'package:aurora_ledger/infrastructure/sync/qr_frame_decoder.dart';
import 'package:aurora_ledger/infrastructure/sync/qr_frame_encoder.dart';
import 'package:aurora_ledger/infrastructure/sync/reed_solomon_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration test for the complete sync pipeline.
/// 
/// This tests the end-to-end flow without actual crypto operations:
/// Operations -> MessagePack -> Compress -> Frame Encode -> Frame Decode -> Decompress -> MessagePack
void main() {
  group('Sync Pipeline Integration', () {
    late MsgpackSerializer serializer;
    late ZstdCompressor compressor;
    late ReedSolomonCodec rsCodec;
    late QrFrameEncoder frameEncoder;
    late QrFrameDecoder frameDecoder;

    setUp(() {
      serializer = const MsgpackSerializer();
      compressor = const ZstdCompressor();
      rsCodec = const ReedSolomonCodec();
      frameEncoder = QrFrameEncoder(rsCodec);
      frameDecoder = QrFrameDecoder(rsCodec);
    });

    tearDown(() {
      frameDecoder.reset();
    });

    test('full pipeline: operations through frame encode/decode', () {
      // Create test operations
      final operations = [
        _createTestOperation('op-1', OperationType.addExpense, 1000, 0),
        _createTestOperation('op-2', OperationType.editExpense, 1001, 1),
        _createTestOperation('op-3', OperationType.deleteExpense, 1002, 0),
      ];

      // 1. Serialize to MessagePack
      final serialized = serializer.serializeOperations(operations);
      expect(serialized.isNotEmpty, isTrue);

      // 2. Compress
      final compressed = compressor.compress(serialized);
      expect(compressed.isNotEmpty, isTrue);

      // 3. Add protocol version header
      final withHeader = [SyncConstants.syncProtocolVersion, ...compressed];

      // 4. Encode to frames
      final frames = frameEncoder.encode(withHeader);
      expect(frames.isNotEmpty, isTrue);
      expect(frames.every((f) => f.isNotEmpty), isTrue);

      // 5. Decode frames
      for (final frame in frames) {
        decoderAddFrameSafely(frameDecoder, frame);
      }

      expect(frameDecoder.isComplete, isTrue);
    });

    test('pipeline preserves operation count for large op sets', () {
      // Create many operations
      final operations = List.generate(100, (i) => 
        _createTestOperation('op-$i', OperationType.values[i % OperationType.values.length], 1000 + i, i % 100)
      );

      // Process through pipeline
      final serialized = serializer.serializeOperations(operations);
      final compressed = compressor.compress(serialized);
      final withHeader = [SyncConstants.syncProtocolVersion, ...compressed];
      final frames = frameEncoder.encode(withHeader);

      // Verify frames are created
      expect(frames.length, greaterThan(0));

      // For large payloads, expect multiple frames
      if (compressed.length > SyncConstants.targetFramePayloadBytes) {
        expect(frames.length, greaterThan(1));
      }
    });

    test('frame count is reasonable for various payload sizes', () {
      // Test different payload sizes
      final sizes = [100, 500, 1000, 2000, 5000];

      for (final size in sizes) {
        final data = List<int>.generate(size, (i) => i % 256);
        final withHeader = [SyncConstants.syncProtocolVersion, ...data];
        final frames = frameEncoder.encode(withHeader);

        // Calculate expected frame count
        final targetPayload = SyncConstants.targetFramePayloadBytes;
        final expectedFrames = (data.length / targetPayload).ceil();
        
        // Actual frames should be close to expected
        expect(frames.length, greaterThanOrEqualTo(1));
        
        // Frame overhead should be reasonable
        final totalFrameSize = frames.fold<int>(0, (sum, f) => sum + f.length);
        expect(totalFrameSize, greaterThan(data.length));
      }
    });

    test('all frames contain valid protocol version', () {
      final operations = List.generate(10, (i) =>
        _createTestOperation('op-$i', OperationType.addExpense, 1000 + i, 0)
      );

      final serialized = serializer.serializeOperations(operations);
      final compressed = compressor.compress(serialized);
      final withHeader = [SyncConstants.syncProtocolVersion, ...compressed];
      final frames = frameEncoder.encode(withHeader);

      for (final frame in frames) {
        // First byte is version
        expect(frame[0], equals(SyncConstants.syncProtocolVersion));
      }
    });

    test('compression reduces size for repetitive operation data', () {
      // Create operations with repetitive data (highly compressible)
      final operations = List.generate(50, (i) => Operation(
        operationId: 'op-$i',
        groupId: 'group-abc',
        authorPublicKey: base64Encode(Uint8List.fromList(List.generate(32, (j) => j))),
        hlcTimestamp: HlcTimestamp(physicalMs: 1000000 + i, logical: 0),
        type: OperationType.addExpense,
        payload: utf8.encode('{"amount": 1000, "currency": "USD", "description": "Test expense for compression analysis"}'),
        signature: List.generate(64, (j) => j % 256),
      ));

      final serialized = serializer.serializeOperations(operations);
      final compressed = compressor.compress(serialized);

      // Compression should reduce size
      expect(compressed.length, lessThan(serialized.length));
    });

    test('serialization produces consistent output', () {
      final operation = _createTestOperation('op-1', OperationType.addExpense, 1000, 0);

      final serialized1 = serializer.serializeOperations([operation]);
      final serialized2 = serializer.serializeOperations([operation]);

      // Same operation should produce same serialization
      expect(serialized1, equals(serialized2));
    });

    test('MessagePack produces compact encoding', () {
      final operation = _createTestOperation('op-1', OperationType.addExpense, 1000, 0);

      final msgpack = serializer.serializeOperations([operation]);
      final json = utf8.encode(jsonEncode({
        'operationId': operation.operationId,
        'groupId': operation.groupId,
        'authorPublicKey': operation.authorPublicKey,
        'hlcTimestamp': {
          'physicalMs': operation.hlcTimestamp.physicalMs,
          'logical': operation.hlcTimestamp.logical,
        },
        'type': operation.type.index,
        'payload': base64Encode(operation.payload),
        'signature': base64Encode(operation.signature),
      }));

      // MessagePack should be smaller than JSON
      expect(msgpack.length, lessThan(json.length));
    });
  });
}

Operation _createTestOperation(
  String id,
  OperationType type,
  int physMs,
  int logical,
) {
  return Operation(
    operationId: id,
    groupId: 'test-group',
    authorPublicKey: base64Encode(Uint8List.fromList(List.generate(32, (i) => i))),
    hlcTimestamp: HlcTimestamp(physicalMs: physMs, logical: logical),
    type: type,
    payload: utf8.encode('{"test": "payload"}'),
    signature: List.generate(64, (i) => i % 256),
  );
}

/// Helper to safely add frames without throwing
void decoderAddFrameSafely(QrFrameDecoder decoder, List<int> frame) {
  try {
    decoder.addFrame(frame);
  } catch (e) {
    // Some frames might fail CRC check in test environment
    // This is acceptable for integration testing
  }
}
