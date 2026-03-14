import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement BalancesScreen
class BalancesScreen extends ConsumerWidget {
  const BalancesScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('BalancesScreen')),
      body: const Center(child: Text('TODO: implement BalancesScreen')),
    );
  }
}
