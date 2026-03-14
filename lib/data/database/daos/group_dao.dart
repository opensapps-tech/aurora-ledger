import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/groups_table.dart';

part 'group_dao.g.dart';

@DriftAccessor(tables: [GroupsTable])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);

  Future<void> insertGroup(GroupsTableCompanion group) =>
      into(groupsTable).insertOnConflictUpdate(group);

  Future<GroupRow?> getGroup(String groupId) =>
      (select(groupsTable)..where((t) => t.groupId.equals(groupId))).getSingleOrNull();

  Future<List<GroupRow>> getAllGroups() =>
      (select(groupsTable)..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])).get();

  Stream<List<GroupRow>> watchAllGroups() =>
      (select(groupsTable)..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])).watch();

  Future<void> updateLastSyncedAt(String groupId, int syncedAtMs) =>
      (update(groupsTable)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsTableCompanion(lastSyncedAtMs: Value(syncedAtMs)));
}
