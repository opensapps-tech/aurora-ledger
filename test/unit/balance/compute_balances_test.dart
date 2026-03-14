import 'package:aurora_ledger/domain/entities/balance.dart';
import 'package:aurora_ledger/domain/entities/expense.dart';
import 'package:aurora_ledger/domain/usecases/balance/compute_balances_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ComputeBalancesUsecase usecase;

  setUp(() => usecase = const ComputeBalancesUsecase());

  group('ComputeBalancesUsecase', () {
    test('single expense — payer is owed, participants owe', () {
      final expenses = [
        _makeExpense(
          amount: 3000, // £30.00
          payer: 'alice',
          participants: ['alice', 'bob', 'charlie'],
        ),
      ];

      final result = usecase(
        expenses: expenses,
        identityAliases: {'alice': 'Alice', 'bob': 'Bob', 'charlie': 'Charlie'},
        currency: 'GBP',
      );

      expect(result.isOk, isTrue);
      final balances = result.value;

      final alice = balances.firstWhere((b) => b.identityId == 'alice');
      final bob = balances.firstWhere((b) => b.identityId == 'bob');

      // Alice paid £30, owes £10 share → net +£20
      expect(alice.netAmountMinorUnits, equals(3000 - 1000));
      // Bob owes £10
      expect(bob.netAmountMinorUnits, equals(-1000));
    });

    test('deleted expense is excluded from balance', () {
      final expenses = [
        _makeExpense(amount: 1000, payer: 'alice', participants: ['alice', 'bob'], deleted: true),
      ];
      final result = usecase(
        expenses: expenses,
        identityAliases: {'alice': 'Alice', 'bob': 'Bob'},
        currency: 'GBP',
      );
      expect(result.isOk, isTrue);
      expect(result.value.isEmpty, isTrue);
    });

    test('all settled — net balances are zero', () {
      // TODO: add settlement operation scenario
    });
  });
}

Expense _makeExpense({
  required int amount,
  required String payer,
  required List<String> participants,
  bool deleted = false,
}) =>
    Expense(
      expenseId: 'exp-${payer}-$amount',
      groupId: 'group-1',
      amountMinorUnits: amount,
      currency: 'GBP',
      payerIdentityId: payer,
      participantIdentityIds: participants,
      notes: 'test',
      createdAt: DateTime.now(),
      authorPublicKey: payer,
      isDeleted: deleted,
    );
