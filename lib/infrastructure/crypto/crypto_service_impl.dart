import 'dart:convert';
import 'dart:typed_data';

import 'package:aurora_ledger/core/constants/crypto_constants.dart';
import 'package:aurora_ledger/core/errors/exceptions.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:sodium/sodium.dart';

import 'crypto_service.dart';

/// libsodium implementation of [CryptoService].
/// All operations are constant-time where required.
class CryptoServiceImpl implements CryptoService {
  const CryptoServiceImpl(this._sodium);
  final Sodium _sodium;

  @override
  Future<({List<int> publicKey, List<int> secretKey})> generateIdentityKeypair() async {
    try {
      final keyPair = await _sodium.crypto.sign.generateKeyPair();
      return (
        publicKey: keyPair.publicKey.toList(),
        secretKey: keyPair.secretKey.toList(),
      );
    } catch (e) {
      throw const CryptoException('Failed to generate Ed25519 keypair');
    }
  }

  @override
  Future<List<int>> sign({required List<int> message, required List<int> secretKey}) async {
    try {
      final secretKeyBytes = Uint8List.fromList(secretKey);
      final messageBytes = Uint8List.fromList(message);
      final signature = await _sodium.crypto.sign.detached(
        message: messageBytes,
        secretKey: await _sodium.crypto.sign.secretKeyFromBytes(secretKeyBytes),
      );
      return signature.toList();
    } catch (e) {
      throw CryptoException('Failed to sign message', cause: e);
    }
  }

  @override
  Future<bool> verify({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
  }) async {
    try {
      final publicKeyBytes = Uint8List.fromList(publicKey);
      final signatureBytes = Uint8List.fromList(signature);
      final messageBytes = Uint8List.fromList(message);
      
      return await _sodium.crypto.sign.verifyDetached(
        message: messageBytes,
        signature: signatureBytes,
        publicKey: await _sodium.crypto.sign.publicKeyFromBytes(publicKeyBytes),
      );
    } catch (e) {
      return false;
    }
  }

  @override
  List<int> generateGroupKey() {
    final key = _sodium.randombytes.buf(CryptoConstants.groupKeyBytes);
    return key.toList();
  }

  @override
  Future<List<int>> encrypt({required List<int> plaintext, required List<int> key}) async {
    try {
      final keyBytes = Uint8List.fromList(key);
      final plaintextBytes = Uint8List.fromList(plaintext);
      
      // Generate a fresh random nonce
      final nonce = _sodium.randombytes.buf(CryptoConstants.nonceBytes);
      
      final ciphertext = await _sodium.crypto.aead.xchacha20poly1305ietf.encrypt(
        message: plaintextBytes,
        secretKey: _sodium.crypto.aead.xchacha20poly1305ietfSecretKeyFromBytes(keyBytes),
        nonce: nonce,
      );
      
      // Prepend nonce to ciphertext
      return [...nonce, ...ciphertext.cipherText, ...ciphertext.mac.bytes];
    } catch (e) {
      throw CryptoException('Failed to encrypt data', cause: e);
    }
  }

  @override
  Future<List<int>> decrypt({required List<int> ciphertext, required List<int> key}) async {
    try {
      if (ciphertext.length < CryptoConstants.nonceBytes + CryptoConstants.macBytes) {
        throw const CryptoException('Ciphertext too short');
      }
      
      final keyBytes = Uint8List.fromList(key);
      
      // Extract nonce (first 24 bytes)
      final nonce = Uint8List.sublistView(
        Uint8List.fromList(ciphertext),
        0,
        CryptoConstants.nonceBytes,
      );
      
      // Extract ciphertext + MAC (remaining bytes)
      final encryptedData = Uint8List.sublistView(
        Uint8List.fromList(ciphertext),
        CryptoConstants.nonceBytes,
      );
      
      // Split ciphertext and MAC
      final cipherTextLength = encryptedData.length - CryptoConstants.macBytes;
      final cipherText = Uint8List.sublistView(encryptedData, 0, cipherTextLength);
      final macBytes = Uint8List.sublistView(
        encryptedData,
        cipherTextLength,
        encryptedData.length,
      );
      
      final mac = await _sodium.crypto.aead.xchacha20poly1305ietfMacFromBytes(macBytes);
      
      final plaintext = await _sodium.crypto.aead.xchacha20poly1305ietf.decrypt(
        cipherText: cipherText,
        secretKey: _sodium.crypto.aead.xchacha20poly1305ietfSecretKeyFromBytes(keyBytes),
        nonce: nonce,
        mac: mac,
      );
      
      return plaintext.toList();
    } catch (e) {
      throw CryptoException('Failed to decrypt data', cause: e);
    }
  }

  @override
  List<int> deriveKey({required List<int> masterKey, required String context}) {
    try {
      if (context.length > _sodium.crypto.kdf.contextBytes) {
        throw const CryptoException('Context string too long');
      }
      
      // Pad context to required length
      final contextPadded = context.padRight(_sodium.crypto.kdf.contextBytes, '\x00');
      final contextBytes = Uint8List.fromList(utf8.encode(contextPadded));
      
      final masterKeyBytes = Uint8List.fromList(masterKey);
      
      // Use subkeyId 0 for deterministic derivation
      final derivedKey = _sodium.crypto.kdf.deriveFromKey(
        masterKey: _sodium.crypto.kdf.masterKeyFromBytes(masterKeyBytes),
        context: contextBytes,
        subkeyId: const SubkeyId(0),
        subkeyLen: _sodium.crypto.kdf.bytesMin,
      );
      
      return derivedKey.toList();
    } catch (e) {
      throw CryptoException('Failed to derive key', cause: e);
    }
  }

  @override
  List<int> sha256(List<int> input) {
    final inputBytes = Uint8List.fromList(input);
    final hash = _sodium.crypto.hash.sha256(input: inputBytes);
    return hash.toList();
  }

  @override
  List<int> operationSigningPayload(Operation operation) {
    // Canonical: operationId (UTF-8) | groupId (UTF-8) | hlc (8+4 bytes LE) | type (1 byte) | payload
    final buffer = BytesBuilder();
    
    // Add operationId as UTF-8
    buffer.add(utf8.encode(operation.operationId));
    
    // Add groupId as UTF-8
    buffer.add(utf8.encode(operation.groupId));
    
    // Add HLC physical component as 8 bytes little-endian
    final hlcPhysicalBytes = ByteData(8)..setInt64(0, operation.hlcTimestamp.physicalMs, Endian.little);
    buffer.add(hlcPhysicalBytes.buffer.asUint8List());
    
    // Add HLC logical component as 4 bytes little-endian
    final hlcLogicalBytes = ByteData(4)..setInt32(0, operation.hlcTimestamp.logical, Endian.little);
    buffer.add(hlcLogicalBytes.buffer.asUint8List());
    
    // Add operation type as 1 byte
    buffer.add([operation.type.index]);
    
    // Add payload
    buffer.add(operation.payload);
    
    return buffer.toBytes();
  }
}
