import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement QrDisplayScreen
class QrDisplayScreen extends ConsumerWidget {
  const QrDisplayScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('QrDisplayScreen')),
      body: const Center(child: Text('TODO: implement QrDisplayScreen')),
    );
  }
}
