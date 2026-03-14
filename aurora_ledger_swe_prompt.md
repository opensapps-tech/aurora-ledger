# Aurora Ledger — SWE Agent Task Sequence

> **Feed this document directly to the SWE agent at session start.**
> It is self-contained. All architectural decisions are final. Do not re-derive them.

---

## 0. Briefing

You are implementing **Aurora Ledger** — a fully offline, privacy-first expense sharing mobile app built with Flutter. There are no servers, no accounts, no telemetry. The repo scaffold already exists at the path you have been given. Your job is to implement files that currently contain `// TODO` or `throw UnimplementedError`.

### Non-negotiable constraints
- **Zero infrastructure.** Never introduce a network call, remote API, cloud SDK, or analytics library. Every `http`, `dio`, `firebase_*`, `supabase`, or `amplitude` import is a hard block.
- **Constant-time crypto only.** All cryptographic operations go through `CryptoService` / libsodium. Never call `dart:math Random` for security-sensitive values. Never roll your own primitives.
- **Amounts are always integers (minor units).** £12.50 is stored as `1250`. Never use `double` for money calculations.
- **Append-only operations table.** Never `UPDATE` or `DELETE` rows in `operations_table`. Mutations are expressed as new operations (EDIT, DELETE types).
- **No floating-point in CRDT merge.** HLC timestamps are `int` pairs. All comparisons are integer arithmetic.
- **Test every algorithm.** `SimplifyDebtsUsecase`, `ComputeBalancesUsecase`, `HybridLogicalClock`, `ConflictResolver`, `QrFrameEncoder/Decoder`, `ReedSolomonCodec` all require unit tests with edge cases before marking complete.

### Repository layout (already scaffolded)
```
lib/
  core/           constants · errors · Result<T,E> · utils · extensions
  domain/         entities · repository interfaces · use cases
  data/           drift database · DAOs · repository implementations
  infrastructure/ crypto · crdt · sync pipeline · serialization · backup
  presentation/   app · screens · widgets · providers
test/unit/        crypto · crdt · sync · balance · usecases
integration_test/ app_test.dart
docs/             architecture.md · sync_protocol.md
```

### Key files already implemented (do NOT rewrite)
- `lib/core/utils/result.dart` — `Result<T,E>` sealed class
- `lib/core/errors/failures.dart` — full `Failure` hierarchy
- `lib/infrastructure/crdt/hybrid_logical_clock.dart` — HLC (complete)
- `lib/infrastructure/crdt/conflict_resolver.dart` — merge policy (complete)
- `lib/domain/usecases/balance/simplify_debts_usecase.dart` — min-cost flow (complete)
- `lib/domain/usecases/balance/compute_balances_usecase.dart` — balance projection (complete)
- `lib/data/repositories/identity_repository_impl.dart` — identity CRUD (complete)
- `lib/data/repositories/group_repository_impl.dart` — group CRUD skeleton

---

## 1. Dependency graph

Implement phases **strictly in order**. Each phase depends on the previous being green (`flutter test`, `flutter analyze`).

```
Phase 1  │  Crypto layer          │  No UI, no DB, pure functions
Phase 2  │  CRDT layer            │  Depends on: Phase 1
Phase 3  │  Serialization         │  Depends on: Phase 1, 2
Phase 4  │  Database + repos      │  Depends on: Phase 2, 3
Phase 5  │  Sync pipeline         │  Depends on: Phase 1, 2, 3, 4
Phase 6  │  Riverpod providers    │  Depends on: Phase 4, 5
Phase 7  │  Onboarding UI         │  Depends on: Phase 6
Phase 8  │  Groups UI             │  Depends on: Phase 6, 7
Phase 9  │  Expenses + Balances   │  Depends on: Phase 6, 8
Phase 10 │  Sync UI               │  Depends on: Phase 5, 6
Phase 11 │  Settings + Backup     │  Depends on: Phase 6
Phase 12 │  Polish + release      │  Depends on: all
```

---

## Phase 1 — Crypto layer

### Task 1.1 — Initialise libsodium in `main.dart`

**File:** `lib/main.dart`

```dart
// Replace the TODO comment with:
import 'package:sodium_libs/sodium_libs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sodium = await SodiumInit.init();
  runApp(ProviderScope(
    overrides: [sodiumProvider.overrideWithValue(sodium)],
    child: const AuroraLedgerApp(),
  ));
}
```

Create `lib/presentation/providers/sodium_provider.dart`:
```dart
final sodiumProvider = Provider<Sodium>((ref) => throw UnimplementedError());
```

---

### Task 1.2 — Implement `CryptoServiceImpl`

**File:** `lib/infrastructure/crypto/crypto_service_impl.dart`

Implement every method. Map directly to libsodium Dart API:

| Method | libsodium call |
|---|---|
| `generateIdentityKeypair()` | `sodium.crypto.sign.keyPair()` |
| `sign(message, secretKey)` | `sodium.crypto.sign.detached(message, secretKey)` |
| `verify(message, sig, pk)` | `sodium.crypto.sign.verifyDetached(message, sig, pk)` |
| `generateGroupKey()` | `sodium.randombytes.buf(32)` |
| `encrypt(plaintext, key)` | `sodium.crypto.aead.xchacha20poly1305Ietf.encrypt(...)` — prepend fresh 24-byte nonce |
| `decrypt(ciphertext, key)` | split nonce (bytes 0..23), then `.decrypt(...)` |
| `deriveKey(masterKey, ctx)` | `sodium.crypto.kdf.deriveFromKey(masterKey, context: ctx, subkeyId: 1, subkeyLen: 32)` |
| `sha256(input)` | `sodium.crypto.hash.sha256(input)` |

For `operationSigningPayload(op)`:
```
bytes = utf8(op.operationId)
      + utf8(op.groupId)
      + int64LE(op.hlcTimestamp.physicalMs)
      + int32LE(op.hlcTimestamp.logical)
      + uint8(op.type.index)
      + op.payload
```
Use `ByteData` / `Uint8List` for deterministic encoding. No JSON here.

**Inject** `Sodium` instance via constructor; register in DI (see Phase 6).

---

### Task 1.3 — Unit tests for `CryptoServiceImpl`

**File:** `test/unit/crypto/crypto_service_test.dart`

