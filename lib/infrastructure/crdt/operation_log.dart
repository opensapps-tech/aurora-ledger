import 'package:aurora_ledger/domain/entities/operation.dart';

/// In-memory projection of the operation log for a single group.
/// The source of truth is the SQLite operations table; this is a cache.
class OperationLog {
  OperationLog(this.groupId);

  final String groupId;
  final List<Operation> _operations = [];

  /// All operations sorted by HLC timestamp (causal order).
  List<Operation> get sorted => List.unmodifiable(
        _operations..sort((a, b) => a.hlcTimestamp.compareTo(b.hlcTimestamp)),
      );

  /// Set of all known operation IDs on this device.
  Set<String> get knownIds => {for (final op in _operations) op.operationId};

  void add(Operation operation) {
    if (!knownIds.contains(operation.operationId)) {
      _operations.add(operation);
    }
  }

  void addAll(Iterable<Operation> operations) {
    for (final op in operations) add(op);
  }

  /// Returns operations the remote device (identified by its known IDs) is missing.
  List<Operation> missingFrom(Set<String> remoteKnownIds) =>
      sorted.where((op) => !remoteKnownIds.contains(op.operationId)).toList();
}
