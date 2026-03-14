import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../providers/replica_status_provider.dart';

class ReplicaStatusBanner extends StatelessWidget {
  const ReplicaStatusBanner({
    super.key,
    required this.status,
    required this.groupId,
  });

  final ReplicaStatus status;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    if (status == ReplicaStatus.ok) return const SizedBox.shrink();

    final color = status == ReplicaStatus.blocked ? Colors.red : Colors.orange;
    final message = status == ReplicaStatus.blocked
        ? 'Sync required to add more expenses.'
        : 'Sync with a group member soon to protect your data.';

    return Material(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: () => context.push(Routes.sync.replaceFirst(':groupId', groupId)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
