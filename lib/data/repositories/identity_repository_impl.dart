import 'dart:convert';
import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/data/database/app_database.dart';
import 'package:aurora_ledger/data/database/daos/identity_dao.dart';
import 'package:aurora_ledger/domain/entities/identity.dart';
import 'package:aurora_ledger/domain/repositories/identity_repository.dart';
import 'package:aurora_ledger/infrastructure/crypto/crypto_service.dart';
import 'package:aurora_ledger/infrastructure/crypto/key_storage_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class IdentityRepositoryImpl implements IdentityRepository {
  const IdentityRepositoryImpl(this._dao, this._cryptoService, this._keyStorage);

  final IdentityDao _dao;
  final CryptoService _cryptoService;
  final KeyStorageService _keyStorage;

  @override
  Future<Result<Identity, Failure>> createIdentity({
    required String alias,
    String? avatarPath,
  }) async {
    try {
      if (await _keyStorage.hasIdentityKey()) {
        return const Result.err(IdentityAlreadyExistsFailure());
      }

      final keypair = await _cryptoService.generateIdentityKeypair();
      final identityId = base64Encode(
        _cryptoService.sha256(keypair.publicKey),
      );

      await _keyStorage.storeSecretKey(keypair.secretKey);
      await _keyStorage.storePublicKey(keypair.publicKey);

      final now = DateTime.now().millisecondsSinceEpoch;
      await _dao.insertIdentity(IdentitiesTableCompanion.insert(
        identityId: identityId,
        publicKeyHex: base64Encode(keypair.publicKey),
        alias: alias,
        avatarPath: Value(avatarPath),
        createdAtMs: now,
      ));

      return Result.ok(Identity(
        identityId: identityId,
        publicKey: base64Encode(keypair.publicKey),
        alias: alias,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        avatarPath: avatarPath,
      ));
    } catch (e) {
      return Result.err(StorageFailure('Failed to create identity: $e'));
    }
  }

  @override
  Future<Result<Identity, Failure>> getLocalIdentity() async {
    final row = await _dao.getLocalIdentity();
    if (row == null) return const Result.err(IdentityNotFoundFailure());
    return Result.ok(_rowToEntity(row));
  }

  @override
  Future<Result<Identity, Failure>> updateAlias({required String alias}) async {
    final row = await _dao.getLocalIdentity();
    if (row == null) return const Result.err(IdentityNotFoundFailure());
    await _dao.updateAlias(row.identityId, alias);
    return getLocalIdentity();
  }

  @override
  Future<bool> hasIdentity() => _keyStorage.hasIdentityKey();

  Identity _rowToEntity(IdentityRow row) => Identity(
        identityId: row.identityId,
        publicKey: row.publicKeyHex,
        alias: row.alias,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
        avatarPath: row.avatarPath,
      );
}
