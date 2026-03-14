import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/sync/frame_progress_indicator.dart';
import '../../widgets/sync/qr_scanner_overlay.dart';

class QrScanScreen extends ConsumerWidget {
  const QrScanScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Partner QR')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawBytes != null) {
                  ref.read(syncNotifierProvider(groupId).notifier)
                      .onFrameScanned(barcode.rawBytes!);
                }
              }
            },
          ),
          const QrScannerOverlay(),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                FrameProgressIndicator(
                  progress: syncState.scanProgress,
                ),
                if (syncState.phase == SyncPhase.receiving)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                if (syncState.phase == SyncPhase.complete)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Complete'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
