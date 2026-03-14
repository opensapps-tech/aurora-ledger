import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';

/// Encrypted backup and restore for identity keypair + all group ledgers.
///
/// Backup payload:
///   HKDF(backup_key, "aurora-backup-v1") → AES-256-GCM encrypt →
///   base64 encode → share via platform share sheet
///
/// Storage destinations: iCloud Drive, Google Drive, local file — user's choice.
/// Aurora never uploads to any Aurora-controlled server.
abstract interface class BackupService {
  /// Creates an encrypted backup blob from the identity key + all group data.
  Future<Result<List<int>, Failure>> createBackup();

  /// Restores identity and groups from an encrypted backup blob.
  Future<Result<void, Failure>> restoreFromBackup(List<int> encryptedBackup);

  /// Exports the backup to the platform share sheet for user-controlled storage.
  Future<Result<void, Failure>> exportBackup(List<int> encryptedBackup);
}
