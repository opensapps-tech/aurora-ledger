import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Failures are expected error states returned via Result<T, Failure>.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Identity ---
final class IdentityAlreadyExistsFailure extends Failure {
  const IdentityAlreadyExistsFailure() : super('Identity already exists on this device.');
}

final class IdentityNotFoundFailure extends Failure {
  const IdentityNotFoundFailure() : super('No identity found. Please complete onboarding.');
}

// --- Group ---
final class GroupNotFoundFailure extends Failure {
  const GroupNotFoundFailure(super.message);
}

final class InvalidInviteFailure extends Failure {
  const InvalidInviteFailure() : super('Invalid or expired group invite.');
}

final class GroupKeyDecryptionFailure extends Failure {
  const GroupKeyDecryptionFailure() : super('Failed to decrypt group invite payload.');
}

// --- Expense ---
final class ExpenseNotFoundFailure extends Failure {
  const ExpenseNotFoundFailure(super.message);
}

final class ReplicaThresholdFailure extends Failure {
  const ReplicaThresholdFailure()
      : super('Sync required before adding expenses (min-replica enforcement).');
}

final class InvalidAmountFailure extends Failure {
  const InvalidAmountFailure() : super('Expense amount must be greater than zero.');
}

// --- Sync ---
final class SyncPayloadDecryptionFailure extends Failure {
  const SyncPayloadDecryptionFailure() : super('Failed to decrypt sync payload.');
}

final class SyncPayloadCorruptedFailure extends Failure {
  const SyncPayloadCorruptedFailure() : super('Sync payload failed integrity check.');
}

final class FrameChecksumFailure extends Failure {
  const FrameChecksumFailure(int frameIndex)
      : super('Frame $frameIndex failed checksum verification.');
}

// --- Crypto ---
final class SignatureVerificationFailure extends Failure {
  const SignatureVerificationFailure() : super('Operation signature verification failed.');
}

final class KeyGenerationFailure extends Failure {
  const KeyGenerationFailure() : super('Failed to generate Ed25519 keypair.');
}

// --- Storage ---
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

// --- Backup ---
final class BackupFailure extends Failure {
  const BackupFailure(super.message);
}
