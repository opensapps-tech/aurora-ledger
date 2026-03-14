import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../providers/group_provider.dart';
import '../../widgets/common/aurora_empty_state.dart';
import '../../widgets/common/aurora_loading_indicator.dart';
import '../../widgets/group/group_card.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return AuroraEmptyState(
              icon: Icons.group_off_outlined,
              title: 'No groups yet',
              subtitle: 'Create a group to start sharing expenses with friends.',
              buttonLabel: 'Create group',
              onButtonTap: () => context.push(Routes.createGroup),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return GroupCard(group: groups[index]);
            },
          );
        },
        loading: () => const AuroraLoadingIndicator(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateJoinSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.group_add_outlined),
                title: const Text('Create group'),
                onTap: () {
                  context.pop();
                  context.push(Routes.createGroup);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Join group'),
                onTap: () {
                  context.pop();
                  context.push(Routes.joinGroup);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
