import 'package:flutter/material.dart';

class DebtBar extends StatelessWidget {
  const DebtBar({
    super.key,
    required this.progress,
    this.label,
  });

  final double progress;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: clamped),
        ),
      ],
    );
  }
}
