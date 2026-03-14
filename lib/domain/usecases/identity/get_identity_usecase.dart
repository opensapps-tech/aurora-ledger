import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/identity.dart';
import 'package:aurora_ledger/domain/repositories/identity_repository.dart';

class GetIdentityUsecase {
  const GetIdentityUsecase(this._repository);
  final IdentityRepository _repository;

  Future<Result<Identity, Failure>> call() => _repository.getLocalIdentity();
}
