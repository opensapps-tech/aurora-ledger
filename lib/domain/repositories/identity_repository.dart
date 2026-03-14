import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/identity.dart';

abstract interface class IdentityRepository {
  /// Returns the local identity if one exists.
  Future<Result<Identity, Failure>> getLocalIdentity();

  /// Creates a new identity: generates Ed25519 keypair, stores in secure storage.
  Future<Result<Identity, Failure>> createIdentity({required String alias, String? avatarPath});

  /// Updates the display alias only. Does not touch the keypair.
  Future<Result<Identity, Failure>> updateAlias({required String alias});

  /// True if an identity keypair exists in secure storage.
  Future<bool> hasIdentity();
}
