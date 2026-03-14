import 'package:flutter/material.dart';
import '../../../domain/entities/expense.dart';
import 'package:intl/intl.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: expense.currency);
    final amountFormatted = currencyFormat.format(expense.amountMinorUnits / 100.0);

    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.receipt_outlined),
      ),
      title: Text(
        expense.notes,
        style: TextStyle(
          decoration: expense.isDeleted ? TextDecoration.lineThrough : null,
          color: expense.isDeleted ? Colors.grey : null,
        ),
      ),
      subtitle: Text('Paid by ${expense.payerIdentityId.substring(0, 8)}'),
      trailing: Text(
        amountFormatted,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          decoration: expense.isDeleted ? TextDecoration.lineThrough : null,
          color: expense.isDeleted ? Colors.grey : null,
        ),
      ),
      onTap: () {
        // TODO: navigate to detail
      },
    );
  }
}
