import 'dart:convert';

import 'package:aurora_ledger/core/constants/crypto_constants.dart';
import 'package:aurora_ledger/infrastructure/crypto/key_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock implementation for testing
class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _storage.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _storage.remove(key);

  @override
  Future<void> deleteAll({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _storage.clear();

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _storage[key];

  @override
  Future<Map<String, String>> readAll({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => Map.unmodifiable(_storage);

  @override
  Future<void> write({
    required String key,
    required String value,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _storage[key] = value;
}

void main() {
  group('KeyStorageService', () {
    late MockFlutterSecureStorage mockStorage;
    late KeyStorageService keyStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      keyStorage = _KeyStorageServiceImpl(mockStorage);
    });

    tearDown(() async {
      await mockStorage.deleteAll();
    });

    test('storeSecretKey stores key and loadSecretKey retrieves it', () async {
      final secretKey = List<int>.generate(64, (i) => i);

      await keyStorage.storeSecretKey(secretKey);
      final retrieved = await keyStorage.loadSecretKey();

      expect(retrieved, equals(secretKey));
    });

    test('loadSecretKey returns null when no key stored', () async {
      final retrieved = await keyStorage.loadSecretKey();
      expect(retrieved, isNull);
    });

    test('storePublicKey stores key and loadPublicKey retrieves it', () async {
      final publicKey = List<int>.generate(32, (i) => i);

      await keyStorage.storePublicKey(publicKey);
      final retrieved = await keyStorage.loadPublicKey();

      expect(retrieved, equals(publicKey));
    });

    test('loadPublicKey returns null when no key stored', () async {
      final retrieved = await keyStorage.loadPublicKey();
      expect(retrieved, isNull);
    });

    test('storeGroupKey stores key and loadGroupKey retrieves it', () async {
      final groupId = 'test-group-123';
      final groupKey = List<int>.generate(32, (i) => i + 100);

      await keyStorage.storeGroupKey(groupId: groupId, key: groupKey);
      final retrieved = await keyStorage.loadGroupKey(groupId: groupId);

      expect(retrieved, equals(groupKey));
    });

    test('loadGroupKey returns null for unknown group', () async {
      final retrieved = await keyStorage.loadGroupKey(groupId: 'unknown-group');
      expect(retrieved, isNull);
    });

    test('deleteGroupKey removes the group key', () async {
      final groupId = 'test-group-456';
      final groupKey = List<int>.generate(32, (i) => i + 200);

      await keyStorage.storeGroupKey(groupId: groupId, key: groupKey);
      await keyStorage.deleteGroupKey(groupId: groupId);
      final retrieved = await keyStorage.loadGroupKey(groupId: groupId);

      expect(retrieved, isNull);
    });

    test('hasIdentityKey returns false when no identity keys stored', () async {
      final hasKey = await keyStorage.hasIdentityKey();
      expect(hasKey, isFalse);
    });

    test('hasIdentityKey returns true when secret key is stored', () async {
      final secretKey = List<int>.generate(64, (i) => i);
      await keyStorage.storeSecretKey(secretKey);

      final hasKey = await keyStorage.hasIdentityKey();
      expect(hasKey, isTrue);
    });

    test('multiple group keys are stored independently', () async {
      final group1Id = 'group-1';
      final group2Id = 'group-2';
      final group1Key = List<int>.generate(32, (i) => i);
      final group2Key = List<int>.generate(32, (i) => i + 50);

      await keyStorage.storeGroupKey(groupId: group1Id, key: group1Key);
      await keyStorage.storeGroupKey(groupId: group2Id, key: group2Key);

      final retrieved1 = await keyStorage.loadGroupKey(groupId: group1Id);
      final retrieved2 = await keyStorage.loadGroupKey(groupId: group2Id);

      expect(retrieved1, equals(group1Key));
      expect(retrieved2, equals(group2Key));
      expect(retrieved1, isNot(equals(retrieved2)));
    });

    test('deleting one group key does not affect others', () async {
      final group1Id = 'group-1';
      final group2Id = 'group-2';
      final group1Key = List<int>.generate(32, (i) => i);
      final group2Key = List<int>.generate(32, (i) => i + 50);

      await keyStorage.storeGroupKey(groupId: group1Id, key: group1Key);
      await keyStorage.storeGroupKey(groupId: group2Id, key: group2Key);

      await keyStorage.deleteGroupKey(groupId: group1Id);

      final retrieved1 = await keyStorage.loadGroupKey(groupId: group1Id);
      final retrieved2 = await keyStorage.loadGroupKey(groupId: group2Id);

      expect(retrieved1, isNull);
      expect(retrieved2, equals(group2Key));
    });

    test('storing a key overwrites previous value', () async {
      final groupId = 'group-1';
      final originalKey = List<int>.generate(32, (i) => i);
      final newKey = List<int>.generate(32, (i) => i + 100);

      await keyStorage.storeGroupKey(groupId: groupId, key: originalKey);
      await keyStorage.storeGroupKey(groupId: groupId, key: newKey);

      final retrieved = await keyStorage.loadGroupKey(groupId: groupId);
      expect(retrieved, equals(newKey));
      expect(retrieved, isNot(equals(originalKey)));
    });
  });
}

// Simple implementation for testing
class _KeyStorageServiceImpl implements KeyStorageService {
  _KeyStorageServiceImpl(this._storage);
  final FlutterSecureStorage _storage;

  static String _groupKeyStorageKey(String groupId) => 'aurora.group.$groupId.key';

  @override
  Future<void> storeSecretKey(List<int> secretKey) async {
    await _storage.write(
      key: CryptoConstants.keystoreSecretKey,
      value: base64Encode(secretKey),
    );
  }

  @override
  Future<List<int>?> loadSecretKey() async {
    final value = await _storage.read(key: CryptoConstants.keystoreSecretKey);
    return value != null ? base64Decode(value) : null;
  }

  @override
  Future<void> storePublicKey(List<int> publicKey) async {
    await _storage.write(
      key: CryptoConstants.keystorePublicKey,
      value: base64Encode(publicKey),
    );
  }

  @override
  Future<List<int>?> loadPublicKey() async {
    final value = await _storage.read(key: CryptoConstants.keystorePublicKey);
    return value != null ? base64Decode(value) : null;
  }

  @override
  Future<void> storeGroupKey({required String groupId, required List<int> key}) async {
    await _storage.write(key: _groupKeyStorageKey(groupId), value: base64Encode(key));
  }

  @override
  Future<List<int>?> loadGroupKey({required String groupId}) async {
    final value = await _storage.read(key: _groupKeyStorageKey(groupId));
    return value != null ? base64Decode(value) : null;
  }

  @override
  Future<void> deleteGroupKey({required String groupId}) async {
    await _storage.delete(key: _groupKeyStorageKey(groupId));
  }

  @override
  Future<bool> hasIdentityKey() async {
    return await _storage.containsKey(key: CryptoConstants.keystoreSecretKey);
  }
}
