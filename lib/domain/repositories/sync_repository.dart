import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';

abstract interface class SyncRepository {
  /// Collects all operations the remote device does not yet have.
  Future<Result<List<Operation>, Failure>> collectMissingOperations({
    required String groupId,
    required List<String> remoteKnownOperationIds,
  });

  /// Applies a batch of incoming operations from a sync peer.
  Future<Result<int, Failure>> applyIncomingOperations({
    required String groupId,
    required List<Operation> operations,
  });

  /// Builds an encrypted, compressed, ECC-protected sync packet
  /// split into QR frame chunks.
  Future<Result<List<List<int>>, Failure>> buildSyncFrames({
    required String groupId,
    required List<String> remoteKnownOperationIds,
  });

  /// Parses, decrypts and validates a completed sync packet.
  Future<Result<List<Operation>, Failure>> parseSyncPacket({
    required String groupId,
    required List<int> encryptedPayload,
  });

  /// Returns the last sync timestamp for replica status checks.
  Future<DateTime?> getLastSyncTimestamp({required String groupId});
}
