import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & restore'),
            subtitle: const Text('Export and import encrypted local snapshots.'),
            onTap: () => context.push(Routes.backup),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy-first by design'),
            subtitle: Text('No accounts, no servers, no analytics.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('0.1.0'),
          ),
        ],
      ),
    );
  }
}
