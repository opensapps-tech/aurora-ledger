import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement SettlementScreen
class SettlementScreen extends ConsumerWidget {
  const SettlementScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SettlementScreen')),
      body: const Center(child: Text('TODO: implement SettlementScreen')),
    );
  }
}
