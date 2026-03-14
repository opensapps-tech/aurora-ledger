import 'package:aurora_ledger/domain/entities/operation.dart';
import 'conflict_resolver.dart';
import 'operation_log.dart';

/// Merges an incoming set of operations into the local log.
/// Returns the number of new operations actually applied.
class OperationMerger {
  const OperationMerger(this._resolver);
  final ConflictResolver _resolver;

  MergeResult merge({
    required OperationLog local,
    required List<Operation> incoming,
  }) {
    final newOps = <Operation>[];
    final duplicateCount = <String>[];

    for (final op in incoming) {
      if (_resolver.isDuplicate(op, local.knownIds)) {
        duplicateCount.add(op.operationId);
        continue;
      }
      local.add(op);
      newOps.add(op);
    }

    return MergeResult(
      appliedOperations: newOps,
      duplicateIds: duplicateCount,
    );
  }
}

class MergeResult {
  const MergeResult({required this.appliedOperations, required this.duplicateIds});
  final List<Operation> appliedOperations;
  final List<String> duplicateIds;
  int get appliedCount => appliedOperations.length;
}
