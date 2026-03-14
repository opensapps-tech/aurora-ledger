import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/aurora_button.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  int _activeStep = 0;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bilateral Sync')),
      body: Stepper(
        currentStep: _activeStep,
        onStepContinue: () {
          if (_activeStep < 3) {
            setState(() => _activeStep++);
          }
        },
        onStepCancel: () {
          if (_activeStep > 0) {
            setState(() => _activeStep--);
          }
        },
        steps: [
          Step(
            title: const Text('Handshake'),
            content: Column(
              children: [
                const Text('Step 1: Show your handshake QR to your partner.'),
                const SizedBox(height: 16),
                // TODO: Handshake QR
                AuroraButton(
                  label: 'Next',
                  onPressed: () => setState(() => _activeStep = 1),
                  isFullWidth: false,
                ),
              ],
            ),
            isActive: _activeStep >= 0,
          ),
          Step(
            title: const Text('Scan Partner'),
            content: Column(
              children: [
                const Text("Step 2: Scan your partner's handshake QR."),
                const SizedBox(height: 16),
                AuroraButton(
                  label: 'Open Scanner',
                  onPressed: () {
                    // In a real app, this would open QrScanScreen and return results
                    setState(() => _activeStep = 2);
                  },
                  isFullWidth: false,
                ),
              ],
            ),
            isActive: _activeStep >= 1,
          ),
          Step(
            title: const Text('Send Operations'),
            content: Column(
              children: [
                const Text('Step 3: Partner scans your sync QR.'),
                const SizedBox(height: 16),
                AuroraButton(
                  label: 'Show Sync QR',
                  onPressed: () {
                    context.push(Routes.qrDisplay.replaceFirst(':groupId', widget.groupId));
                    setState(() => _activeStep = 3);
                  },
                  isFullWidth: false,
                ),
              ],
            ),
            isActive: _activeStep >= 2,
          ),
          Step(
            title: const Text('Receive Operations'),
            content: Column(
              children: [
                const Text('Step 4: Scan your partner\'s sync QR.'),
                const SizedBox(height: 16),
                AuroraButton(
                  label: 'Scan Partner Sync QR',
                  onPressed: () {
                    context.push(Routes.qrScan.replaceFirst(':groupId', widget.groupId));
                  },
                  isFullWidth: false,
                ),
                if (syncState.phase == SyncPhase.complete)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text('Sync Complete!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            isActive: _activeStep >= 3,
          ),
        ],
      ),
    );
  }
}
