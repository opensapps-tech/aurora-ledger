import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/balance.dart';
import 'expense_provider.dart';
import 'service_providers.dart';

part 'balance_provider.g.dart';

@riverpod
class BalanceNotifier extends _$BalanceNotifier {
  @override
  Future<({List<MemberBalance> balances, List<Settlement> settlements})> build(
    String groupId,
  ) async {
    final expenses = await ref.watch(expenseNotifierProvider(groupId).future);
    
    final groupResult = await ref.read(groupRepositoryProvider).getGroup(groupId: groupId);
    final group = groupResult.when(
      ok: (g) => g,
      err: (f) => throw Exception(f.message),
    );

    // TODO: In a later phase, load member aliases from the identity repository/DAO.
    // For now, we pass an empty map and the usecase will fallback to ID substrings.
    final Map<String, String> identityAliases = {};

    final balancesResult = ref.read(computeBalancesUsecaseProvider).call(
      expenses: expenses,
      identityAliases: identityAliases,
      currency: group.currency,
    );

    final balances = balancesResult.when(
      ok: (b) => b,
      err: (f) => throw Exception(f.message),
    );

    final settlementsResult = ref.read(simplifyDebtsUsecaseProvider).call(
      balances: balances,
    );

    final settlements = settlementsResult.when(
      ok: (s) => s,
      err: (f) => throw Exception(f.message),
    );

    return (balances: balances, settlements: settlements);
  }
}
