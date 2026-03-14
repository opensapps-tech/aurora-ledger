import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/balance.dart';
import 'package:aurora_ledger/domain/entities/expense.dart';

/// Projects the list of expenses into per-member net balances.
class ComputeBalancesUsecase {
  const ComputeBalancesUsecase();

  Result<List<MemberBalance>, Failure> call({
    required List<Expense> expenses,
    required Map<String, String> identityAliases, // identityId → alias
    required String currency,
  }) {
    final balances = <String, int>{};

    for (final expense in expenses) {
      if (expense.isDeleted) continue;

      // Payer is owed the full amount
      balances[expense.payerIdentityId] =
          (balances[expense.payerIdentityId] ?? 0) + expense.amountMinorUnits;

      // Each participant owes their share
      final shareMinorUnits = expense.amountMinorUnits ~/ expense.participantIdentityIds.length;
      for (final participantId in expense.participantIdentityIds) {
        balances[participantId] = (balances[participantId] ?? 0) - shareMinorUnits;
      }
    }

    final result = balances.entries.map((entry) {
      return MemberBalance(
        identityId: entry.key,
        alias: identityAliases[entry.key] ?? entry.key.substring(0, 8),
        netAmountMinorUnits: entry.value,
        currency: currency,
      );
    }).toList()
      ..sort((a, b) => b.netAmountMinorUnits.compareTo(a.netAmountMinorUnits));

    return Result.ok(result);
  }
}
