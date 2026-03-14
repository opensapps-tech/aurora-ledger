import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement QrScanScreen
class QrScanScreen extends ConsumerWidget {
  const QrScanScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('QrScanScreen')),
      body: const Center(child: Text('TODO: implement QrScanScreen')),
    );
  }
}
