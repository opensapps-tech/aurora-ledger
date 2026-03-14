import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/identities_table.dart';

part 'identity_dao.g.dart';

@DriftAccessor(tables: [IdentitiesTable])
class IdentityDao extends DatabaseAccessor<AppDatabase> with _$IdentityDaoMixin {
  IdentityDao(super.db);

  Future<void> insertIdentity(IdentitiesTableCompanion identity) =>
      into(identitiesTable).insertOnConflictUpdate(identity);

  Future<IdentityRow?> getLocalIdentity() =>
      (select(identitiesTable)..limit(1)).getSingleOrNull();

  Future<void> updateAlias(String identityId, String alias) =>
      (update(identitiesTable)..where((t) => t.identityId.equals(identityId)))
          .write(IdentitiesTableCompanion(alias: Value(alias)));
}
