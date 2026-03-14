import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement ExpenseDetailScreen
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ExpenseDetailScreen')),
      body: const Center(child: Text('TODO: implement ExpenseDetailScreen')),
    );
  }
}
