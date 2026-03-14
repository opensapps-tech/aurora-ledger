import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/group.dart';
import 'package:aurora_ledger/domain/repositories/group_repository.dart';
import 'package:aurora_ledger/core/constants/app_constants.dart';

class CreateGroupUsecase {
  const CreateGroupUsecase(this._repository);
  final GroupRepository _repository;

  Future<Result<Group, Failure>> call({required String name, required String currency}) async {
    if (name.trim().isEmpty) return const Result.err(GroupNotFoundFailure('Group name cannot be empty.'));
    if (!AppConstants.supportedCurrencies.contains(currency)) {
      return const Result.err(GroupNotFoundFailure('Unsupported currency.'));
    }
    return _repository.createGroup(name: name.trim(), currency: currency);
  }
}
