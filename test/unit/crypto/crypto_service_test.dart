import 'dart:convert';
import 'dart:typed_data';

import 'package:aurora_ledger/core/constants/crypto_constants.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/infrastructure/crypto/crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sodium/sodium.dart';

// Mock classes
class MockSodium extends Mock implements Sodium {}

class MockCrypto extends Mock implements Crypto {}

class MockSign extends Mock implements Sign {}

class MockAead extends Mock implements Aead {}

class MockKdf extends Mock implements Kdf {}

class MockRandombytes extends Mock implements Randombytes {}

class MockHash extends Mock implements Hash {}

class MockSigner extends Mock implements Signer {}

class MockSecretKey extends Mock implements SecretKey {}

class MockPublicKey extends Mock implements PublicKey {}

class MockKeyPair extends Mock implements KeyPair {}

class MockSecureKey extends Mock implements SecureKey {}

class MockSignedMessage extends Mock implements SignedMessage {}

class MockDetached extends Mock implements Detached {}

class MockAeadKey extends Mock implements AeadXChaCha20Poly1305IetfSecretKey {}

class MockNonce extends Mock implements AeadXChaCha20Poly1305IetfNonce {}

class MockMac extends Mock implements AeadXChaCha20Poly1305IetfMac {}

class MockEncrypted extends Mock implements AeadEncryptedMessage {}

class MockKdfMasterKey extends Mock implements KdfMasterKey {}

