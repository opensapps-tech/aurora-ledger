import 'package:aurora_ledger/core/constants/crypto_constants.dart';
import 'package:aurora_ledger/core/errors/exceptions.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'crypto_service.dart';
// TODO: import sodium package: import 'package:sodium/sodium.dart';

/// libsodium implementation of [CryptoService].
/// All operations are constant-time where required.
class CryptoServiceImpl implements CryptoService {
  // TODO: Inject Sodium instance via constructor after initialising with
  //       SodiumInit.init() in main.dart.
  // const CryptoServiceImpl(this._sodium);
  // final Sodium _sodium;

  @override
  Future<({List<int> publicKey, List<int> secretKey})> generateIdentityKeypair() async {
    // TODO: implement using _sodium.crypto.sign.keyPair()
    throw UnimplementedError('generateIdentityKeypair not yet implemented');
  }

  @override
  Future<List<int>> sign({required List<int> message, required List<int> secretKey}) async {
    // TODO: implement using _sodium.crypto.sign.detached(message, secretKey)
    throw UnimplementedError('sign not yet implemented');
  }

  @override
  Future<bool> verify({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
  }) async {
    // TODO: implement using _sodium.crypto.sign.verifyDetached(message, signature, publicKey)
    throw UnimplementedError('verify not yet implemented');
  }

  @override
  List<int> generateGroupKey() {
    // TODO: implement using _sodium.randombytes.buf(CryptoConstants.groupKeyBytes)
    throw UnimplementedError('generateGroupKey not yet implemented');
  }

  @override
  Future<List<int>> encrypt({required List<int> plaintext, required List<int> key}) async {
    // TODO: implement XChaCha20-Poly1305 with fresh nonce
    // nonce = _sodium.randombytes.buf(CryptoConstants.nonceBytes)
    // ciphertext = _sodium.crypto.aead.xchacha20poly1305Ietf.encrypt(...)
    // return nonce + ciphertext
    throw UnimplementedError('encrypt not yet implemented');
  }

  @override
  Future<List<int>> decrypt({required List<int> ciphertext, required List<int> key}) async {
    // TODO: split nonce (first 24 bytes) from ciphertext, then decrypt
    throw UnimplementedError('decrypt not yet implemented');
  }

  @override
  List<int> deriveKey({required List<int> masterKey, required String context}) {
    // TODO: implement HKDF via _sodium.crypto.kdf.deriveFromKey(...)
    throw UnimplementedError('deriveKey not yet implemented');
  }

  @override
  List<int> sha256(List<int> input) {
    // TODO: implement using _sodium.crypto.hash.sha256(input)
    throw UnimplementedError('sha256 not yet implemented');
  }

  @override
  List<int> operationSigningPayload(Operation operation) {
    // Canonical: operationId (UTF-8) | groupId (UTF-8) | hlc (8+4 bytes LE) | type (1 byte) | payload
    // TODO: implement deterministic byte serialisation
    throw UnimplementedError('operationSigningPayload not yet implemented');
  }
}
