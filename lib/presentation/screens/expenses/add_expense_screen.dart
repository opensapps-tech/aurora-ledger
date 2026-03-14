import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement AddExpenseScreen
class AddExpenseScreen extends ConsumerWidget {
  const AddExpenseScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('AddExpenseScreen')),
      body: const Center(child: Text('TODO: implement AddExpenseScreen')),
    );
  }
}
