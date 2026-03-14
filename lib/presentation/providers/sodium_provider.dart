import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sodium/sodium.dart';

/// Provider for the libsodium Sodium instance.
/// Must be initialized via SodiumInit.init() before use.
final sodiumProvider = Provider<Sodium>((ref) {
  throw UnimplementedError(
    'Sodium must be initialized before accessing this provider. '
    'Call SodiumInit.init() in main() and override this provider with the result.',
  );
});
