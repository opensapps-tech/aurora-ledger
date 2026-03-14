import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/expense.dart';

abstract interface class ExpenseRepository {
  Future<Result<Expense, Failure>> addExpense({
    required String groupId,
    required int amountMinorUnits,
    required String currency,
    required String payerIdentityId,
    required List<String> participantIdentityIds,
    required String notes,
  });
  Future<Result<Expense, Failure>> editExpense({required String expenseId, required Expense updated});
  Future<Result<void, Failure>> deleteExpense({required String expenseId});
  Future<Result<List<Expense>, Failure>> getExpensesForGroup({required String groupId});
  Future<Result<void, Failure>> settlePayment({
    required String groupId,
    required String fromIdentityId,
    required String toIdentityId,
    required int amountMinorUnits,
  });
  Stream<List<Expense>> watchExpensesForGroup({required String groupId});
}
