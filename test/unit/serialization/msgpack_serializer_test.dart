import 'dart:convert';
import 'dart:typed_data';

import 'package:aurora_ledger/core/errors/exceptions.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/infrastructure/serialization/msgpack_serializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MsgpackSerializer', () {
    late MsgpackSerializer serializer;

    setUp(() {
      serializer = const MsgpackSerializer();
    });

    test('round-trip 1 operation: all fields preserved', () {
      final original = Operation(
        operationId: 'op-123',
        groupId: 'group-abc',
        authorPublicKey: base64Encode(Uint8List.fromList(List.generate(32, (i) => i))),
        hlcTimestamp: const HlcTimestamp(physicalMs: 1234567890, logical: 42),
        type: OperationType.addExpense,
        payload: utf8.encode('{"amount": 1000, "currency": "USD"}'),
        signature: List.generate(64, (i) => i + 100),
      );

      final bytes = serializer.serializeOperations([original]);
      final deserialized = serializer.deserializeOperations(bytes);

      expect(deserialized, hasLength(1));
      expect(deserialized[0].operationId, equals(original.operationId));
      expect(deserialized[0].groupId, equals(original.groupId));
      expect(deserialized[0].authorPublicKey, equals(original.authorPublicKey));
      expect(deserialized[0].hlcTimestamp.physicalMs, equals(original.hlcTimestamp.physicalMs));
      expect(deserialized[0].hlcTimestamp.logical, equals(original.hlcTimestamp.logical));
      expect(deserialized[0].type, equals(original.type));
      expect(deserialized[0].payload, equals(original.payload));
      expect(deserialized[0].signature, equals(original.signature));
    });

    test('round-trip 50 operations: count and IDs preserved', () {
      final operations = List.generate(50, (i) => Operation(
        operationId: 'op-$i',
        groupId: 'group-${i % 5}',
        authorPublicKey: base64Encode(Uint8List.fromList([i])),
        hlcTimestamp: HlcTimestamp(physicalMs: 1000 + i, logical: i % 10),
        type: OperationType.values[i % OperationType.values.length],
        payload: utf8.encode('payload-$i'),
        signature: List.generate(64, (j) => (i + j) % 256),
      ));

      final bytes = serializer.serializeOperations(operations);
      final deserialized = serializer.deserializeOperations(bytes);

      expect(deserialized, hasLength(50));
      for (var i = 0; i < 50; i++) {
        expect(deserialized[i].operationId, equals('op-$i'));
      }
    });

    test('deserialize malformed bytes throws SerializationException', () {
      // Invalid MessagePack data
      final malformedBytes = [0xFF, 0xFF, 0xFF];

      expect(
        () => serializer.deserializeOperations(malformedBytes),
        throwsA(isA<SerializationException>()),
      );
    });

    test('empty list round-trip', () {
      final bytes = serializer.serializeOperations([]);
      final deserialized = serializer.deserializeOperations(bytes);

      expect(deserialized, isEmpty);
    });

    test('all operation types are correctly serialized and deserialized', () {
      for (final type in OperationType.values) {
        final op = Operation(
          operationId: 'op-${type.name}',
          groupId: 'group-1',
          authorPublicKey: base64Encode(Uint8List(32)),
          hlcTimestamp: const HlcTimestamp(physicalMs: 1000, logical: 0),
          type: type,
          payload: const [],
          signature: List.generate(64, (i) => i),
        );

        final bytes = serializer.serializeOperations([op]);
        final deserialized = serializer.deserializeOperations(bytes);

        expect(deserialized[0].type, equals(type));
        expect(deserialized[0].operationId, equals('op-${type.name}'));
      }
    });

    test('binary payload is preserved correctly', () {
      final binaryPayload = Uint8List.fromList([0x00, 0x01, 0xFF, 0xAB, 0xCD, 0xEF]);
      
      final op = Operation(
        operationId: 'binary-op',
        groupId: 'group-1',
        authorPublicKey: base64Encode(Uint8List(32)),
        hlcTimestamp: const HlcTimestamp(physicalMs: 1000, logical: 0),
        type: OperationType.addExpense,
        payload: binaryPayload.toList(),
        signature: List.generate(64, (i) => i),
      );

      final bytes = serializer.serializeOperations([op]);
      final deserialized = serializer.deserializeOperations(bytes);

      expect(deserialized[0].payload, equals(binaryPayload.toList()));
    });

    test('large payload is handled correctly', () {
      final largePayload = List.generate(10000, (i) => i % 256);
      
      final op = Operation(
        operationId: 'large-op',
        groupId: 'group-1',
        authorPublicKey: base64Encode(Uint8List(32)),
        hlcTimestamp: const HlcTimestamp(physicalMs: 1000, logical: 0),
        type: OperationType.addExpense,
        payload: largePayload,
        signature: List.generate(64, (i) => i),
      );

      final bytes = serializer.serializeOperations([op]);
      final deserialized = serializer.deserializeOperations(bytes);

      expect(deserialized[0].payload, equals(largePayload));
    });

    test('special characters in operationId are preserved', () {
      final specialId = 'op-with-special-chars-!@#\$%^&*()_+-=[]{}|;\':",./<>?';
      
      final op = Operation(
        operationId: specialId,
        groupId: 'group-1',
        authorPublicKey: base64Encode(Uint8List(32)),
        hlcTimestamp: const HlcTimestamp(physicalMs: 1000, logical: 0),
        type: OperationType.addExpense,
        payload: const [],
        signature: List.generate(64, (i) => i),
      );

      final bytes = serializer.serializeOperations([op]);
      final deserialized = serializer.deserializeOperations(bytes);

      expect(deserialized[0].operationId, equals(specialId));
    });

    test('HLC with max int values', () {
      final op = Operation(
        operationId: 'max-hlc-op',
        groupId: 'group-1',
        authorPublicKey: base64Encode(Uint8List(32)),
        hlcTimestamp: const HlcTimestamp(physicalMs: 9223372036854775807, logical: 2147483647),
        type: OperationType.addExpense,
        payload: const [],
        signature: List.generate(64, (i) => i),
      );

      final bytes = serializer.serializeOperations([op]);
      final deserialized = serializer.deserializeOperations(bytes);

      expect(deserialized[0].hlcTimestamp.physicalMs, equals(9223372036854775807));
      expect(deserialized[0].hlcTimestamp.logical, equals(2147483647));
    });
  });
}
