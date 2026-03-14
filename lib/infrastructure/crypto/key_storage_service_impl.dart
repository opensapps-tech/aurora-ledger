import 'dart:convert';
import 'package:aurora_ledger/core/constants/crypto_constants.dart';
import 'package:aurora_ledger/core/errors/exceptions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'key_storage_service.dart';

/// flutter_secure_storage implementation — uses Keychain on iOS, Keystore on Android.
class KeyStorageServiceImpl implements KeyStorageService {
  KeyStorageServiceImpl(this._storage);
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
