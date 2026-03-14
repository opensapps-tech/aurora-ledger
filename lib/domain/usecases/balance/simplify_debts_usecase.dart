import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/balance.dart';

/// Minimises the number of settlement transactions using a greedy min-cost flow.
///
/// Algorithm: pair the largest debtor with the largest creditor, settle the
/// minimum of the two, recurse. Produces at most n-1 transactions for n members.
///
/// Example: 6 people, 40 expenses → ~12 naive → ~4 simplified.
class SimplifyDebtsUsecase {
  const SimplifyDebtsUsecase();

  Result<List<Settlement>, Failure> call({
    required List<MemberBalance> balances,
    required String currency,
  }) {
    final settlements = <Settlement>[];

    // Mutable working copies of balances (minor units)
    final debtors = <({String id, int amount})>[];   // negative balance (owe)
    final creditors = <({String id, int amount})>[]; // positive balance (owed)

    for (final b in balances) {
      if (b.netAmountMinorUnits < 0) {
        debtors.add((id: b.identityId, amount: -b.netAmountMinorUnits));
      } else if (b.netAmountMinorUnits > 0) {
        creditors.add((id: b.identityId, amount: b.netAmountMinorUnits));
      }
    }

    // Greedy pairing
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      debtors.sort((a, b) => b.amount.compareTo(a.amount));
      creditors.sort((a, b) => b.amount.compareTo(a.amount));

      final debtor = debtors.removeAt(0);
      final creditor = creditors.removeAt(0);

      final settled = debtor.amount < creditor.amount ? debtor.amount : creditor.amount;

      settlements.add(Settlement(
        fromIdentityId: debtor.id,
        toIdentityId: creditor.id,
        amountMinorUnits: settled,
        currency: currency,
      ));

      final debtorRemainder = debtor.amount - settled;
      final creditorRemainder = creditor.amount - settled;

      if (debtorRemainder > 0) debtors.add((id: debtor.id, amount: debtorRemainder));
      if (creditorRemainder > 0) creditors.add((id: creditor.id, amount: creditorRemainder));
    }

    return Result.ok(settlements);
  }
}
