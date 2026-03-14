import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/group.dart';

abstract interface class GroupRepository {
  Future<Result<Group, Failure>> createGroup({required String name, required String currency});
  Future<Result<Group, Failure>> getGroup({required String groupId});
  Future<Result<List<Group>, Failure>> getAllGroups();
  Future<Result<Group, Failure>> joinGroup({required String invitePayload});
  Future<Result<String, Failure>> generateInvitePayload({required String groupId});
  Future<Result<void, Failure>> updateLastSyncedAt({required String groupId, required DateTime syncedAt});
  Stream<List<Group>> watchAllGroups();
}
