import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/balance.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/aurora_button.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({
    super.key,
    required this.groupId,
    required this.settlement,
  });

  final String groupId;
  final Settlement settlement;

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);

    final result = await ref.read(settlePaymentUsecaseProvider).call(
          groupId: widget.groupId,
          fromIdentityId: widget.settlement.fromIdentityId,
          toIdentityId: widget.settlement.toIdentityId,
          amountMinorUnits: widget.settlement.amountMinorUnits,
          currency: widget.settlement.currency,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      result.when(
        ok: (_) => context.pop(),
        err: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: widget.settlement.currency);
    final amountFormatted = currencyFormat.format(widget.settlement.amountMinorUnits / 100.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Settlement')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.handshake_outlined, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 32),
            Text(
              amountFormatted,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              '${widget.settlement.fromIdentityId.substring(0, 8)} paid ${widget.settlement.toIdentityId.substring(0, 8)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create a signed operation on the ledger to record this payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            AuroraButton(
              label: 'Confirm Settlement',
              isLoading: _isLoading,
              onPressed: _handleConfirm,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
