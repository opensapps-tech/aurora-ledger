import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../providers/group_provider.dart';
import '../../providers/replica_status_provider.dart';
import '../../widgets/common/aurora_loading_indicator.dart';
import '../../widgets/common/replica_status_banner.dart';
import '../balances/balances_screen.dart';
import '../expenses/expense_list_tab.dart'; // I need to create this

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupNotifierProvider);
    final replicaStatusAsync = ref.watch(replicaStatusNotifierProvider(groupId));

    return groupsAsync.when(
      data: (groups) {
        final group = groups.firstWhere((g) => g.groupId == groupId);
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name),
                  Text(
                    group.currency,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => context.push(Routes.sync.replaceFirst(':groupId', groupId)),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // TODO: handle menu actions
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'invite', child: Text('Invite member')),
                    const PopupMenuItem(value: 'info', child: Text('Group info')),
                  ],
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Expenses'),
                  Tab(text: 'Balances'),
                ],
              ),
            ),
            body: Column(
              children: [
                replicaStatusAsync.when(
                  data: (status) => ReplicaStatusBanner(status: status, groupId: groupId),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ExpenseListTab(groupId: groupId),
                      BalancesScreen(groupId: groupId),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push(Routes.addExpense.replaceFirst(':groupId', groupId)),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: AuroraLoadingIndicator()),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
