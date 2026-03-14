import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../providers/balance_provider.dart';
import '../../widgets/balance/balance_summary_card.dart';
import '../../widgets/balance/settlement_card.dart';
import '../../widgets/common/aurora_empty_state.dart';
import '../../widgets/common/aurora_loading_indicator.dart';

class BalancesScreen extends ConsumerWidget {
  const BalancesScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceNotifierProvider(groupId));

    return balanceAsync.when(
      data: (data) {
        final balances = data.balances;
        final settlements = data.settlements;

        if (balances.isEmpty) {
          return const AuroraEmptyState(
            icon: Icons.account_balance_outlined,
            title: 'No balances yet',
            subtitle: 'Balances will appear once you add some expenses.',
          );
        }

        if (balances.every((b) => b.netAmountMinorUnits == 0)) {
          return const AuroraEmptyState(
            icon: Icons.done_all,
            title: 'All settled up!',
            subtitle: 'No outstanding debts in this group.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Balances',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...balances.map((b) => BalanceSummaryCard(balance: b)),
            const SizedBox(height: 24),
            if (settlements.isNotEmpty) ...[
              Text(
                'Suggested Settlements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...settlements.map((s) => SettlementCard(
                    settlement: s,
                    onTap: () {
                      // Navigate to settlement confirmation
                      context.push(
                        Routes.settlement.replaceFirst(':groupId', groupId),
                        extra: s,
                      );
                    },
                  )),
            ],
          ],
        );
      },
      loading: () => const AuroraLoadingIndicator(),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
