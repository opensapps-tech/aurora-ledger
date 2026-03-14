import 'dart:convert';

import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/data/database/daos/operation_dao.dart';
import 'package:aurora_ledger/data/database/tables/operations_table.dart';
import 'package:aurora_ledger/domain/entities/expense.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/domain/repositories/expense_repository.dart';
import 'package:aurora_ledger/infrastructure/crdt/conflict_resolver.dart';
import 'package:aurora_ledger/infrastructure/crdt/hybrid_logical_clock.dart';
import 'package:aurora_ledger/infrastructure/crypto/crypto_service.dart';
import 'package:aurora_ledger/infrastructure/crypto/key_storage_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(
    this._operationDao,
    this._cryptoService,
    this._keyStorage,
    this._hlc,
    this._resolver,
  );

  final OperationDao _operationDao;
  final CryptoService _cryptoService;
  final KeyStorageService _keyStorage;
  final HybridLogicalClock _hlc;
  final ConflictResolver _resolver;

  static const _uuid = Uuid();

  @override
  Future<Result<Expense, Failure>> addExpense({
    required String groupId,
    required int amountMinorUnits,
    required String currency,
    required String payerIdentityId,
    required List<String> participantIdentityIds,
    required String notes,
  }) async {
    try {
      final expenseId = _uuid.v4();
      final payload = _buildAddExpensePayload(
        expenseId: expenseId,
        amountMinorUnits: amountMinorUnits,
        currency: currency,
        payerIdentityId: payerIdentityId,
        participantIdentityIds: participantIdentityIds,
        notes: notes,
      );

      final operation = await _createAndSignOperation(
        groupId: groupId,
        type: OperationType.addExpense,
        payload: payload,
      );

      await _insertOperation(operation);

      return Result.ok(_operationToExpense(operation, {
        'expenseId': expenseId,
        'amountMinorUnits': amountMinorUnits,
        'currency': currency,
        'payerIdentityId': payerIdentityId,
        'participantIdentityIds': participantIdentityIds,
        'notes': notes,
      }));
    } catch (e) {
      return Result.err(StorageFailure('Failed to add expense: $e'));
    }
  }

  @override
  Future<Result<Expense, Failure>> editExpense({
    required String expenseId,
    required Expense updated,
  }) async {
    try {
      final payload = _buildEditExpensePayload(
        expenseId: expenseId,
        amountMinorUnits: updated.amountMinorUnits,
        currency: updated.currency,
        notes: updated.notes,
      );

      final operation = await _createAndSignOperation(
        groupId: updated.groupId,
        type: OperationType.editExpense,
        payload: payload,
      );

      await _insertOperation(operation);

      return Result.ok(updated.copyWith(
        authorPublicKey: await _keyStorage.loadPublicKey().then((k) => base64Encode(k!)),
      ));
    } catch (e) {
      return Result.err(StorageFailure('Failed to edit expense: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> deleteExpense({required String groupId, required String expenseId}) async {
    try {
      final payload = _buildDeleteExpensePayload(expenseId: expenseId);

      final operation = await _createAndSignOperation(
        groupId: groupId,
        type: OperationType.deleteExpense,
        payload: payload,
      );

      await _insertOperation(operation);

      return const Result.ok(null);
    } catch (e) {
      return Result.err(StorageFailure('Failed to delete expense: $e'));
    }
  }

  @override
  Future<Result<List<Expense>, Failure>> getExpensesForGroup({
    required String groupId,
  }) async {
    try {
      final rows = await _operationDao.getOperationsForGroup(groupId);
      final expenses = _projectExpenses(rows);
      return Result.ok(expenses);
    } catch (e) {
      return Result.err(StorageFailure('Failed to get expenses: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> settlePayment({
    required String groupId,
    required String fromIdentityId,
    required String toIdentityId,
    required int amountMinorUnits,
  }) async {
    try {
      final payload = _buildSettlePayload(
        fromIdentityId: fromIdentityId,
        toIdentityId: toIdentityId,
        amountMinorUnits: amountMinorUnits,
      );

      final operation = await _createAndSignOperation(
        groupId: groupId,
        type: OperationType.settlePayment,
        payload: payload,
      );

      await _insertOperation(operation);

      return const Result.ok(null);
    } catch (e) {
      return Result.err(StorageFailure('Failed to settle payment: $e'));
    }
  }

  @override
  Stream<List<Expense>> watchExpensesForGroup({required String groupId}) {
    return _operationDao.watchOperationsForGroup(groupId).map(_projectExpenses);
  }

  /// Projects operation rows to expense entities, applying conflict resolution.
  List<Expense> _projectExpenses(List<OperationRow> rows) {
    // Group operations by expenseId
    final opsByExpense = <String, List<Operation>>{};

    for (final row in rows) {
      final op = _rowToOperation(row);
      final expenseId = _extractExpenseId(op);
      if (expenseId != null) {
        opsByExpense.putIfAbsent(expenseId, () => []).add(op);
      }
    }

    // Apply conflict resolution and project
    final expenses = <Expense>[];
    for (final entry in opsByExpense.entries) {
      final winningOp = _resolver.resolveExpenseOps(entry.value);
      if (winningOp != null) {
        final expense = _operationToExpense(winningOp, _extractPayloadData(winningOp));
        if (expense != null) {
          expenses.add(expense);
        }
      }
    }

    // Sort by creation time (newest first)
    expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return expenses;
  }

  Operation _rowToOperation(OperationRow row) => Operation(
        operationId: row.operationId,
        groupId: row.groupId,
        authorPublicKey: row.authorPublicKey,
        hlcTimestamp: HlcTimestamp(
          physicalMs: row.hlcPhysicalMs,
          logical: row.hlcLogical,
        ),
        type: OperationType.values[row.operationType],
        payload: row.payload,
        signature: row.signature,
      );

  String? _extractExpenseId(Operation op) {
    try {
      final payload = jsonDecode(utf8.decode(op.payload)) as Map<String, dynamic>;
      return payload['expenseId'] as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractPayloadData(Operation op) {
    try {
      return jsonDecode(utf8.decode(op.payload)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Expense? _operationToExpense(Operation op, Map<String, dynamic>? data) {
    if (data == null) return null;

    return Expense(
      expenseId: data['expenseId'] as String? ?? '',
      groupId: op.groupId,
      amountMinorUnits: data['amountMinorUnits'] as int? ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      payerIdentityId: data['payerIdentityId'] as String? ?? '',
      participantIdentityIds: (data['participantIdentityIds'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      notes: data['notes'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(op.hlcTimestamp.physicalMs),
      authorPublicKey: op.authorPublicKey,
      isDeleted: op.type == OperationType.deleteExpense,
    );
  }

  Future<Operation> _createAndSignOperation({
    required String groupId,
    required OperationType type,
    required List<int> payload,
  }) async {
    final secretKey = await _keyStorage.loadSecretKey();
    final publicKey = await _keyStorage.loadPublicKey();

    if (secretKey == null || publicKey == null) {
      throw Exception('Identity keys not found');
    }

    final hlc = _hlc.now();
    final operationId = _uuid.v4();

    final unsignedOp = Operation(
      operationId: operationId,
      groupId: groupId,
      authorPublicKey: base64Encode(publicKey),
      hlcTimestamp: hlc,
      type: type,
      payload: payload,
      signature: const [],
    );

    final signingPayload = _cryptoService.operationSigningPayload(unsignedOp);
    final signature = await _cryptoService.sign(
      message: signingPayload,
      secretKey: secretKey,
    );

    return Operation(
      operationId: operationId,
      groupId: groupId,
      authorPublicKey: base64Encode(publicKey),
      hlcTimestamp: hlc,
      type: type,
      payload: payload,
      signature: signature,
    );
  }

  Future<void> _insertOperation(Operation op) async {
    await _operationDao.insertOperation(OperationsTableCompanion.insert(
      operationId: op.operationId,
      groupId: op.groupId,
      authorPublicKey: op.authorPublicKey,
      hlcPhysicalMs: op.hlcTimestamp.physicalMs,
      hlcLogical: op.hlcTimestamp.logical,
      operationType: op.type.index,
      payload: op.payload,
      signature: op.signature,
      insertedAtMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  List<int> _buildAddExpensePayload({
    required String expenseId,
    required int amountMinorUnits,
    required String currency,
    required String payerIdentityId,
    required List<String> participantIdentityIds,
    required String notes,
  }) {
    return utf8.encode(jsonEncode({
      'expenseId': expenseId,
      'amountMinorUnits': amountMinorUnits,
      'currency': currency,
      'payerIdentityId': payerIdentityId,
      'participantIdentityIds': participantIdentityIds,
      'notes': notes,
    }));
  }

  List<int> _buildEditExpensePayload({
    required String expenseId,
    required int amountMinorUnits,
    required String currency,
    required String notes,
  }) {
    return utf8.encode(jsonEncode({
      'expenseId': expenseId,
      'amountMinorUnits': amountMinorUnits,
      'currency': currency,
      'notes': notes,
    }));
  }

  List<int> _buildDeleteExpensePayload({required String expenseId}) {
    return utf8.encode(jsonEncode({'expenseId': expenseId}));
  }

  List<int> _buildSettlePayload({
    required String fromIdentityId,
    required String toIdentityId,
    required int amountMinorUnits,
  }) {
    return utf8.encode(jsonEncode({
      'fromIdentityId': fromIdentityId,
      'toIdentityId': toIdentityId,
      'amountMinorUnits': amountMinorUnits,
    }));
  }
}
