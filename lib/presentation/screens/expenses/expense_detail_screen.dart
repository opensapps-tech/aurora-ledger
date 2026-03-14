import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/expense_provider.dart';
import '../../widgets/common/aurora_loading_indicator.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
  });

  final String groupId;
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseNotifierProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Expense details')),
      body: expensesAsync.when(
        data: (expenses) {
          final matches = expenses.where((e) => e.expenseId == expenseId);
          if (matches.isEmpty) {
            return const Center(child: Text('Expense not found.'));
          }

          final expense = matches.first;
          final currencyFormat = NumberFormat.simpleCurrency(name: expense.currency);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Amount'),
                subtitle: Text(currencyFormat.format(expense.amountMinorUnits / 100.0)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notes'),
                subtitle: Text(expense.notes.isEmpty ? '—' : expense.notes),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Payer'),
                subtitle: Text(expense.payerIdentityId),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Participants'),
                subtitle: Text(expense.participantIdentityIds.join(', ')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Created'),
                subtitle: Text(expense.createdAt.toIso8601String()),
              ),
              if (expense.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'This expense has been deleted.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          );
        },
        loading: () => const AuroraLoadingIndicator(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
