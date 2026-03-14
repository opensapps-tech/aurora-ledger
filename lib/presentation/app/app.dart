import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';
import 'theme.dart';
// import 'package:aurora_ledger/l10n/app_localizations.dart';

class AuroraLedgerApp extends ConsumerWidget {
  const AuroraLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Aurora Ledger',
      theme: AuroraTheme.light,
      darkTheme: AuroraTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        // AppLocalizations.delegate, // TODO: uncomment when l10n is generated
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }
}
