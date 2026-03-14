import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/group_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  bool _isJoining = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isJoining) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isJoining = true);

    final result = await ref.read(groupNotifierProvider.notifier).join(invitePayload: code);

    if (mounted) {
      result.when(
        ok: (group) {
          context.pop();
        },
        err: (failure) {
          setState(() => _isJoining = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid group invite: ${failure.message}')),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isJoining)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Scan the invite QR code',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
