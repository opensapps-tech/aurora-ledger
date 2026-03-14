import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement HomeScreen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('HomeScreen')),
      body: const Center(child: Text('TODO: implement HomeScreen')),
    );
  }
}
