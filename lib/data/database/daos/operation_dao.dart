import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/operations_table.dart';

part 'operation_dao.g.dart';

@DriftAccessor(tables: [OperationsTable])
class OperationDao extends DatabaseAccessor<AppDatabase> with _$OperationDaoMixin {
  OperationDao(super.db);

  Future<void> insertOperation(OperationsTableCompanion op) =>
      into(operationsTable).insertOnConflictUpdate(op);

  Future<List<OperationRow>> getOperationsForGroup(String groupId) =>
      (select(operationsTable)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.asc(t.hlcPhysicalMs),
                       (t) => OrderingTerm.asc(t.hlcLogical)]))
          .get();

  Future<Set<String>> getKnownOperationIds(String groupId) async {
    final rows = await (selectOnly(operationsTable)
          ..addColumns([operationsTable.operationId])
          ..where(operationsTable.groupId.equals(groupId)))
        .get();
    return {for (final r in rows) r.read(operationsTable.operationId)!};
  }

  Stream<List<OperationRow>> watchOperationsForGroup(String groupId) =>
      (select(operationsTable)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.asc(t.hlcPhysicalMs),
                       (t) => OrderingTerm.asc(t.hlcLogical)]))
          .watch();
}
