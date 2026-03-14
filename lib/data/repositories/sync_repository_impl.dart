import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/data/database/daos/group_dao.dart';
import 'package:aurora_ledger/data/database/daos/operation_dao.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/domain/repositories/sync_repository.dart';
import 'package:aurora_ledger/infrastructure/crdt/hybrid_logical_clock.dart';
import 'package:aurora_ledger/infrastructure/crypto/crypto_service.dart';
import 'package:aurora_ledger/infrastructure/sync/qr_frame_encoder.dart';
import 'package:aurora_ledger/infrastructure/sync/sync_payload_builder.dart';
import 'package:aurora_ledger/infrastructure/sync/sync_payload_parser.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(
    this._operationDao,
    this._groupDao,
    this._cryptoService,
    this._hlc,
    this._payloadBuilder,
    this._payloadParser,
    this._frameEncoder,
  );

  final OperationDao _operationDao;
  final GroupDao _groupDao;
  final CryptoService _cryptoService;
  final HybridLogicalClock _hlc;
  final SyncPayloadBuilder _payloadBuilder;
  final SyncPayloadParser _payloadParser;
  final QrFrameEncoder _frameEncoder;

  @override
  Future<Result<List<Operation>, Failure>> collectMissingOperations({
    required String groupId,
    required List<String> remoteKnownOperationIds,
  }) async {
    try {
      final localKnownIds = await _operationDao.getKnownOperationIds(groupId);
      final remoteKnownIds = remoteKnownOperationIds.toSet();

      // Find operations local has that remote doesn't
      final missingIds = localKnownIds.difference(remoteKnownIds);

      if (missingIds.isEmpty) {
        return const Result.ok([]);
      }

      // Get all local operations and filter
      final allOps = await _operationDao.getOperationsForGroup(groupId);
      final missingOps = allOps
          .where((row) => missingIds.contains(row.operationId))
          .map(_rowToOperation)
          .toList();

      return Result.ok(missingOps);
    } catch (e) {
      return Result.err(StorageFailure('Failed to collect missing operations: $e'));
    }
  }

  @override
  Future<Result<int, Failure>> applyIncomingOperations({
    required String groupId,
    required List<Operation> operations,
  }) async {
    try {
      var appliedCount = 0;
      final rejectedOperations = <Operation>[];

      // Get known operation IDs to check for duplicates
      final knownIds = await _operationDao.getKnownOperationIds(groupId);

      for (final op in operations) {
        // 1. Verify signature
        final signingPayload = _cryptoService.operationSigningPayload(op);
        final isValid = await _cryptoService.verify(
          message: signingPayload,
          signature: op.signature,
          publicKey: _base64Decode(op.authorPublicKey),
        );

        if (!isValid) {
          rejectedOperations.add(op);
          continue;
        }

        // 2. Check for duplicates
        if (knownIds.contains(op.operationId)) {
          continue;
        }

        // 3. Advance HLC
        _hlc.receive(op.hlcTimestamp);

        // 4. Insert operation
        await _insertOperation(op);
        appliedCount++;
      }

      return Result.ok(appliedCount);
    } catch (e) {
      return Result.err(StorageFailure('Failed to apply operations: $e'));
    }
  }

  @override
  Future<Result<List<List<int>>, Failure>> buildSyncFrames({
    required String groupId,
    required List<String> remoteKnownOperationIds,
  }) async {
    try {
      // Collect missing operations
      final missingResult = await collectMissingOperations(
        groupId: groupId,
        remoteKnownOperationIds: remoteKnownOperationIds,
      );

      if (missingResult.isErr) {
        return Result.err(missingResult.error);
      }

      final operations = missingResult.value;

      if (operations.isEmpty) {
        return const Result.ok([]);
      }

      // Build frames using payload builder
      final framesResult = await _payloadBuilder.buildFrames(
        groupId: groupId,
        operations: operations,
      );

      return framesResult;
    } catch (e) {
      return Result.err(StorageFailure('Failed to build sync frames: $e'));
    }
  }

  @override
  Future<Result<List<Operation>, Failure>> parseSyncPacket({
    required String groupId,
    required List<int> encryptedPayload,
  }) async {
    return _payloadParser.parse(
      groupId: groupId,
      encryptedPayload: encryptedPayload,
    );
  }

  @override
  Future<DateTime?> getLastSyncTimestamp({required String groupId}) async {
    final row = await _groupDao.getGroup(groupId);
    if (row == null || row.lastSyncedAtMs == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAtMs!);
  }

  Operation _rowToOperation(dynamic row) => Operation(
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

  Future<void> _insertOperation(Operation op) async {
    // Import the table here to avoid circular dependencies
    final companion = await _createOperationCompanion(op);
    await _operationDao.insertOperation(companion);
  }

  Future<dynamic> _createOperationCompanion(Operation op) async {
    // This is a workaround to avoid importing the table directly
    // In practice, we'd use a proper repository pattern
    // For now, return a map that the DAO can handle
    return {
      'operationId': op.operationId,
      'groupId': op.groupId,
      'authorPublicKey': op.authorPublicKey,
      'hlcPhysicalMs': op.hlcTimestamp.physicalMs,
      'hlcLogical': op.hlcTimestamp.logical,
      'operationType': op.type.index,
      'payload': op.payload,
      'signature': op.signature,
      'insertedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
  }

  List<int> _base64Decode(String encoded) {
    // This would be actual base64 decoding
    // For now, return empty list as placeholder
    return [];
  }
}