Required test cases:
1. `generateIdentityKeypair()` returns keys of correct byte length (32 + 64)
2. `sign` + `verify` round-trip: verify returns `true`
3. `verify` returns `false` when signature is tampered (flip one byte)
4. `verify` returns `false` when message is tampered
5. `encrypt` + `decrypt` round-trip recovers plaintext exactly
6. `decrypt` throws `CryptoException` on tampered ciphertext
7. `deriveKey` with same inputs produces same output (deterministic)
8. `deriveKey` with different contexts produces different keys
9. `sha256` matches known vector (SHA-256("") = e3b0c44...)
10. `operationSigningPayload` is deterministic: same op → same bytes

**Acceptance:** All 10 pass. `flutter analyze` clean.

---

### Task 1.4 — Unit tests for `KeyStorageServiceImpl`

**File:** `test/unit/crypto/key_storage_service_test.dart`

Use `flutter_secure_storage`'s in-memory mock:
```dart
FlutterSecureStorage.setMockInitialValues({});
```

Required test cases:
1. Store + load secret key round-trips correctly
2. Store + load group key round-trips correctly
3. `hasIdentityKey()` returns `false` before store, `true` after
4. `deleteGroupKey()` removes key; subsequent load returns `null`

---

## Phase 2 — CRDT layer

### Task 2.1 — Verify existing HLC tests pass

**File:** `test/unit/crdt/hybrid_logical_clock_test.dart`

The HLC is already implemented. Run the tests. If any fail, diagnose and fix the test setup (not the HLC logic — the HLC is correct).

Add these missing test cases to the existing file:
1. `receive()` with a remote timestamp 10 seconds in the future: resulting physical component ≥ remote physical
2. Serialise `HlcTimestamp` to/from two `int` fields and back: equality preserved
3. `HlcTimestamp.compareTo` total ordering: `(100, 0) < (100, 1) < (101, 0)`

---

### Task 2.2 — Complete `OperationMerger` tests

**File:** `test/unit/crdt/operation_merger_test.dart` (create)

```dart
// Required test cases:
// 1. merge() applies new operations and returns appliedCount correctly
// 2. merge() skips duplicate operations (same operationId)
// 3. merge() with empty incoming list → appliedCount == 0
// 4. merge() preserves causal order in sorted() after merge
// 5. missingFrom() returns only operations not in remoteKnownIds
```

---

### Task 2.3 — Add `SyncRepository` implementation skeleton

**File:** `lib/data/repositories/sync_repository_impl.dart` (create)

Implement the interface from `lib/domain/repositories/sync_repository.dart`. For now, implement `collectMissingOperations` and `getLastSyncTimestamp` (use the DAO). Mark others as `throw UnimplementedError('Implemented in Phase 5')`.

```dart
class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl(this._operationDao, this._groupDao);
  final OperationDao _operationDao;
  final GroupDao _groupDao;

  @override
  Future<Result<List<Operation>, Failure>> collectMissingOperations({...}) async {
    final allOps = await _operationDao.getOperationsForGroup(groupId);
    final remoteSet = remoteKnownOperationIds.toSet();
    final missing = allOps
        .where((row) => !remoteSet.contains(row.operationId))
        .map(_rowToOperation)
        .toList();
    return Result.ok(missing);
  }
  // ...
}
```

---

## Phase 3 — Serialization

### Task 3.1 — Implement `MsgpackSerializer`

**File:** `lib/infrastructure/serialization/msgpack_serializer.dart`

Use the `messagepack` package. Serialize `List<Operation>` as a MessagePack array of maps. Each operation map:

```
{
  "id":    String  (operationId),
  "gid":   String  (groupId),
  "apk":   Uint8List (authorPublicKey, base64-decoded),
  "hms":   int     (hlcTimestamp.physicalMs),
  "hlg":   int     (hlcTimestamp.logical),
  "typ":   int     (operationType.index),
  "pay":   Uint8List (payload),
  "sig":   Uint8List (signature),
}
```

Use short keys to minimise payload size.

`deserializeOperations` must validate that all required keys are present; throw `SerializationException` if malformed.

**Tests** (`test/unit/crdt/msgpack_serializer_test.dart`):
1. Serialize + deserialize 1 operation: all fields preserved
2. Serialize + deserialize 50 operations: count and all IDs preserved
3. Deserialize malformed bytes → throws `SerializationException`
4. Empty list serializes and deserializes to empty list

---

### Task 3.2 — Implement `ZstdCompressor`

**File:** `lib/infrastructure/serialization/zstd_compressor.dart`

Replace the gzip placeholder. Use `flutter_zstd` FFI binding if available in your environment; otherwise use the `archive` package's `GZipEncoder` as a shim and leave a `// TODO: replace with flutter_zstd` comment.

Add `compress`/`decompress` round-trip test:
```dart
// test/unit/sync/compressor_test.dart
test('round-trip preserves bytes', () {
  final original = List.generate(500, (i) => i % 256);
  final compressed = compressor.compress(original);
  final restored = compressor.decompress(compressed);
  expect(restored, equals(original));
});
test('compressed is smaller than original for repetitive data', () {
  final repetitive = List.filled(1000, 42);
  expect(compressor.compress(repetitive).length, lessThan(repetitive.length));
});
```

---

## Phase 4 — Database + repositories

### Task 4.1 — Run drift code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `app_database.g.dart`, `operation_dao.g.dart`, `identity_dao.g.dart`, `group_dao.g.dart`. Do not edit generated files.

**Verify:** `flutter analyze` passes with no errors.

---

### Task 4.2 — Complete `GroupRepositoryImpl`

**File:** `lib/data/repositories/group_repository_impl.dart`

Implement the two `UnimplementedError` methods:

**`joinGroup({required String invitePayload})`:**
```
1. base64-decode invitePayload
2. Decrypt using HKDF(local_group_key_attempt, "aurora-invite-v1")
   — actually: the invite is encrypted with the creator's identity key
   — decrypt with group member's own identity key (X25519 key exchange)
   — DESIGN NOTE: invite payload = groupId(UUID) + groupKey(32B) + creatorPublicKey(32B)
   — encrypted with XChaCha20-Poly1305 using creatorPublicKey as recipient
3. Extract groupId, groupKey, creatorPublicKey
4. Store groupKey via KeyStorageService.storeGroupKey()
5. Insert group row with current device added to memberPublicKeysJson
6. Return Result.ok(group)
```

