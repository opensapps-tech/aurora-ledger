import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/balance.dart';
import '../common/aurora_card.dart';

class SettlementCard extends StatelessWidget {
  const SettlementCard({
    super.key,
    required this.settlement,
    this.onTap,
  });

  final Settlement settlement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: settlement.currency);
    final amountFormatted = currencyFormat.format(settlement.amountMinorUnits / 100.0);

    return AuroraCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.payment, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: settlement.fromIdentityId.substring(0, 8), // TODO
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' pays '),
                      TextSpan(
                        text: settlement.toIdentityId.substring(0, 8), // TODO
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mark as settled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue),
                ),
              ],
            ),
          ),
          Text(
            amountFormatted,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
