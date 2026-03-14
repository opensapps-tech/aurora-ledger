import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/balance.dart';
import '../common/aurora_card.dart';
import '../common/identity_avatar.dart';

class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({super.key, required this.balance});

  final MemberBalance balance;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: balance.currency);
    final amount = balance.netAmountMinorUnits / 100.0;
    final amountFormatted = currencyFormat.format(amount.abs());
    
    final isOwed = balance.netAmountMinorUnits > 0;
    final isOwes = balance.netAmountMinorUnits < 0;
    final isSettled = balance.netAmountMinorUnits == 0;

    final color = isOwed ? Colors.green : (isOwes ? Colors.red : Colors.grey);
    final statusText = isOwed ? 'is owed' : (isOwes ? 'owes' : 'is settled');

    return AuroraCard(
      child: Row(
        children: [
          IdentityAvatar(identityId: balance.identityId, alias: balance.alias),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance.alias,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (!isSettled)
            Text(
              amountFormatted,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
