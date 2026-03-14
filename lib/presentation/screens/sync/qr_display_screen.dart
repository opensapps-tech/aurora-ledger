import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/sync_provider.dart';

class QrDisplayScreen extends ConsumerWidget {
  const QrDisplayScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider(groupId));
    final frames = syncState.outboundFrames;
    
    if (frames.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sending...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentFrame = frames[syncState.currentFrameIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Show this QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
                data: currentFrame.toString(), // Simplified for now
                version: QrVersions.auto,
                size: 280,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Frame ${syncState.currentFrameIndex + 1} of ${frames.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: (syncState.currentFrameIndex + 1) / frames.length,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
