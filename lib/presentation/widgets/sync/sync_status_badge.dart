import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/replica_status_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(replicaStatusNotifierProvider(groupId));

    return statusAsync.when(
      data: (status) {
        final color = switch (status) {
          ReplicaStatus.ok => Colors.green,
          ReplicaStatus.warningSoon => Colors.orange,
          ReplicaStatus.blocked => Colors.red,
        };

        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(width: 12, height: 12),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
