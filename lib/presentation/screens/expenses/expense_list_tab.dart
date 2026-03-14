import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/aurora_empty_state.dart';
import '../../widgets/common/aurora_loading_indicator.dart';
import '../../widgets/expense/expense_list_tile.dart';

class ExpenseListTab extends ConsumerWidget {
  const ExpenseListTab({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseNotifierProvider(groupId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const AuroraEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            subtitle: 'Tap the + button to add your first expense.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            return ExpenseListTile(expense: expenses[index]);
          },
        );
      },
      loading: () => const AuroraLoadingIndicator(),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
