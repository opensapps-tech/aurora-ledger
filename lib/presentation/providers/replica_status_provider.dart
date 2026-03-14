import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/app_constants.dart';
import 'service_providers.dart';

part 'replica_status_provider.g.dart';

enum ReplicaStatus { ok, warningSoon, blocked }

@riverpod
class ReplicaStatusNotifier extends _$ReplicaStatusNotifier {
  @override
  Future<ReplicaStatus> build(String groupId) async {
    final lastSync = await ref.watch(syncRepositoryProvider)
        .getLastSyncTimestamp(groupId: groupId);
        
    if (lastSync == null) {
      return ReplicaStatus.ok; // First device, no sync needed yet
    }
    
    final hoursAgo = DateTime.now().difference(lastSync).inHours;
    
    if (hoursAgo >= AppConstants.replicaBlockThresholdHours) {
      return ReplicaStatus.blocked;
    }
    if (hoursAgo >= AppConstants.replicaWarnThresholdHours) {
      return ReplicaStatus.warningSoon;
    }
    return ReplicaStatus.ok;
  }
}
