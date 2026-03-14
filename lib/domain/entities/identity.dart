import 'package:equatable/equatable.dart';

/// The cryptographic identity of a device/user.
/// Created once on first launch; stored in the secure enclave / Keystore.
class Identity extends Equatable {
  const Identity({
    required this.identityId,
    required this.publicKey,
    required this.alias,
    required this.createdAt,
    this.avatarPath,
  });

  /// SHA-256(publicKey) — stable 32-byte identifier.
  final String identityId;

  /// Ed25519 public key bytes (hex-encoded for storage).
  final String publicKey;

  /// Human-readable display name. Cosmetic only.
  final String alias;

  final DateTime createdAt;

  /// Optional path to local avatar image.
  final String? avatarPath;

  @override
  List<Object?> get props => [identityId, publicKey, alias, createdAt, avatarPath];
}
