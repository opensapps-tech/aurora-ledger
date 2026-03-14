import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/repositories/expense_repository.dart';

class SettlePaymentUsecase {
  const SettlePaymentUsecase(this._repository);
  final ExpenseRepository _repository;

  Future<Result<void, Failure>> call({
    required String groupId,
    required String fromIdentityId,
    required String toIdentityId,
    required int amountMinorUnits,
  }) =>
      _repository.settlePayment(
        groupId: groupId,
        fromIdentityId: fromIdentityId,
        toIdentityId: toIdentityId,
        amountMinorUnits: amountMinorUnits,
      );
}
