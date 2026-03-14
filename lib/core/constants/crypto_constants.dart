// WARNING: Do not change these values after shipping v1.
// Changing them breaks all existing signed operations and encrypted payloads.

/// Cryptographic constants — aligned with libsodium / NaCl primitives.
class CryptoConstants {
  CryptoConstants._();

  // Ed25519 identity keypair
  static const int publicKeyBytes = 32;
  static const int secretKeyBytes = 64;
  static const int signatureBytes = 64;

  // XChaCha20-Poly1305 group encryption
  static const int groupKeyBytes = 32;
  static const int nonceBytes = 24;
  static const int macBytes = 16;

  // Identity fingerprint (SHA-256 of public key)
  static const int identityIdBytes = 32;

  // HKDF domain separation labels
  static const String kdfContextSync = 'aurora-sync-v1';
  static const String kdfContextBackup = 'aurora-backup-v1';
  static const String kdfContextInvite = 'aurora-invite-v1';

  // flutter_secure_storage keys
  static const String keystoreSecretKey = 'aurora.identity.secret_key';
  static const String keystorePublicKey = 'aurora.identity.public_key';
}
