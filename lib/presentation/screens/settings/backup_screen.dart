import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Create backup',
            subtitle: 'Export an encrypted file to local storage.',
            buttonLabel: 'Export backup',
          ),
          SizedBox(height: 12),
          _ActionCard(
            icon: Icons.download_for_offline_outlined,
            title: 'Restore backup',
            subtitle: 'Import an encrypted file from local storage.',
            buttonLabel: 'Import backup',
          ),
          SizedBox(height: 16),
          Text(
            'Backups never leave your device unless you manually share the file.',
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon.')),
                );
              },
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
