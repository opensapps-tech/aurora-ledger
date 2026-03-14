import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sodium_libs/sodium_libs.dart';
import 'presentation/app/app.dart';
import 'presentation/providers/sodium_provider.dart';

// TODO: Initialise flutter_local_notifications for replica nudges.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sodium = await SodiumInit.init();

  runApp(
    ProviderScope(
      overrides: [
        sodiumProvider.overrideWithValue(sodium),
      ],
      child: const AuroraLedgerApp(),
    ),
  );
}
