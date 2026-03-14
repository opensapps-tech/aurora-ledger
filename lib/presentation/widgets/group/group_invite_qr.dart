import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GroupInviteQr extends StatelessWidget {
  const GroupInviteQr({
    super.key,
    required this.invitePayload,
    required this.groupCode,
  });

  final String invitePayload;
  final String groupCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: invitePayload,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          groupCode,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Scan this to join the group',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: implement share
          },
          icon: const Icon(Icons.share),
          label: const Text('Share invite'),
        ),
      ],
    );
  }
}
