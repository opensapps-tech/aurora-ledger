import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/infrastructure/crdt/conflict_resolver.dart';
import 'package:aurora_ledger/infrastructure/crdt/operation_log.dart';
import 'package:aurora_ledger/infrastructure/crdt/operation_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OperationMerger', () {
    late OperationMerger merger;
    late OperationLog localLog;

    setUp(() {
      merger = const OperationMerger(ConflictResolver());
      localLog = OperationLog('group-1');
    });

    test('merge() applies new ops and returns correct appliedCount', () {
      final incoming = [
        _makeOp('op-1', OperationType.addExpense, physMs: 100),
        _makeOp('op-2', OperationType.editExpense, physMs: 200),
      ];

      final result = merger.merge(
        local: localLog,
        incoming: incoming,
      );

      expect(result.appliedCount, equals(2));
      expect(result.appliedOperations, hasLength(2));
      expect(result.duplicateIds, isEmpty);
      expect(localLog.sorted, hasLength(2));
    });

    test('merge() skips duplicates', () {
      // First merge
      final op1 = _makeOp('op-1', OperationType.addExpense, physMs: 100);
      merger.merge(local: localLog, incoming: [op1]);

      // Second merge with same op
      final result = merger.merge(
        local: localLog,
        incoming: [op1],
      );

      expect(result.appliedCount, equals(0));
      expect(result.duplicateIds, equals(['op-1']));
      expect(localLog.sorted, hasLength(1));
    });

    test('merge() with empty list returns appliedCount == 0', () {
      final result = merger.merge(
        local: localLog,
        incoming: [],
      );

      expect(result.appliedCount, equals(0));
      expect(result.appliedOperations, isEmpty);
      expect(result.duplicateIds, isEmpty);
    });

    test('merge() preserves causal order after merge', () {
      // Create ops out of order
      final op1 = _makeOp('op-1', OperationType.addExpense, physMs: 100, logical: 0);
      final op2 = _makeOp('op-2', OperationType.editExpense, physMs: 50, logical: 0);
      final op3 = _makeOp('op-3', OperationType.editExpense, physMs: 150, logical: 0);

      merger.merge(local: localLog, incoming: [op1, op2, op3]);

      // Verify sorted order
      final sorted = localLog.sorted;
      expect(sorted[0].hlcTimestamp.physicalMs, equals(50));
      expect(sorted[1].hlcTimestamp.physicalMs, equals(100));
      expect(sorted[2].hlcTimestamp.physicalMs, equals(150));
    });

    test('missingFrom() returns only ops not in remoteKnownIds', () {
      // Add some operations to the log
      final op1 = _makeOp('op-1', OperationType.addExpense, physMs: 100);
      final op2 = _makeOp('op-2', OperationType.editExpense, physMs: 200);
      final op3 = _makeOp('op-3', OperationType.deleteExpense, physMs: 300);

      localLog.add(op1);
      localLog.add(op2);
      localLog.add(op3);

      // Remote knows op-1 and op-3
      final missing = localLog.missingFrom({'op-1', 'op-3'});

      expect(missing, hasLength(1));
      expect(missing.first.operationId, equals('op-2'));
    });

    test('missingFrom() returns all ops when remote knows nothing', () {
      final op1 = _makeOp('op-1', OperationType.addExpense, physMs: 100);
      final op2 = _makeOp('op-2', OperationType.editExpense, physMs: 200);

      localLog.add(op1);
      localLog.add(op2);

      final missing = localLog.missingFrom({});

      expect(missing, hasLength(2));
    });

    test('missingFrom() returns empty when remote knows all ops', () {
      final op1 = _makeOp('op-1', OperationType.addExpense, physMs: 100);
      localLog.add(op1);

      final missing = localLog.missingFrom({'op-1'});

      expect(missing, isEmpty);
    });

    test('knownIds contains all operation IDs in log', () {
      final op1 = _makeOp('op-1', OperationType.addExpense, physMs: 100);
      final op2 = _makeOp('op-2', OperationType.editExpense, physMs: 200);

      localLog.add(op1);
      localLog.add(op2);

      expect(localLog.knownIds, equals({'op-1', 'op-2'}));
    });

    test('add() prevents duplicate operations in log', () {
      final op1 = _makeOp('op-1', OperationType.addExpense, physMs: 100);

      localLog.add(op1);
      localLog.add(op1); // Add same op again

      expect(localLog.sorted, hasLength(1));
    });

    test('addAll() adds multiple operations efficiently', () {
      final ops = [
        _makeOp('op-1', OperationType.addExpense, physMs: 100),
        _makeOp('op-2', OperationType.editExpense, physMs: 200),
        _makeOp('op-3', OperationType.deleteExpense, physMs: 300),
      ];

      localLog.addAll(ops);

      expect(localLog.sorted, hasLength(3));
    });
  });
}

Operation _makeOp(
  String id,
  OperationType type, {
  required int physMs,
  int logical = 0,
}) =>
    Operation(
      operationId: id,
      groupId: 'group-1',
      authorPublicKey: 'pubkey-alice',
      hlcTimestamp: HlcTimestamp(physicalMs: physMs, logical: logical),
      type: type,
      payload: const [],
      signature: const [],
    );
