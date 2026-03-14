import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/group.dart';
import 'package:aurora_ledger/domain/repositories/group_repository.dart';

class JoinGroupUsecase {
  const JoinGroupUsecase(this._repository);
  final GroupRepository _repository;

  Future<Result<Group, Failure>> call({required String invitePayload}) =>
      _repository.joinGroup(invitePayload: invitePayload);
}
