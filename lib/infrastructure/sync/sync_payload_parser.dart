import 'package:aurora_ledger/core/constants/crypto_constants.dart';
import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/infrastructure/crypto/crypto_service.dart';
import 'package:aurora_ledger/infrastructure/crypto/key_storage_service.dart';
import 'package:aurora_ledger/infrastructure/serialization/msgpack_serializer.dart';
import 'package:aurora_ledger/infrastructure/serialization/zstd_compressor.dart';

/// Parses, decrypts and validates a completed sync payload.
class SyncPayloadParser {
  const SyncPayloadParser(
    this._serializer,
    this._compressor,
    this._cryptoService,
    this._keyStorage,
  );

  final MsgpackSerializer _serializer;
  final ZstdCompressor _compressor;
  final CryptoService _cryptoService;
  final KeyStorageService _keyStorage;

  /// Parses a sync payload:
  /// 1. Validates protocol version
  /// 2. Strips version header
  /// 3. Derives sync key via HKDF
  /// 4. Decrypts with XChaCha20-Poly1305
  /// 5. Decompresses with zstd
  /// 6. Deserializes MessagePack to List<Operation>
  ///
  /// Returns [Result.ok(operations)] on success,
  /// [Result.err(SyncPayloadDecryptionFailure)] on decryption error,
  /// [Result.err(SyncPayloadCorruptedFailure)] on deserialization error.
  Future<Result<List<Operation>, Failure>> parse({
    required String groupId,
    required List<int> encryptedPayload,
  }) async {
    try {
      // Validate minimum length
      if (encryptedPayload.length < 1 + CryptoConstants.nonceBytes + CryptoConstants.macBytes) {
        return const Result.err(SyncPayloadCorruptedFailure());
      }

      // 1. Validate protocol version byte
      final version = encryptedPayload[0];
      if (version != SyncConstants.syncProtocolVersion) {
        return const Result.err(SyncPayloadCorruptedFailure());
      }

      // 2. Strip version header, remainder is ciphertext
      final ciphertext = encryptedPayload.sublist(1);

      // 3. Load group key and derive sync key
      final groupKey = await _keyStorage.loadGroupKey(groupId: groupId);
      if (groupKey == null) {
        return const Result.err(GroupNotFoundFailure('Group key not found.'));
      }

      final syncKey = _cryptoService.deriveKey(
        masterKey: groupKey,
        context: CryptoConstants.kdfContextSync,
      );

      // 4. Decrypt with XChaCha20-Poly1305
      final compressed;
      try {
        compressed = await _cryptoService.decrypt(
          ciphertext: ciphertext,
          key: syncKey,
        );
      } catch (e) {
        return const Result.err(SyncPayloadDecryptionFailure());
      }

      // 5. Decompress with zstd
      final serialized;
      try {
        serialized = _compressor.decompress(compressed);
      } catch (e) {
        return const Result.err(SyncPayloadCorruptedFailure());
      }

      // 6. Deserialize MessagePack → List<Operation>
      final operations;
      try {
        operations = _serializer.deserializeOperations(serialized);
      } catch (e) {
        return const Result.err(SyncPayloadCorruptedFailure());
      }

      return Result.ok(operations);
    } catch (e) {
      return Result.err(SyncPayloadCorruptedFailure());
    }
  }
}
