import 'package:aurora_ledger/core/constants/app_constants.dart';
import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/expense.dart';
import 'package:aurora_ledger/domain/repositories/expense_repository.dart';
import 'package:aurora_ledger/domain/repositories/sync_repository.dart';

class AddExpenseUsecase {
  const AddExpenseUsecase(this._expenseRepository, this._syncRepository);

  final ExpenseRepository _expenseRepository;
  final SyncRepository _syncRepository;

  Future<Result<Expense, Failure>> call({
    required String groupId,
    required int amountMinorUnits,
    required String currency,
    required String payerIdentityId,
    required List<String> participantIdentityIds,
    required String notes,
  }) async {
    // Enforce min-replica contract before writing
    final lastSync = await _syncRepository.getLastSyncTimestamp(groupId: groupId);
    if (lastSync != null &&
        DateTime.now().difference(lastSync).inHours >= AppConstants.replicaBlockThresholdHours) {
      return const Result.err(ReplicaThresholdFailure());
    }

    if (amountMinorUnits <= 0) return const Result.err(InvalidAmountFailure());
    if (participantIdentityIds.isEmpty) {
      return const Result.err(ParticipantsEmptyFailure());
    }

    return _expenseRepository.addExpense(
      groupId: groupId,
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      payerIdentityId: payerIdentityId,
      participantIdentityIds: participantIdentityIds,
      notes: notes,
    );
  }
}
