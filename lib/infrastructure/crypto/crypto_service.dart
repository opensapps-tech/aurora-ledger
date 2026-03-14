import 'package:aurora_ledger/domain/entities/operation.dart';

/// Abstract port for all cryptographic operations.
/// Implementation uses libsodium (constant-time, audited).
abstract interface class CryptoService {
  /// Generates a new Ed25519 keypair. Returns (publicKey, secretKey) bytes.
  Future<({List<int> publicKey, List<int> secretKey})> generateIdentityKeypair();

  /// Signs [message] with [secretKey]. Returns 64-byte Ed25519 signature.
  Future<List<int>> sign({required List<int> message, required List<int> secretKey});

  /// Verifies [signature] over [message] using [publicKey].
  Future<bool> verify({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
  });

  /// Generates a random 32-byte symmetric group key.
  List<int> generateGroupKey();

  /// Encrypts [plaintext] with [key] using XChaCha20-Poly1305.
  /// Returns nonce + ciphertext (nonce prepended, 24 bytes).
  Future<List<int>> encrypt({required List<int> plaintext, required List<int> key});

  /// Decrypts [ciphertext] (nonce prepended) with [key].
  Future<List<int>> decrypt({required List<int> ciphertext, required List<int> key});

  /// HKDF key derivation with domain separation.
  List<int> deriveKey({required List<int> masterKey, required String context});

  /// SHA-256 hash of [input]. Used for identity_id derivation.
  List<int> sha256(List<int> input);

  /// Builds the canonical byte sequence that gets signed for an operation.
  List<int> operationSigningPayload(Operation operation);
}
