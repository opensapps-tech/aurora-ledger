import 'dart:convert';

import 'package:aurora_ledger/infrastructure/serialization/zstd_compressor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZstdCompressor', () {
    late ZstdCompressor compressor;

    setUp(() {
      compressor = const ZstdCompressor();
    });

    test('round-trip preserves bytes', () {
      final original = utf8.encode('Hello, World! This is a test message for compression.');
      
      final compressed = compressor.compress(original);
      final decompressed = compressor.decompress(compressed);
      
      expect(decompressed, equals(original));
    });

    test('compression reduces size for repetitive data', () {
      // Create repetitive data that compresses well
      final repetitiveData = utf8.encode('ABC' * 1000);
      
      final compressed = compressor.compress(repetitiveData);
      
      // Compressed should be smaller than original
      expect(compressed.length, lessThan(repetitiveData.length));
      
      // Verify round-trip
      final decompressed = compressor.decompress(compressed);
      expect(decompressed, equals(repetitiveData));
    });

    test('handles empty data', () {
      final empty = <int>[];
      
      final compressed = compressor.compress(empty);
      final decompressed = compressor.decompress(compressed);
      
      expect(decompressed, equals(empty));
    });

    test('handles binary data', () {
      final binaryData = List<int>.generate(256, (i) => i);
      
      final compressed = compressor.compress(binaryData);
      final decompressed = compressor.decompress(compressed);
      
      expect(decompressed, equals(binaryData));
    });

    test('handles large data', () {
      final largeData = List<int>.generate(100000, (i) => i % 256);
      
      final compressed = compressor.compress(largeData);
      final decompressed = compressor.decompress(compressed);
      
      expect(decompressed, equals(largeData));
    });

    test('handles JSON data', () {
      final jsonData = utf8.encode(jsonEncode({
        'operations': List.generate(100, (i) => {
          'id': 'op-$i',
          'groupId': 'group-${i % 10}',
          'type': 'addExpense',
          'amount': 1000 + i,
        }),
      }));
      
      final compressed = compressor.compress(jsonData);
      final decompressed = compressor.decompress(compressed);
      
      expect(decompressed, equals(jsonData));
    });

    test('handles data with special characters', () {
      final specialData = utf8.encode('Hello\x00World\xFF\xFE\xFD');
      
      final compressed = compressor.compress(specialData);
      final decompressed = compressor.decompress(compressed);
      
      expect(decompressed, equals(specialData));
    });

    test('multiple compressions produce consistent results', () {
      final data = utf8.encode('Test data for consistent compression');
      
      final compressed1 = compressor.compress(data);
      final compressed2 = compressor.compress(data);
      
      // Both compressed versions should decompress to the same data
      expect(compressor.decompress(compressed1), equals(data));
      expect(compressor.decompress(compressed2), equals(data));
    });
  });
}
