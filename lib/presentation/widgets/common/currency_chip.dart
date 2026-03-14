import 'package:flutter/material.dart';

class CurrencyChip extends StatelessWidget {
  const CurrencyChip({
    super.key,
    required this.currency,
    this.compact = false,
  });

  final String currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      avatar: const Icon(Icons.currency_exchange, size: 16),
      label: Text(currency.toUpperCase()),
    );
  }
}
