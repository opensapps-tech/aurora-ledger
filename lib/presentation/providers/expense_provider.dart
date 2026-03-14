import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import 'service_providers.dart';

part 'expense_provider.g.dart';

@riverpod
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Stream<List<Expense>> build(String groupId) {
    return ref.read(expenseRepositoryProvider).watchExpensesForGroup(groupId: groupId);
  }

  Future<Result<Expense, Failure>> add({
    required String groupId,
    required int amountMinorUnits,
    required String currency,
    required String payerIdentityId,
    required List<String> participantIdentityIds,
    required String notes,
  }) async {
    return await ref.read(addExpenseUsecaseProvider).call(
          groupId: groupId,
          amountMinorUnits: amountMinorUnits,
          currency: currency,
          payerIdentityId: payerIdentityId,
          participantIdentityIds: participantIdentityIds,
          notes: notes,
        );
  }
}