**`generateInvitePayload({required String groupId})`:**
```
1. Load groupKey from KeyStorageService
2. Load own publicKey from KeyStorageService
3. Build plaintext = groupId (UUID bytes, 16B) + groupKey (32B) + publicKey (32B)
4. Encrypt with XChaCha20-Poly1305 using HKDF(groupKey, "aurora-invite-v1") as key
5. base64url-encode (no padding) the ciphertext
6. Return Result.ok(encoded)
```

**Tests** (`test/unit/usecases/group_repository_test.dart`):
1. `createGroup()` stores group key in key storage
2. `generateInvitePayload()` + `joinGroup()` round-trip: joining device ends up with same groupKey
3. `getAllGroups()` returns groups in descending creation order
4. `watchAllGroups()` emits new list when group is added

---

### Task 4.3 — Implement `ExpenseRepository`

**File:** `lib/data/repositories/expense_repository_impl.dart` (create)

The `Expense` entity is a **read-model projected from operations** — it is never stored directly. The repository must:

1. `addExpense(...)`:
   - Load `secretKey` from `KeyStorageService`
   - Build `OperationPayload` as MessagePack-encoded map of expense fields
   - Set `hlcTimestamp` from `HybridLogicalClock.now()`
   - Sign the canonical payload with `CryptoService.sign()`
   - Insert an `ADD_EXPENSE` `OperationRow` into `operations_table`
   - Return `Result.ok(expense)` — project the expense from the operation

2. `editExpense(...)`:
   - Create an `EDIT_EXPENSE` operation referencing the original `expenseId`
   - Same sign + insert flow

3. `deleteExpense(...)`:
   - Create a `DELETE_EXPENSE` operation
   - Same sign + insert flow

4. `getExpensesForGroup(groupId)`:
   - Load all operations for group from DAO
   - Filter to expense-type operations
   - Group by `expenseId` (extracted from payload)
   - Apply `ConflictResolver.resolveExpenseOps()` per expense
   - Project surviving operations → `Expense` entities
   - Return sorted by `hlcTimestamp` descending (newest first)

5. `settlePayment(...)`:
   - Create a `SETTLE_PAYMENT` operation
   - Sign + insert

6. `watchExpensesForGroup(groupId)`:
   - Stream from `OperationDao.watchOperationsForGroup()`
   - Map through the same projection pipeline as `getExpensesForGroup`

**Inject:** `OperationDao`, `CryptoService`, `KeyStorageService`, `HybridLogicalClock`, `MsgpackSerializer`

**Tests** (`test/unit/usecases/expense_repository_test.dart`):
1. `addExpense()` inserts exactly one operation row with type `addExpense`
2. `deleteExpense()` after `addExpense()` → `getExpensesForGroup()` returns empty list
3. `editExpense()` after `addExpense()` → `getExpensesForGroup()` returns updated fields
4. `getExpensesForGroup()` returns expenses sorted newest first
5. Operation signature is valid (verify with `CryptoService.verify()`)

---

### Task 4.4 — Implement `SyncRepository` (storage methods)

**File:** `lib/data/repositories/sync_repository_impl.dart`

Complete `applyIncomingOperations`:
```
For each incoming operation:
  1. Verify Ed25519 signature using CryptoService.verify()
     → if invalid: collect to rejectedOps list, continue (do not throw)
  2. Check for duplicate via OperationDao.getKnownOperationIds()
     → if duplicate: skip
  3. Call HybridLogicalClock.receive(op.hlcTimestamp)
  4. Insert into operations_table via OperationDao.insertOperation()
Return Result.ok(appliedCount)
```

Implement `getLastSyncTimestamp`:
```
Load group row via GroupDao.getGroup(groupId)
Return group.lastSyncedAtMs converted to DateTime, or null
```

---

## Phase 5 — Sync pipeline

### Task 5.1 — Implement `ReedSolomonCodec`

**File:** `lib/infrastructure/sync/reed_solomon_codec.dart`

Implement RS(32, 24) over GF(2⁸). This is a pure Dart implementation (~100 LOC).

**GF(2⁸) arithmetic using primitive polynomial 0x11D (x⁸+x⁴+x³+x²+1):**

```dart
// Pre-compute log and antilog tables for GF(256)
static final _gfLog = Uint8List(256);
static final _gfExp = Uint8List(512); // doubled for modular arithmetic

static void _initGfTables() {
  int x = 1;
  for (int i = 0; i < 255; i++) {
    _gfExp[i] = x;
    _gfLog[x] = i;
    x = _gfMul(x, 2); // multiply by generator
  }
  for (int i = 255; i < 512; i++) _gfExp[i] = _gfExp[i - 255];
}

static int _gfMul(int a, int b) {
  if (a == 0 || b == 0) return 0;
  return _gfExp[(_gfLog[a] + _gfLog[b]) % 255];
}

static int _gfDiv(int a, int b) {
  if (b == 0) throw ArgumentError('Division by zero in GF(256)');
  if (a == 0) return 0;
  return _gfExp[(_gfLog[a] - _gfLog[b] + 255) % 255];
}
```

Generate the RS generator polynomial for `n - k = 8` parity bytes, then implement Euclidean encoding and syndrome-based error detection/correction.

If the full RS implementation is complex in the timeline, use `dart_reed_solomon` package as a direct substitute — check `pub.dev` for availability. If unavailable, implement a simplified version that only does error **detection** (CRC-based) and flags frames for rescan rather than correcting in-place, with a `// TODO: upgrade to full RS correction` comment.

**Tests** (`test/unit/sync/reed_solomon_test.dart`):
1. `encode()` output length = input length + (n - k) parity bytes per block
2. `encode()` + `decode()` with zero errors: exact round-trip
3. `decode()` with 1 byte corrupted: corrects to original
4. `decode()` with 4 bytes corrupted (max correctable): corrects to original
5. `decode()` with 5 bytes corrupted: throws or returns error indicator

---

### Task 5.2 — Implement `QrFrameEncoder`

**File:** `lib/infrastructure/sync/qr_frame_encoder.dart`

