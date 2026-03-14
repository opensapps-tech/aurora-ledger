import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/identity.dart';
import 'service_providers.dart';

part 'identity_provider.g.dart';

@riverpod
class IdentityNotifier extends _$IdentityNotifier {
  @override
  Future<Identity?> build() async {
    final result = await ref.read(getIdentityUsecaseProvider).call();
    return result.when(
      ok: (identity) => identity,
      err: (_) => null,
    );
  }

  Future<Result<Identity, Failure>> create({required String alias}) async {
    final result = await ref.read(createIdentityUsecaseProvider).call(alias: alias);
    if (result.isOk) {
      ref.invalidateSelf();
    }
    return result;
  }
}
