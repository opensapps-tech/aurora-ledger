import 'package:aurora_ledger/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end app flow', () {
    testWidgets('onboarding → create identity → create group', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // TODO: Implement full onboarding flow test.
      // 1. Expect onboarding screen
      // 2. Enter alias
      // 3. Tap continue
      // 4. Expect home screen
      // 5. Tap create group
      // 6. Enter name + currency
      // 7. Expect group detail screen
    });

    testWidgets('add expense reflects in balance', (tester) async {
      // TODO: implement
    });
  });
}