Implement `_buildFrameEnvelope`:

```dart
List<int> _buildFrameEnvelope({
  required int frameIndex,
  required int totalFrames,
  required List<int> data,
}) {
  final buffer = BytesBuilder();
  buffer.addByte(SyncConstants.syncProtocolVersion);      // 1 byte
  buffer.add(_uint16LE(frameIndex));                       // 2 bytes
  buffer.add(_uint16LE(totalFrames));                      // 2 bytes
  buffer.add(data);                                        // N bytes
  final crc = _crc32(buffer.toBytes());
  buffer.add(_uint32LE(crc));                              // 4 bytes
  return buffer.toBytes();
}

List<int> _uint16LE(int v) => [v & 0xFF, (v >> 8) & 0xFF];
List<int> _uint32LE(int v) => [v & 0xFF, (v>>8)&0xFF, (v>>16)&0xFF, (v>>24)&0xFF];

int _crc32(List<int> data) {
  // Standard CRC-32 using 0xEDB88320 polynomial
  // Implement lookup-table approach for performance
}
```

**Tests** (`test/unit/sync/qr_frame_encoder_test.dart`):
1. Single small payload encodes to exactly 1 frame
2. Payload larger than `targetFramePayloadBytes` encodes to multiple frames
3. All frames have consistent `totalFrames` header value
4. Frame envelope header bytes decode correctly (version, index, total)
5. CRC32 in last 4 bytes matches computed CRC of preceding bytes

---

### Task 5.3 — Implement `QrFrameDecoder`

**File:** `lib/infrastructure/sync/qr_frame_decoder.dart`

```dart
Result<List<int>?, Failure> addFrame(List<int> rawFrame) {
  // 1. Validate minimum frame length (9 bytes: 1+2+2+0+4)
  // 2. Extract CRC32 from last 4 bytes; verify against frame body
  //    → if mismatch: return Result.err(FrameChecksumFailure(frameIndex))
  // 3. Parse: version(1), frameIndex(2 LE), totalFrames(2 LE), data(rest minus CRC)
  // 4. Validate version == SyncConstants.syncProtocolVersion
  // 5. Apply RS error correction to data
  // 6. Store in _receivedFrames[frameIndex]
  // 7. Set _totalFrames on first valid frame
  // 8. If isComplete: assemble and return Result.ok(assembled)
  // 9. Otherwise: return Result.ok(null)
}
```

**Tests** (`test/unit/sync/qr_frame_decoder_test.dart`):
1. Encode then decode round-trip: output == original payload
2. Out-of-order frames: decoder assembles correctly regardless of arrival order
3. Duplicate frame: ignored, `isComplete` not affected
4. Tampered CRC: `FrameChecksumFailure` returned, frame not stored
5. `progress` goes from 0.0 to 1.0 as frames arrive
6. `reset()` clears all state

---

### Task 5.4 — Complete `SyncPayloadBuilder` and implement `SyncPayloadParser`

**File (builder):** `lib/infrastructure/sync/sync_payload_builder.dart` — already scaffolded, verify it compiles with Phase 3 implementations in place.

**File (parser — create):** `lib/infrastructure/sync/sync_payload_parser.dart`

```dart
class SyncPayloadParser {
  const SyncPayloadParser(
    this._serializer, this._compressor, this._cryptoService, this._keyStorage,
  );

  Future<Result<List<Operation>, Failure>> parse({
    required String groupId,
    required List<int> encryptedPayload,
  }) async {
    // 1. Validate protocol version byte
    // 2. Strip version byte; remainder is ciphertext
    // 3. Load group key; derive sync key via HKDF
    // 4. Decrypt with XChaCha20-Poly1305
    //    → CryptoException → SyncPayloadDecryptionFailure
    // 5. Decompress with zstd
    // 6. Deserialize MessagePack → List<Operation>
    //    → SerializationException → SyncPayloadCorruptedFailure
    // 7. Return Result.ok(operations)
  }
}
```

Complete `SyncRepositoryImpl.buildSyncFrames` and `parseSyncPacket` using these two classes.

**Integration test** (`test/unit/sync/sync_pipeline_test.dart`):
1. Builder + Parser round-trip: parse(build(ops)) == ops (all fields)
2. Parser rejects ciphertext with wrong group key
3. Builder produces correct number of frames for large op set (>10 ops)

---

## Phase 6 — Riverpod providers

### Task 6.1 — Dependency injection setup

**File:** `lib/presentation/providers/service_providers.dart` (create)

Wire all services as Riverpod providers:

