import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement SyncScreen
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SyncScreen')),
      body: const Center(child: Text('TODO: implement SyncScreen')),
    );
  }
}
