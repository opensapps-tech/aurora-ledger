import 'package:aurora_ledger/domain/entities/operation.dart';

/// Resolves conflicts between concurrent operations.
///
/// Policy (conservative, favours data preservation):
/// - ADD_EXPENSE: no conflict possible (pure append with unique ID)
/// - EDIT_EXPENSE vs EDIT_EXPENSE: last-writer-wins by HLC timestamp
/// - DELETE_EXPENSE vs EDIT_EXPENSE: delete wins
/// - SETTLE_PAYMENT: idempotent; duplicate settle ops are no-ops
///
/// This policy is deterministic — every device will converge to the same state.
class ConflictResolver {
  const ConflictResolver();

  /// Given a sorted list of operations for a single expense, returns the
  /// winning operation. Returns null if the expense is deleted.
  Operation? resolveExpenseOps(List<Operation> opsForExpense) {
    assert(opsForExpense.isNotEmpty, 'Operation list must not be empty');

    // Sort by HLC (ascending = causal order)
    final sorted = [...opsForExpense]
      ..sort((a, b) => a.hlcTimestamp.compareTo(b.hlcTimestamp));

    // If any delete exists, the expense is gone. Delete wins.
    if (sorted.any((op) => op.type == OperationType.deleteExpense)) return null;

    // Last EDIT wins (highest HLC = most recent causal event)
    return sorted.last;
  }

  /// True if [incoming] is a duplicate (same operationId already known).
  bool isDuplicate(Operation incoming, Set<String> knownIds) =>
      knownIds.contains(incoming.operationId);
}
