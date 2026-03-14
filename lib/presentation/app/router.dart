import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/balance.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/groups/group_detail_screen.dart';
import '../screens/groups/join_group_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/expenses/expense_detail_screen.dart';
import '../screens/balances/balances_screen.dart';
import '../screens/balances/settlement_screen.dart';
import '../screens/sync/sync_screen.dart';
import '../screens/sync/qr_display_screen.dart';
import '../screens/sync/qr_scan_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/backup_screen.dart';
import '../providers/service_providers.dart';

// Route name constants
class Routes {
  Routes._();
  static const onboarding = '/onboarding';
  static const home = '/';
  static const groups = '/groups';
  static const createGroup = '/groups/create';
  static const joinGroup = '/groups/join';
  static const groupDetail = '/groups/:groupId';
  static const addExpense = '/groups/:groupId/expenses/add';
  static const expenseDetail = '/groups/:groupId/expenses/:expenseId';
  static const balances = '/groups/:groupId/balances';
  static const settlement = '/groups/:groupId/balances/settle';
  static const sync = '/groups/:groupId/sync';
  static const qrDisplay = '/groups/:groupId/sync/display';
  static const qrScan = '/groups/:groupId/sync/scan';
  static const settings = '/settings';
  static const backup = '/settings/backup';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) async {
      final hasIdentity = await ref.read(identityRepositoryProvider).hasIdentity();
      final isGoingToOnboarding = state.matchedLocation == Routes.onboarding;

      if (!hasIdentity && !isGoingToOnboarding) {
        return Routes.onboarding;
      }
      if (hasIdentity && isGoingToOnboarding) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: Routes.groups, builder: (_, __) => const GroupsScreen()),
      GoRoute(path: Routes.createGroup, builder: (_, __) => const CreateGroupScreen()),
      GoRoute(path: Routes.joinGroup, builder: (_, __) => const JoinGroupScreen()),
      GoRoute(
        path: Routes.groupDetail,
        builder: (_, state) => GroupDetailScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: Routes.addExpense,
        builder: (_, state) => AddExpenseScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: Routes.sync,
        builder: (_, state) => SyncScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: Routes.qrDisplay,
        builder: (_, state) => QrDisplayScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: Routes.qrScan,
        builder: (_, state) => QrScanScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: Routes.balances,
        builder: (_, state) => BalancesScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: Routes.settlement,
        builder: (_, state) => SettlementScreen(
          groupId: state.pathParameters['groupId']!,
          settlement: state.extra as Settlement,
        ),
      ),
      GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: Routes.backup, builder: (_, __) => const BackupScreen()),
    ],
  );
});