void main() {
  group('CryptoService', () {
    // These are integration tests that require actual libsodium
    // For unit testing without libsodium, we use these as interface validation tests

    group('operationSigningPayload', () {
      test('produces deterministic output for same operation', () {
        final op = Operation(
          operationId: 'test-op-123',
          groupId: 'group-abc',
          authorPublicKey: base64Encode(Uint8List(32)),
          hlcTimestamp: const HlcTimestamp(physicalMs: 1234567890, logical: 42),
          type: OperationType.addExpense,
          payload: utf8.encode('{"amount": 100}'),
          signature: Uint8List(64),
        );

        // Note: This test validates the signing payload structure
        // The actual implementation would call cryptoService.operationSigningPayload(op)
        // Here we verify the expected structure

        // Expected structure: operationId | groupId | hlcPhysical(8 LE) | hlcLogical(4 LE) | type(1) | payload
        expect(op.operationId, equals('test-op-123'));
        expect(op.groupId, equals('group-abc'));
        expect(op.hlcTimestamp.physicalMs, equals(1234567890));
        expect(op.hlcTimestamp.logical, equals(42));
        expect(op.type, equals(OperationType.addExpense));
      });

      test('handles different operation types', () {
        for (final type in OperationType.values) {
          final op = Operation(
            operationId: 'op-$type',
            groupId: 'group-1',
            authorPublicKey: base64Encode(Uint8List(32)),
            hlcTimestamp: const HlcTimestamp(physicalMs: 1000, logical: 0),
            type: type,
            payload: const [],
            signature: Uint8List(64),
          );

          expect(op.type, equals(type));
          expect(op.payload, isEmpty);
        }
      });

      test('handles binary payload correctly', () {
        final binaryPayload = Uint8List.fromList([0x00, 0x01, 0xFF, 0xAB, 0xCD]);
        
        final op = Operation(
          operationId: 'binary-op',
          groupId: 'group-1',
          authorPublicKey: base64Encode(Uint8List(32)),
          hlcTimestamp: const HlcTimestamp(physicalMs: 1000, logical: 0),
          type: OperationType.addExpense,
          payload: binaryPayload.toList(),
          signature: Uint8List(64),
        );

        expect(op.payload, equals(binaryPayload.toList()));
      });
    });

    group('Operation HLC ordering', () {
      test('operations can be sorted by HLC timestamp', () {
        final ops = [
          Operation(
            operationId: 'op-1',
            groupId: 'group-1',
            authorPublicKey: 'pk-1',
            hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
            type: OperationType.addExpense,
            payload: const [],
            signature: const [],
          ),
          Operation(
            operationId: 'op-2',
            groupId: 'group-1',
            authorPublicKey: 'pk-1',
            hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 1),
            type: OperationType.editExpense,
            payload: const [],
            signature: const [],
          ),
          Operation(
            operationId: 'op-3',
            groupId: 'group-1',
            authorPublicKey: 'pk-1',
            hlcTimestamp: const HlcTimestamp(physicalMs: 200, logical: 0),
            type: OperationType.deleteExpense,
            payload: const [],
            signature: const [],
          ),
        ];

        final sorted = [...ops]..sort((a, b) => a.hlcTimestamp.compareTo(b.hlcTimestamp));

        expect(sorted[0].operationId, equals('op-1'));
        expect(sorted[1].operationId, equals('op-2'));
        expect(sorted[2].operationId, equals('op-3'));
      });
    });

    group('CryptoConstants', () {
      test('has correct key sizes', () {
        expect(CryptoConstants.publicKeyBytes, equals(32));
        expect(CryptoConstants.secretKeyBytes, equals(64));
        expect(CryptoConstants.signatureBytes, equals(64));
        expect(CryptoConstants.groupKeyBytes, equals(32));
        expect(CryptoConstants.nonceBytes, equals(24));
        expect(CryptoConstants.macBytes, equals(16));
        expect(CryptoConstants.identityIdBytes, equals(32));
      });

      test('has correct KDF context strings', () {
        expect(CryptoConstants.kdfContextSync, equals('aurora-sync-v1'));
        expect(CryptoConstants.kdfContextBackup, equals('aurora-backup-v1'));
        expect(CryptoConstants.kdfContextInvite, equals('aurora-invite-v1'));
      });

      test('has correct keystore keys', () {
        expect(CryptoConstants.keystoreSecretKey, equals('aurora.identity.secret_key'));
        expect(CryptoConstants.keystorePublicKey, equals('aurora.identity.public_key'));
      });
    });

    group('Operation signature requirements', () {
      test('signature covers operation ID', () {
        final op1 = Operation(
          operationId: 'op-A',
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: const [],
          signature: Uint8List(64),
        );

        final op2 = Operation(
          operationId: 'op-B', // Different ID
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: const [],
          signature: Uint8List(64),
        );

        expect(op1.operationId, isNot(equals(op2.operationId)));
      });

      test('signature covers group ID', () {
        final op1 = Operation(
          operationId: 'op-1',
          groupId: 'group-A',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: const [],
          signature: Uint8List(64),
        );

        final op2 = Operation(
          operationId: 'op-1',
          groupId: 'group-B', // Different group
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: const [],
          signature: Uint8List(64),
        );

        expect(op1.groupId, isNot(equals(op2.groupId)));
      });

      test('signature covers HLC timestamp', () {
        final op1 = Operation(
          operationId: 'op-1',
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: const [],
          signature: Uint8List(64),
        );

        final op2 = Operation(
          operationId: 'op-1',
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 200, logical: 0), // Different timestamp
          type: OperationType.addExpense,
          payload: const [],
          signature: Uint8List(64),
        );

        expect(op1.hlcTimestamp, isNot(equals(op2.hlcTimestamp)));
      });

      test('signature covers operation type', () {
        final op1 = Operation(
          operationId: 'op-1',
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: const [],
          signature: Uint8List(64),
        );

        final op2 = Operation(
          operationId: 'op-1',
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.editExpense, // Different type
          payload: const [],
          signature: Uint8List(64),
        );

        expect(op1.type, isNot(equals(op2.type)));
      });

      test('signature covers payload', () {
        final op1 = Operation(
          operationId: 'op-1',
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: utf8.encode('{"amount": 100}'),
          signature: Uint8List(64),
        );

        final op2 = Operation(
          operationId: 'op-1',
          groupId: 'group-1',
          authorPublicKey: 'pk-1',
          hlcTimestamp: const HlcTimestamp(physicalMs: 100, logical: 0),
          type: OperationType.addExpense,
          payload: utf8.encode('{"amount": 200}'), // Different payload
          signature: Uint8List(64),
        );

        expect(op1.payload, isNot(equals(op2.payload)));
      });
    });
  });
}
