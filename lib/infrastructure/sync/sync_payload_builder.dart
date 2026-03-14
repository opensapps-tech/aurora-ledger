import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'package:aurora_ledger/core/errors/failures.dart';
import 'package:aurora_ledger/core/utils/result.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:aurora_ledger/infrastructure/crypto/crypto_service.dart';
import 'package:aurora_ledger/infrastructure/crypto/key_storage_service.dart';
import 'package:aurora_ledger/infrastructure/serialization/msgpack_serializer.dart';
import 'package:aurora_ledger/infrastructure/serialization/zstd_compressor.dart';
import 'qr_frame_encoder.dart';

/// Builds an encrypted, compressed sync payload ready for QR frame encoding.
///
/// Pipeline: operations → MessagePack → zstd compress → XChaCha20 encrypt → RS frames
class SyncPayloadBuilder {
  const SyncPayloadBuilder(
    this._serializer,
    this._compressor,
    this._cryptoService,
    this._keyStorage,
    this._frameEncoder,
  );

  final MsgpackSerializer _serializer;
  final ZstdCompressor _compressor;
  final CryptoService _cryptoService;
  final KeyStorageService _keyStorage;
  final QrFrameEncoder _frameEncoder;

  Future<Result<List<List<int>>, Failure>> buildFrames({
    required String groupId,
    required List<Operation> operations,
  }) async {
    // 1. Serialize
    final serialized = _serializer.serializeOperations(operations);

    // 2. Compress
    final compressed = _compressor.compress(serialized);

    // 3. Load group key and derive sync key
    final groupKey = await _keyStorage.loadGroupKey(groupId: groupId);
    if (groupKey == null) return const Result.err(GroupNotFoundFailure('Group key not found.'));

    final syncKey = _cryptoService.deriveKey(
      masterKey: groupKey,
      context: 'aurora-sync-v1',
    );

    // 4. Encrypt
    final encrypted = await _cryptoService.encrypt(plaintext: compressed, key: syncKey);

    // 5. Prepend protocol version header
    final withHeader = [SyncConstants.syncProtocolVersion, ...encrypted];

    // 6. Frame encode (split + RS ECC)
    final frames = _frameEncoder.encode(withHeader);

    return Result.ok(frames);
  }
}