```dart
// Database
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// DAOs
final identityDaoProvider = Provider((ref) => ref.read(appDatabaseProvider).identityDao);
final groupDaoProvider    = Provider((ref) => ref.read(appDatabaseProvider).groupDao);
final operationDaoProvider = Provider((ref) => ref.read(appDatabaseProvider).operationDao);

// Infrastructure
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  final sodium = ref.read(sodiumProvider);
  return CryptoServiceImpl(sodium);
});

final keyStorageProvider = Provider<KeyStorageService>(
  (_) => KeyStorageServiceImpl(const FlutterSecureStorage()),
);

final hlcProvider = Provider<HybridLogicalClock>((_) => HybridLogicalClock());
final msgpackProvider = Provider((_) => const MsgpackSerializer());
final compressorProvider = Provider((_) => const ZstdCompressor());
final rsCodecProvider = Provider((_) => const ReedSolomonCodec());
final frameEncoderProvider = Provider((ref) => QrFrameEncoder(ref.read(rsCodecProvider)));
final conflictResolverProvider = Provider((_) => const ConflictResolver());

// Repositories
final identityRepositoryProvider = Provider<IdentityRepository>((ref) =>
  IdentityRepositoryImpl(
    ref.read(identityDaoProvider),
    ref.read(cryptoServiceProvider),
    ref.read(keyStorageProvider),
  ));

final groupRepositoryProvider = Provider<GroupRepository>((ref) =>
  GroupRepositoryImpl(
    ref.read(groupDaoProvider),
    ref.read(cryptoServiceProvider),
    ref.read(keyStorageProvider),
  ));

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) =>
  ExpenseRepositoryImpl(
    ref.read(operationDaoProvider),
    ref.read(cryptoServiceProvider),
    ref.read(keyStorageProvider),
    ref.read(hlcProvider),
    ref.read(msgpackProvider),
  ));

final syncRepositoryProvider = Provider<SyncRepository>((ref) =>
  SyncRepositoryImpl(
    ref.read(operationDaoProvider),
    ref.read(groupDaoProvider),
  ));

// Use cases
final createIdentityUsecaseProvider = Provider((ref) =>
  CreateIdentityUsecase(ref.read(identityRepositoryProvider)));
final getIdentityUsecaseProvider = Provider((ref) =>
  GetIdentityUsecase(ref.read(identityRepositoryProvider)));
final createGroupUsecaseProvider = Provider((ref) =>
  CreateGroupUsecase(ref.read(groupRepositoryProvider)));
final joinGroupUsecaseProvider = Provider((ref) =>
  JoinGroupUsecase(ref.read(groupRepositoryProvider)));
final addExpenseUsecaseProvider = Provider((ref) =>
  AddExpenseUsecase(ref.read(expenseRepositoryProvider), ref.read(syncRepositoryProvider)));
final settlePaymentUsecaseProvider = Provider((ref) =>
  SettlePaymentUsecase(ref.read(expenseRepositoryProvider)));
final computeBalancesUsecaseProvider = Provider((_) => const ComputeBalancesUsecase());
final simplifyDebtsUsecaseProvider = Provider((_) => const SimplifyDebtsUsecase());
final prepareSyncUsecaseProvider = Provider((ref) {
  // build SyncPayloadBuilder and wire to repository
  final builder = SyncPayloadBuilder(
    ref.read(msgpackProvider),
    ref.read(compressorProvider),
    ref.read(cryptoServiceProvider),
    ref.read(keyStorageProvider),
    ref.read(frameEncoderProvider),
  );
  return PrepareSyncPacketUsecase(ref.read(syncRepositoryProvider));
});
```

---

### Task 6.2 — Implement `IdentityNotifier`

**File:** `lib/presentation/providers/identity_provider.dart`

```dart
@riverpod
class IdentityNotifier extends _$IdentityNotifier {
  @override
  Future<Identity?> build() async {
    final result = await ref.read(getIdentityUsecaseProvider).call();
    return result.when(ok: (id) => id, err: (_) => null);
  }

  Future<Result<Identity, Failure>> create({required String alias}) async {
    final result = await ref.read(createIdentityUsecaseProvider).call(alias: alias);
    if (result.isOk) ref.invalidateSelf();
    return result;
  }
}
```

---

### Task 6.3 — Implement `GroupNotifier`

**File:** `lib/presentation/providers/group_provider.dart`

```dart
@riverpod
class GroupNotifier extends _$GroupNotifier {
  @override
  Stream<List<Group>> build() =>
    ref.read(groupRepositoryProvider).watchAllGroups();

  Future<Result<Group, Failure>> create({required String name, required String currency}) =>
    ref.read(createGroupUsecaseProvider).call(name: name, currency: currency);

  Future<Result<Group, Failure>> join({required String invitePayload}) =>
    ref.read(joinGroupUsecaseProvider).call(invitePayload: invitePayload);
}
```

---

### Task 6.4 — Implement `ExpenseNotifier`

**File:** `lib/presentation/providers/expense_provider.dart`

```dart
@riverpod
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Stream<List<Expense>> build(String groupId) =>
    ref.read(expenseRepositoryProvider).watchExpensesForGroup(groupId: groupId);

  Future<Result<Expense, Failure>> add({
    required String groupId,
    required int amountMinorUnits,
    required String currency,
    required String payerIdentityId,
    required List<String> participantIdentityIds,
    required String notes,
  }) => ref.read(addExpenseUsecaseProvider).call(
        groupId: groupId,
        amountMinorUnits: amountMinorUnits,
        currency: currency,
        payerIdentityId: payerIdentityId,
        participantIdentityIds: participantIdentityIds,
        notes: notes,
      );
}
```

---

### Task 6.5 — Implement `BalanceNotifier`

**File:** `lib/presentation/providers/balance_provider.dart`

```dart
@riverpod
class BalanceNotifier extends _$BalanceNotifier {
  @override
  FutureOr<({List<MemberBalance> balances, List<Settlement> settlements})> build(
    String groupId,
  ) async {
    // 1. Watch expenses for group (subscribe to stream)
    // 2. Load member aliases from group entity
    // 3. Compute balances via ComputeBalancesUsecase
    // 4. Simplify via SimplifyDebtsUsecase
    // 5. Return both
  }
}
```

---

### Task 6.6 — Implement `SyncNotifier`

**File:** `lib/presentation/providers/sync_provider.dart`

```dart
enum SyncPhase { idle, sending, receiving, complete, error }

@freezed
class SyncState with _$SyncState {
  const factory SyncState({
    @Default(SyncPhase.idle) SyncPhase phase,
    @Default([]) List<List<int>> outboundFrames,
    @Default(0) int currentFrameIndex,
    @Default(0) double scanProgress,
    String? errorMessage,
    DateTime? completedAt,
  }) = _SyncState;
}

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  SyncState build(String groupId) => const SyncState();

  Future<void> startSend() async {
    // 1. Get remote known op IDs (exchange via initial handshake QR — see Phase 10)
    // 2. Call PrepareSyncPacketUsecase
    // 3. Set state to sending with outboundFrames
    // 4. Start frame animation timer
  }

  void onFrameScanned(List<int> rawFrame) {
    // Feed to QrFrameDecoder; update scanProgress
    // When complete: call ApplySyncPacketUsecase
  }

  void nextFrame() {
    // Advance currentFrameIndex; loop at outboundFrames.length
  }
}
```

---

### Task 6.7 — Implement `ReplicaStatusNotifier`

**File:** `lib/presentation/providers/replica_status_provider.dart`

```dart
enum ReplicaStatus { ok, warningSoon, blocked }

@riverpod
class ReplicaStatusNotifier extends _$ReplicaStatusNotifier {
  @override
  Future<ReplicaStatus> build(String groupId) async {
    final lastSync = await ref.read(syncRepositoryProvider)
        .getLastSyncTimestamp(groupId: groupId);
    if (lastSync == null) return ReplicaStatus.ok; // First device, no sync needed yet
    final hoursAgo = DateTime.now().difference(lastSync).inHours;
    if (hoursAgo >= AppConstants.replicaBlockThresholdHours) return ReplicaStatus.blocked;
    if (hoursAgo >= AppConstants.replicaWarnThresholdHours) return ReplicaStatus.warningSoon;
    return ReplicaStatus.ok;
  }
}
```

