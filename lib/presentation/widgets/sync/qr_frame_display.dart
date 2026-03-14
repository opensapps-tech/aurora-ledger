import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrFrameDisplay extends StatelessWidget {
  const QrFrameDisplay({
    super.key,
    required this.frameBytes,
    required this.frameIndex,
    required this.totalFrames,
  });

  final Uint8List frameBytes;
  final int frameIndex;
  final int totalFrames;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: QrImageView(
            data: base64Encode(frameBytes),
            version: QrVersions.auto,
            size: 280,
          ),
        ),
        const SizedBox(height: 12),
        Text('Frame $frameIndex of $totalFrames'),
      ],
    );
  }
}
