import 'package:drift/drift.dart';

@DataClassName('IdentityRow')
class IdentitiesTable extends Table {
  TextColumn get identityId => text()();
  TextColumn get publicKeyHex => text()();
  TextColumn get alias => text()();
  TextColumn get avatarPath => text().nullable()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {identityId};
}
