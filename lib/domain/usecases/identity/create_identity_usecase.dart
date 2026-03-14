import 'package:aurora_ledger/core/constants/app_constants.dart';
import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/identity.dart';
import 'package:aurora_ledger/domain/repositories/identity_repository.dart';

class CreateIdentityUsecase {
  const CreateIdentityUsecase(this._repository);
  final IdentityRepository _repository;

  Future<Result<Identity, Failure>> call({required String alias, String? avatarPath}) async {
    final normalizedAlias = alias.trim();

    if (normalizedAlias.isEmpty) {
      return const Result.err(AliasEmptyFailure());
    }

    if (normalizedAlias.length > AppConstants.maxAliasLength) {
      return const Result.err(AliasTooLongFailure(AppConstants.maxAliasLength));
    }

    return _repository.createIdentity(alias: normalizedAlias, avatarPath: avatarPath);
  }
}
