import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/identity.dart';
import 'package:aurora_ledger/domain/repositories/identity_repository.dart';

class CreateIdentityUsecase {
  const CreateIdentityUsecase(this._repository);
  final IdentityRepository _repository;

  Future<Result<Identity, Failure>> call({required String alias, String? avatarPath}) async {
    // TODO: Validate alias is non-empty and within length limits.
    if (alias.trim().isEmpty) {
      return const Result.err(IdentityNotFoundFailure()); // TODO: add AliasEmptyFailure
    }
    return _repository.createIdentity(alias: alias.trim(), avatarPath: avatarPath);
  }
}
