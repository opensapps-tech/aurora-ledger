import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/group.dart';
import 'service_providers.dart';

part 'group_provider.g.dart';

@riverpod
class GroupNotifier extends _$GroupNotifier {
  @override
  Stream<List<Group>> build() {
    return ref.read(groupRepositoryProvider).watchAllGroups();
  }

  Future<Result<Group, Failure>> create({
    required String name,
    required String currency,
  }) async {
    return await ref.read(createGroupUsecaseProvider).call(
          name: name,
          currency: currency,
        );
  }

  Future<Result<Group, Failure>> join({required String invitePayload}) async {
    return await ref.read(joinGroupUsecaseProvider).call(
          invitePayload: invitePayload,
        );
  }
}
