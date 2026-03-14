import 'package:drift/drift.dart';

@DataClassName('GroupRow')
class GroupsTable extends Table {
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  TextColumn get creatorIdentityId => text()();

  /// JSON-encoded list of member public keys.
  TextColumn get memberPublicKeysJson => text()();

  IntColumn get createdAtMs => integer()();
  IntColumn get lastSyncedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {groupId};
}
