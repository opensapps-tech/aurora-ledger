import 'package:aurora_ledger/domain/entities/balance.dart';
import 'package:aurora_ledger/domain/usecases/balance/simplify_debts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SimplifyDebtsUsecase usecase;

  setUp(() => usecase = const SimplifyDebtsUsecase());

  group('SimplifyDebtsUsecase', () {
    test('produces at most n-1 settlements for n members', () {
      final balances = [
        const MemberBalance(identityId: 'a', alias: 'A', netAmountMinorUnits: 2000, currency: 'GBP'),
        const MemberBalance(identityId: 'b', alias: 'B', netAmountMinorUnits: -500, currency: 'GBP'),
        const MemberBalance(identityId: 'c', alias: 'C', netAmountMinorUnits: -800, currency: 'GBP'),
        const MemberBalance(identityId: 'd', alias: 'D', netAmountMinorUnits: -700, currency: 'GBP'),
      ];

      final result = usecase(balances: balances, currency: 'GBP');
      expect(result.isOk, isTrue);
      expect(result.value.length, lessThanOrEqualTo(balances.length - 1));
    });

    test('settlements sum to zero (net balance is preserved)', () {
      final balances = [
        const MemberBalance(identityId: 'a', alias: 'A', netAmountMinorUnits: 3000, currency: 'GBP'),
        const MemberBalance(identityId: 'b', alias: 'B', netAmountMinorUnits: -1000, currency: 'GBP'),
        const MemberBalance(identityId: 'c', alias: 'C', netAmountMinorUnits: -2000, currency: 'GBP'),
      ];

      final result = usecase(balances: balances, currency: 'GBP');
      expect(result.isOk, isTrue);

      final totalOut = result.value.fold(0, (sum, s) => sum + s.amountMinorUnits);
      final totalOwed = balances
          .where((b) => b.netAmountMinorUnits > 0)
          .fold(0, (sum, b) => sum + b.netAmountMinorUnits);
      expect(totalOut, equals(totalOwed));
    });

    test('returns empty list when all balances are zero', () {
      final balances = [
        const MemberBalance(identityId: 'a', alias: 'A', netAmountMinorUnits: 0, currency: 'GBP'),
        const MemberBalance(identityId: 'b', alias: 'B', netAmountMinorUnits: 0, currency: 'GBP'),
      ];
      final result = usecase(balances: balances, currency: 'GBP');
      expect(result.value.isEmpty, isTrue);
    });
  });
}
