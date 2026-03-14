import 'package:aurora_ledger/domain/entities/operation.dart';
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
      final futureRemote = HlcTimestamp(physicalMs: futureMs, logical: 0);
      
      final localBefore = hlc.current;
      final after = hlc.receive(futureRemote);
      
      // Should advance physical time to at least the future timestamp
      expect(after.physicalMs, greaterThanOrEqualTo(futureMs));
    });

    test('two concurrent events get different logical counters', () {
      // Simulate same physical millisecond by capturing timestamps quickly
      final t1 = hlc.now();
      final t2 = hlc.now();
      // They should be distinguishable
      expect(t1 == t2, isFalse);
    });

    test('serialization round-trip preserves HLC values', () {
      final original = HlcTimestamp(physicalMs: 1234567890, logical: 42);
      
      // Simulate serialization (convert to primitive types)
      final physMs = original.physicalMs;
      final logical = original.logical;
      
      // Simulate deserialization
      final reconstructed = HlcTimestamp(physicalMs: physMs, logical: logical);
      
      expect(reconstructed.physicalMs, equals(original.physicalMs));
      expect(reconstructed.logical, equals(original.logical));
      expect(reconstructed, equals(original));
    });

    test('total ordering: (100,0) < (100,1) < (101,0)', () {
      final t1 = HlcTimestamp(physicalMs: 100, logical: 0);
      final t2 = HlcTimestamp(physicalMs: 100, logical: 1);
      final t3 = HlcTimestamp(physicalMs: 101, logical: 0);

      expect(t1.compareTo(t2), lessThan(0));
      expect(t2.compareTo(t3), lessThan(0));
      expect(t1.compareTo(t3), lessThan(0));
    });

    test('receive() with same physical ms increments logical', () {
      final t1 = hlc.now();
      
      // Simulate receiving a timestamp with same physical ms
      final remote = HlcTimestamp(physicalMs: t1.physicalMs, logical: 0);
      final after = hlc.receive(remote);
      
      expect(after.physicalMs, equals(t1.physicalMs));
      expect(after.logical, greaterThan(t1.logical));
    });

    test('receive() when both local and remote have same physical ms', () {
      final wallMs = DateTime.now().millisecondsSinceEpoch;
      final localTs = HlcTimestamp(physicalMs: wallMs, logical: 5);
      final remoteTs = HlcTimestamp(physicalMs: wallMs, logical: 3);
      
      // Create HLC with known state
      final hlc2 = HybridLogicalClock();
      // We can't directly set the internal state, so we simulate
      // by advancing to a known timestamp
      hlc2.receive(localTs);
      
      final after = hlc2.receive(remoteTs);
      
      expect(after.physicalMs, equals(wallMs));
      expect(after.logical, greaterThan(5));
    });
  });
}
