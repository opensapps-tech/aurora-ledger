import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/app/app.dart';

// TODO: Initialise libsodium via SodiumInit.init() before runApp.
// TODO: Initialise flutter_local_notifications for replica nudges.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: await SodiumInit.init();

  runApp(
    const ProviderScope(
      child: AuroraLedgerApp(),
    ),
  );
}
