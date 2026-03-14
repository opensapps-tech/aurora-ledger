import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/repositories/sync_repository.dart';

class PrepareSyncPacketUsecase {
  const PrepareSyncPacketUsecase(this._repository);
  final SyncRepository _repository;

  /// Returns a list of QR frame byte payloads ready for display.
  Future<Result<List<List<int>>, Failure>> call({
    required String groupId,
    required List<String> remoteKnownOperationIds,
  }) =>
      _repository.buildSyncFrames(
        groupId: groupId,
        remoteKnownOperationIds: remoteKnownOperationIds,
      );
}
