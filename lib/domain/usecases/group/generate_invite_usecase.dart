import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/repositories/group_repository.dart';

class GenerateInviteUsecase {
  const GenerateInviteUsecase(this._repository);
  final GroupRepository _repository;

  Future<Result<String, Failure>> call({required String groupId}) =>
      _repository.generateInvitePayload(groupId: groupId);
}
