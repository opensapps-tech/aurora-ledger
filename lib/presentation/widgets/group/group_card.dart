import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../domain/entities/group.dart';
import '../common/aurora_card.dart';
import '../../widgets/sync/sync_status_badge.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      onTap: () => context.push(Routes.groupDetail.replaceFirst(':groupId', group.groupId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SyncStatusBadge(groupId: group.groupId),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group.currency,
                  style: TextStyle(
                    color: Theme.of(context).onPrimaryColorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${group.memberPublicKeys.length} members',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
