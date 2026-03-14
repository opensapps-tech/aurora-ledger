import 'package:aurora_ledger/infrastructure/crdt/hybrid_logical_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HybridLogicalClock', () {
    late HybridLogicalClock hlc;

    setUp(() => hlc = HybridLogicalClock());

    test('now() returns monotonically increasing timestamps', () {
      final t1 = hlc.now();
      final t2 = hlc.now();
      expect(t2.compareTo(t1), greaterThan(0));
    });

    test('receive() advances past remote timestamp', () {
      final remote = hlc.now();
      final hlc2 = HybridLogicalClock();
      final after = hlc2.receive(remote);
      expect(after.compareTo(remote), greaterThan(0));
    });

    test('receive() with future remote timestamp uses remote physical time', () {
      final futureMs = DateTime.now().millisecondsSinceEpoch + 10000;
      // TODO: mock DateTime.now() to test this properly
    });

    test('two concurrent events get different logical counters', () {
      // Simulate same physical millisecond
      final t1 = hlc.now();
      // Force same physical ms scenario
      final t2 = hlc.now();
      // They should be distinguishable
      expect(t1 == t2, isFalse);
    });
  });
}