Run codegen after all providers are written:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Phase 7 — Onboarding UI

### Task 7.1 — Onboarding flow screen

**File:** `lib/presentation/screens/onboarding/onboarding_screen.dart`

Two-page flow:

**Page 1 — Welcome:**
- Full-screen dark background with Aurora logo (SVG or icon)
- Title: "Aurora Ledger"
- Subtitle: "Private expense sharing.\nNo servers. No accounts."
- Three feature pills: "Zero infrastructure" · "Encrypted sync" · "Offline first"
- CTA button: "Get started" → navigates to Page 2

**Page 2 — Alias setup (`alias_setup_screen.dart`):**
- Prompt: "What should we call you?"
- `TextField` bound to alias, max 30 chars
- Body text: "Stored only on this device. Cosmetic only."
- CTA button: "Create identity" — calls `IdentityNotifier.create(alias: ...)`
  - Loading state while creating
  - On `Result.ok`: `context.go(Routes.home)`
  - On `Result.err`: show `SnackBar` with error message
- Router guard: if identity already exists, skip onboarding and go directly to `Routes.home`

**Router guard** in `router.dart`:
```dart
redirect: (context, state) async {
  final hasIdentity = await ref.read(identityRepositoryProvider).hasIdentity();
  if (!hasIdentity && state.matchedLocation != Routes.onboarding) return Routes.onboarding;
  if (hasIdentity && state.matchedLocation == Routes.onboarding) return Routes.home;
  return null;
},
```

---

### Task 7.2 — Shared widgets: `AuroraButton`, `AuroraCard`, `AuroraLoadingIndicator`

**File:** `lib/presentation/widgets/common/aurora_button.dart`

```dart
class AuroraButton extends StatelessWidget {
  // Primary CTA button — full width, rounded, theme primary colour
  // Props: label, onPressed, isLoading (shows CircularProgressIndicator)
}
```

**File:** `lib/presentation/widgets/common/aurora_card.dart`
```dart
// Rounded Card with 16dp radius, subtle border, no elevation
// Props: child, padding (default 16), onTap
```

**File:** `lib/presentation/widgets/common/aurora_empty_state.dart`
```dart
// Centered column: icon (outline), title, subtitle, optional CTA button
// Props: icon, title, subtitle, buttonLabel, onButtonTap
```

**File:** `lib/presentation/widgets/common/aurora_error_view.dart`
```dart
// Shows Failure.message with retry button
// Props: failure, onRetry
```

---

## Phase 8 — Groups UI

### Task 8.1 — `HomeScreen`

**File:** `lib/presentation/screens/home/home_screen.dart`

- `Scaffold` with bottom `NavigationBar` (3 tabs: Groups · Sync · Settings)
- Each tab loads the respective screen in a `Navigator` subtree
- Tab state persists during app session

---

### Task 8.2 — `GroupsScreen`

**File:** `lib/presentation/screens/groups/groups_screen.dart`

- `ConsumerWidget` — watches `groupNotifierProvider`
- Loading: `AuroraLoadingIndicator`
- Empty: `AuroraEmptyState` with "No groups yet" and "Create group" + "Join group" buttons
- Non-empty: `ListView` of `GroupCard` widgets
- FAB with "+" that shows bottom sheet: "Create group" / "Join group"

**`GroupCard`** (`lib/presentation/widgets/group/group_card.dart`):
```dart
// Shows: group name, currency pill, member count, sync status badge
// Sync status: green dot (synced <24h), amber dot (warn), red dot (blocked)
// onTap: navigate to GroupDetailScreen
```

---

### Task 8.3 — `CreateGroupScreen`

**File:** `lib/presentation/screens/groups/create_group_screen.dart`

- Text field: group name
- Currency picker: `DropdownButton` from `AppConstants.supportedCurrencies`
- "Create" button → `GroupNotifier.create()` → navigate to `GroupDetailScreen`
- Show `ReplicaStatus` info: "Your expenses sync when you meet in person."

---

### Task 8.4 — `JoinGroupScreen`

**File:** `lib/presentation/screens/groups/join_group_screen.dart`

- Uses `mobile_scanner` to scan a single QR code
- On decode: extract the invite payload string
- Call `GroupNotifier.join(invitePayload: ...)`
- Success: navigate to `GroupDetailScreen`
- Error: show error snackbar, allow rescan

---

### Task 8.5 — `GroupDetailScreen`

**File:** `lib/presentation/screens/groups/group_detail_screen.dart`

- AppBar: group name + currency chip
- `ReplicaStatusBanner` at top (amber/red warning if sync overdue)
- `ExpenseListTab` and `BalancesTab` in a `TabBar`
- FAB: "Add expense"
- Menu: "Sync" · "Invite member" · "Group info"

**`ReplicaStatusBanner`** (`lib/presentation/widgets/common/replica_status_banner.dart`):
```dart
// Yellow or red banner: "Sync with a group member soon to protect your data."
// Shown only when ReplicaStatus != ok
// Tap: navigate to SyncScreen
```

---

### Task 8.6 — `MemberListTile` + `GroupInviteQr`

**`MemberListTile`** (`lib/presentation/widgets/group/member_list_tile.dart`):
```dart
// Row: IdentityAvatar + alias + "You" chip if current device
```

**`IdentityAvatar`** (`lib/presentation/widgets/common/identity_avatar.dart`):
```dart
// Circular avatar: shows avatarPath image if set, else initials on coloured circle
// Colour derived deterministically from identityId (sha256 → hue)
```

**`GroupInviteQr`** (`lib/presentation/widgets/group/group_invite_qr.dart`):
```dart
// Displays invite payload as qr_flutter QrImageView
// + human-readable group code below (AURORA-XXXX-YYZ)
// + share button to export as image or text
```

---

## Phase 9 — Expenses + Balances UI

### Task 9.1 — `AddExpenseScreen`

