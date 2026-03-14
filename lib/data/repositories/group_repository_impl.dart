import 'dart:convert';
import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/data/database/daos/group_dao.dart';
import 'package:aurora_ledger/data/database/tables/groups_table.dart';
import 'package:aurora_ledger/domain/entities/group.dart';
import 'package:aurora_ledger/domain/repositories/group_repository.dart';
import 'package:aurora_ledger/infrastructure/crypto/crypto_service.dart';
import 'package:aurora_ledger/infrastructure/crypto/key_storage_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class GroupRepositoryImpl implements GroupRepository {
  const GroupRepositoryImpl(this._dao, this._cryptoService, this._keyStorage);

  final GroupDao _dao;
  final CryptoService _cryptoService;
  final KeyStorageService _keyStorage;

  static const _uuid = Uuid();

  @override
  Future<Result<Group, Failure>> createGroup({
    required String name,
    required String currency,
  }) async {
    try {
      final creatorPubKey = await _keyStorage.loadPublicKey();
      if (creatorPubKey == null) return const Result.err(IdentityNotFoundFailure());

      final groupId = _uuid.v4();
      final groupKey = _cryptoService.generateGroupKey();
      final creatorIdBytes = _cryptoService.sha256(creatorPubKey);
      final creatorIdentityId = base64Encode(creatorIdBytes);
      final pubKeyHex = base64Encode(creatorPubKey);

      await _keyStorage.storeGroupKey(groupId: groupId, key: groupKey);

      final now = DateTime.now().millisecondsSinceEpoch;
      await _dao.insertGroup(GroupsTableCompanion.insert(
        groupId: groupId,
        name: name,
        currency: currency,
        creatorIdentityId: creatorIdentityId,
        memberPublicKeysJson: jsonEncode([pubKeyHex]),
        createdAtMs: now,
      ));

      return Result.ok(Group(
        groupId: groupId,
        name: name,
        currency: currency,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        creatorIdentityId: creatorIdentityId,
        memberPublicKeys: [pubKeyHex],
      ));
    } catch (e) {
      return Result.err(StorageFailure('Failed to create group: $e'));
    }
  }

  @override
  Future<Result<Group, Failure>> getGroup({required String groupId}) async {
    final row = await _dao.getGroup(groupId);
    if (row == null) return Result.err(GroupNotFoundFailure('Group $groupId not found.'));
    return Result.ok(_rowToEntity(row));
  }

  @override
  Future<Result<List<Group>, Failure>> getAllGroups() async {
    final rows = await _dao.getAllGroups();
    return Result.ok(rows.map(_rowToEntity).toList());
  }

  @override
  Future<Result<Group, Failure>> joinGroup({required String invitePayload}) async {
    // TODO: Decrypt invite payload, extract groupId + groupKey + creatorPublicKey,
    //       store group key, insert group row with current device as additional member.
    throw UnimplementedError('joinGroup not yet implemented');
  }

  @override
  Future<Result<String, Failure>> generateInvitePayload({required String groupId}) async {
    // TODO: Encrypt (groupId + groupKey + creatorPublicKey) with HKDF-derived invite key.
    throw UnimplementedError('generateInvitePayload not yet implemented');
  }

  @override
  Future<Result<void, Failure>> updateLastSyncedAt({
    required String groupId,
    required DateTime syncedAt,
  }) async {
    await _dao.updateLastSyncedAt(groupId, syncedAt.millisecondsSinceEpoch);
    return const Result.ok(null);
  }

  @override
  Stream<List<Group>> watchAllGroups() =>
      _dao.watchAllGroups().map((rows) => rows.map(_rowToEntity).toList());

  Group _rowToEntity(GroupRow row) {
    final members = (jsonDecode(row.memberPublicKeysJson) as List).cast<String>();
    return Group(
      groupId: row.groupId,
      name: row.name,
      currency: row.currency,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      creatorIdentityId: row.creatorIdentityId,
      memberPublicKeys: members,
      lastSyncedAt: row.lastSyncedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAtMs!)
          : null,
    );
  }
}
