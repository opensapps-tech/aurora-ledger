import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInputField extends StatelessWidget {
  const AmountInputField({
    super.key,
    required this.controller,
    required this.currency,
  });

  final TextEditingController controller;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        prefixText: _getCurrencySymbol(currency),
        hintText: '0.00',
        border: InputBorder.none,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter an amount';
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) return 'Invalid amount';
        return null;
      },
    );
  }

  String _getCurrencySymbol(String code) {
    return switch (code) {
      'USD' => '$',
      'EUR' => '€',
      'GBP' => '£',
      _ => '$code ',
    };
  }
}
