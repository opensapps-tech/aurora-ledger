import 'package:drift/drift.dart';

/// Append-only table for all CRDT operations.
/// Never UPDATE or DELETE rows from this table.
@DataClassName('OperationRow')
class OperationsTable extends Table {
  TextColumn get operationId => text()();
  TextColumn get groupId => text()();
  TextColumn get authorPublicKey => text()();

  /// HLC physical component (Unix milliseconds).
  IntColumn get hlcPhysicalMs => integer()();

  /// HLC logical counter.
  IntColumn get hlcLogical => integer()();

  /// OperationType enum index.
  IntColumn get operationType => integer()();

  /// MessagePack-encoded payload bytes.
  BlobColumn get payload => blob()();

  /// Ed25519 signature bytes.
  BlobColumn get signature => blob()();

  /// Local insertion timestamp (not the HLC). For debugging only.
  IntColumn get insertedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {operationId};
}
