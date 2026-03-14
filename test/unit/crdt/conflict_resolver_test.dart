import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/infrastructure/crdt/conflict_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ConflictResolver resolver;

  setUp(() => resolver = const ConflictResolver());

  group('ConflictResolver', () {
    test('delete wins over edit', () {
      final ops = [
        _makeOp('op-1', OperationType.editExpense, physMs: 100),
        _makeOp('op-2', OperationType.deleteExpense, physMs: 90), // earlier but delete wins
      ];
      final winner = resolver.resolveExpenseOps(ops);
      expect(winner, isNull); // deleted
    });

    test('last edit wins when no delete', () {
      final ops = [
        _makeOp('op-1', OperationType.addExpense, physMs: 100),
        _makeOp('op-2', OperationType.editExpense, physMs: 200),
        _makeOp('op-3', OperationType.editExpense, physMs: 150),
      ];
      final winner = resolver.resolveExpenseOps(ops);
      expect(winner?.operationId, equals('op-2')); // highest HLC
    });

    test('isDuplicate returns true for known operationId', () {
      final op = _makeOp('op-known', OperationType.addExpense, physMs: 1);
      expect(resolver.isDuplicate(op, {'op-known', 'op-other'}), isTrue);
    });
  });
}

Operation _makeOp(String id, OperationType type, {required int physMs}) => Operation(
      operationId: id,
      groupId: 'group-1',
      authorPublicKey: 'pubkey-alice',
      hlcTimestamp: HlcTimestamp(physicalMs: physMs, logical: 0),
      type: type,
      payload: const [],
      signature: const [],
    );