**File:** `lib/presentation/screens/expenses/add_expense_screen.dart`

Fields:
- `AmountInputField` — currency-formatted integer input (stores minor units)
- Notes `TextField`
- "Paid by" — `DropdownButton` of group members (identity aliases)
- "Split between" — `ParticipantSelector` (multi-select chips of group members, all selected by default)
- "Add expense" button → `ExpenseNotifier.add(...)`

**`AmountInputField`** (`lib/presentation/widgets/expense/amount_input_field.dart`):
```dart
// TextFormField with currency symbol prefix
// Input: raw digits → stored as int (minor units)
// Display: formatted decimal e.g. "£12.50"
// Validator: must be > 0
```

**`ParticipantSelector`** (`lib/presentation/widgets/expense/participant_selector.dart`):
```dart
// Row of FilterChip widgets, one per group member
// All selected by default
// Must have at least 1 selected (validation)
```

---

### Task 9.2 — `ExpenseListTile`

**File:** `lib/presentation/widgets/expense/expense_list_tile.dart`

```dart
// ListTile: notes (title) · amount (trailing, formatted) · payer alias (subtitle)
// Deleted expenses: strikethrough, muted colour
// Long-press: context menu (Edit · Delete)
// Tap: navigate to ExpenseDetailScreen
```

---

### Task 9.3 — `BalancesScreen`

**File:** `lib/presentation/screens/balances/balances_screen.dart`

- Watches `balanceNotifierProvider(groupId)`
- Loading / error states
- `BalanceSummaryCard` per member: alias, net amount, directional colour (green = owed, red = owes)
- "Suggested settlements" section: `SettlementCard` per settlement
- "Mark as settled" on each settlement → `SettlePaymentUsecase`
- "All settled up" empty state when all balances zero

**`DebtBar`** (`lib/presentation/widgets/balance/debt_bar.dart`):
```dart
// Visual bar showing proportion owed/owing relative to group total
// Green fill for positive, red for negative
```

---

### Task 9.4 — `SettlementScreen`

**File:** `lib/presentation/screens/balances/settlement_screen.dart`

- Pre-filled: from person, to person, amount
- "Confirm settlement" → `SettlePaymentUsecase` → pop back to `BalancesScreen`
- Shows that this creates a signed operation on the ledger

---

## Phase 10 — Sync UI

### Task 10.1 — Sync protocol handshake design

Before phase-1 QR transmission, devices need to exchange their known operation ID sets so each knows what to send. Design:

```
Handshake QR (tiny, single frame):
  Encrypted JSON: { "knownIds": ["id1","id2",...], "groupId": "...", "deviceAlias": "..." }
  Encrypted with HKDF(groupKey, "aurora-handshake-v1")
```

Implement `buildHandshakeFrame` and `parseHandshakeFrame` in `SyncPayloadBuilder`/`SyncPayloadParser`.

---

### Task 10.2 — `SyncScreen`

**File:** `lib/presentation/screens/sync/sync_screen.dart`

Four-step linear flow with a `Stepper`-style UI:

```
Step 1: "Show this to your sync partner"
  → Displays handshake QR (your known op IDs)

Step 2: "Scan their handshake QR"
  → QrScanScreen returns their known op IDs
  → Both devices compute what to send

Step 3: "Show your sync QR"
  → QrDisplayScreen with animated outbound frames

Step 4: "Scan their sync QR"
  → QrScanScreen, feeds frames to QrFrameDecoder
  → On complete: ApplySyncPacketUsecase → update lastSyncedAt
  → Show "Sync complete" with operation count
```

---

### Task 10.3 — `QrDisplayScreen`

**File:** `lib/presentation/screens/sync/qr_display_screen.dart`

- Receives `List<List<int>>` frames from `SyncNotifier`
- Displays one frame at a time as `QrImageView` from `qr_flutter`
- Advances at `SyncConstants.qrDisplayFps` (4 fps) using `Timer.periodic`
- Each frame repeats `SyncConstants.frameRepeatCount` times before advancing
- Shows frame counter: "Frame 3 of 7"
- Shows progress bar
- "Done" button appears only after all frames have been displayed at least once

**`QrFrameDisplay`** (`lib/presentation/widgets/sync/qr_frame_display.dart`):
```dart
// Large, centered QrImageView
// Correct size for scanning distance: 280×280 dp minimum
// White background always (QR needs contrast regardless of theme)
// Frame progress indicator below
```

---

### Task 10.4 — `QrScanScreen`

**File:** `lib/presentation/screens/sync/qr_scan_screen.dart`

- `MobileScanner` widget fills screen
- Custom overlay: `QrScannerOverlay` with corner markers
- Decodes each frame → feeds to `SyncNotifier.onFrameScanned()`
- `FrameProgressIndicator` shows received / total frames
- Prevents duplicate frame processing (check `QrFrameDecoder.receivedIndices`)
- On `isComplete`: auto-pop with assembled payload

**`QrScannerOverlay`** (`lib/presentation/widgets/sync/qr_scanner_overlay.dart`):
```dart
// Dark semi-transparent overlay with cut-out scan region
// Corner markers (brackets) drawn as CustomPainter
// Animated border pulse when actively scanning
```

**`FrameProgressIndicator`** (`lib/presentation/widgets/sync/frame_progress_indicator.dart`):
```dart
// Row of small circles: received=filled, missing=outline, unknown=faint
// "Scanning frame 3 of 7" label
```

---

### Task 10.5 — `SyncStatusBadge`

**File:** `lib/presentation/widgets/sync/sync_status_badge.dart`

```dart
// Compact badge for GroupCard and GroupDetailScreen
// Green: synced <1h ago
// Amber: synced 1-24h ago
// Red: synced >24h ago or never
// Pulsing dot animation for green state
```

---

## Phase 11 — Settings + Backup

### Task 11.1 — `SettingsScreen`

**File:** `lib/presentation/screens/settings/settings_screen.dart`

Sections:
1. **Identity** — alias (editable inline), public key fingerprint (last 8 hex chars), avatar
2. **Backup** — "Back up identity" → `BackupScreen`; last backup timestamp
3. **Groups** — list of joined groups with leave option (future)
4. **About** — app version, "Aurora Ledger is open source" link, privacy statement

