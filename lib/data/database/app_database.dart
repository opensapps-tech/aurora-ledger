import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'tables/groups_table.dart';
import 'tables/identities_table.dart';
import 'tables/operations_table.dart';
import 'daos/group_dao.dart';
import 'daos/identity_dao.dart';
import 'daos/operation_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [IdentitiesTable, GroupsTable, OperationsTable],
  daos: [IdentityDao, GroupDao, OperationDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA foreign_keys = ON;');
        },
        onUpgrade: (m, from, to) async {
          // TODO: implement incremental migrations for future schema versions
        },
      );
}

QueryExecutor _openConnection() {
  // TODO: Replace with SQLCipher connection when sqflite_sqlcipher is integrated.
  return SqfliteQueryExecutor.inDatabaseFolder(
    path: 'aurora_ledger.db',
    logStatements: false, // TODO: set to true in debug builds only
  );
}
