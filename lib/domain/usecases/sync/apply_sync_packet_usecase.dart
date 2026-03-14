import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/repositories/sync_repository.dart';
import 'package:aurora_ledger/domain/repositories/group_repository.dart';

class ApplySyncPacketUsecase {
  const ApplySyncPacketUsecase(this._syncRepository, this._groupRepository);
  final SyncRepository _syncRepository;
  final GroupRepository _groupRepository;

  Future<Result<int, Failure>> call({
    required String groupId,
    required List<int> encryptedPayload,
  }) async {
    final parseResult = await _syncRepository.parseSyncPacket(
      groupId: groupId,
      encryptedPayload: encryptedPayload,
    );
    if (parseResult.isErr) return Result.err(parseResult.failure);

    final applyResult = await _syncRepository.applyIncomingOperations(
      groupId: groupId,
      operations: parseResult.value,
    );
    if (applyResult.isErr) return Result.err(applyResult.failure);

    // Record successful sync timestamp for replica tracking
    await _groupRepository.updateLastSyncedAt(
      groupId: groupId,
      syncedAt: DateTime.now(),
    );

    return applyResult;
  }
}