---

### Task 11.2 — Implement `BackupServiceImpl`

**File:** `lib/infrastructure/backup/backup_service_impl.dart`

```dart
class BackupServiceImpl implements BackupService {
  @override
  Future<Result<List<int>, Failure>> createBackup() async {
    // 1. Load secretKey + publicKey from KeyStorageService
    // 2. Load all group keys (enumerate known groups from DB)
    // 3. Load all operations from DB (all groups)
    // 4. Serialize to MessagePack: { identity, groupKeys, operations }
    // 5. Derive backup encryption key from secretKey + HKDF("aurora-backup-v1")
    // 6. Encrypt with XChaCha20-Poly1305
    // 7. Prepend magic header: b'AURORA_BACKUP_V1' (16 bytes)
    // 8. Return Result.ok(blob)
  }

  @override
  Future<Result<void, Failure>> restoreFromBackup(List<int> encryptedBackup) async {
    // 1. Verify magic header
    // 2. Prompt user to enter backup passphrase (or derive key from device - TBD)
    // 3. Decrypt
    // 4. Deserialize
    // 5. Restore identity to secure storage
    // 6. Restore all group keys to secure storage
    // 7. Re-insert all operations into DB (idempotent — ON CONFLICT IGNORE)
    // 8. Return Result.ok(null)
  }
}
```

---

### Task 11.3 — `BackupScreen`

**File:** `lib/presentation/screens/settings/backup_screen.dart`

- "Create backup" button → `BackupServiceImpl.createBackup()` → `exportBackup()` via platform share sheet
- "Restore from backup" → file picker → `BackupServiceImpl.restoreFromBackup()`
- Warning text: "Store this backup in iCloud Drive or Google Drive. Aurora never uploads it."
- Last backup timestamp (stored in `SharedPreferences` after each backup)

---

## Phase 12 — Polish + release

### Task 12.1 — Replica nudge notifications

**File:** `lib/infrastructure/backup/replica_nudge_service.dart` (create)

Using `flutter_local_notifications`:
```dart
class ReplicaNudgeService {
  // Schedule a local notification 24h after last sync
  // Cancel and reschedule on each successful sync
  // Notification body: "Sync Aurora Ledger with a group member to protect your expenses."
  // Tap: opens SyncScreen for the relevant group
}
```

Wire into `ApplySyncPacketUsecase` — reschedule on successful sync.

---

### Task 12.2 — Human-readable group code (Luhn)

**File:** `lib/core/utils/group_code_generator.dart` (create)

```dart
// Encodes group_id (UUID) as AURORA-XXXX-YYZ (base32 + Luhn check digit)
// AURORA-1AB2-3CD4
// Luhn algorithm over base32 alphabet
// Used as fallback when QR cannot be scanned
```

Display in `GroupInviteQr` below the QR code. Implement `parseGroupCode()` inverse.

---

### Task 12.3 — L10n wiring

1. Ensure `flutter_localizations` is in `pubspec.yaml` dependencies
2. Verify `l10n.yaml` exists:
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   ```
3. Run `flutter gen-l10n`
4. Replace all hardcoded English strings in screens with `AppLocalizations.of(context)!.*`

---

### Task 12.4 — Final CI verification

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed lib/ test/
flutter test --coverage test/unit/
flutter build apk --debug
flutter build ios --debug --no-codesign
```

All must pass before marking Phase 12 complete.

---

### Task 12.5 — Acceptance test matrix

Before declaring v1 complete, manually verify on a real device pair (one iOS, one Android):

| Test | Expected |
|---|---|
| Fresh install — no account prompt | Onboarding shows, no email/phone asked |
| Create identity | Keypair generated, alias saved, home screen shown |
| Create group "Spain Trip" (EUR) | Group appears in list, currency shown |
| Invite second device via QR | Second device joins, member count = 2 |
| Add expense £30.00 — Alice pays, 3 participants | Expense appears, balances update |
| Delete expense | Expense removed from list, balance resets |
| Bilateral QR sync between devices | Both devices show same expenses and balances |
| Sync status after sync | Green badge, timestamp shown |
| 24h replica warning | Amber badge appears, nudge notification fires |
| 72h replica block | Cannot add expenses; error message shown |
| Export backup | Share sheet opens, file produced |
| Restore from backup on new device | All groups and expenses present |
| Kill app mid-sync, restart, re-sync | Idempotent: no duplicate operations |
| 6 people, 40 expenses — simplified debts | ≤ 5 settlement transactions shown |

---

## Appendix A — Code style rules

1. All `Result<T,E>` returns must be handled at the call site — no `.value` without `.isOk` check
2. Never catch `Exception` broadly — catch specific types and map to `Failure`
3. `// TODO:` comments must reference the Phase number: `// TODO(Phase 5): implement RS encoding`
4. No `print()` statements — use `AuroraLogger`
5. All public APIs must have dartdoc `///` comments
6. Format with `dart format` before every commit
7. Generated files (`*.g.dart`, `*.freezed.dart`) are never committed modified — run codegen fresh

---

## Appendix B — Critical invariants to test

These invariants must hold at all times. Write a test for each:

```dart
// INV-1: Operation count only ever increases
// INV-2: Applying the same set of operations twice produces identical balance state
// INV-3: Balance sum across all members in a group is always zero
// INV-4: Number of simplified settlements ≤ (memberCount - 1)
// INV-5: Every stored operation has a valid Ed25519 signature
// INV-6: HLC timestamps are strictly monotonically increasing on each device
// INV-7: encrypt(decrypt(x)) == x for all x ∈ [0..65536] byte payloads
// INV-8: QrFrameEncoder(x) → QrFrameDecoder round-trip == x for all payload sizes
```

---

## Appendix C — Things that must never exist in this codebase

If you are about to write any of the following, stop and flag for human review:

- `import 'package:http/http.dart'`
- `import 'package:dio/dio.dart'`
- `import 'package:firebase_*`
- `import 'package:supabase*`
- `import 'package:amplitude*`
- `dart:math` `Random()` for cryptographic purposes
- `double` arithmetic on money amounts
- `UPDATE operations_table SET ...`
- `DELETE FROM operations_table WHERE ...`
- Any hardcoded encryption key or seed
- Any API key or secret in source code
