# Aurora Ledger

> A fully offline, privacy-first expense sharing system.  
> Zero infrastructure. Cryptographic identity. Optical QR sync.

[![CI](https://github.com/your-org/aurora_ledger/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/aurora_ledger/actions/workflows/ci.yml)

---

## Architecture

```
lib/
├── core/              # Constants, error types, Result<T,E>, utils
├── domain/            # Entities, repository interfaces, use cases
│   ├── entities/      # Identity, Group, Operation, Expense, Balance
│   ├── repositories/  # Abstract ports (interfaces only)
│   └── usecases/      # Business logic, one class per operation
├── data/              # Repository implementations, SQLite/drift
│   ├── database/      # Drift tables, DAOs, AppDatabase
│   └── repositories/  # Concrete repository impls
├── infrastructure/    # Crypto, CRDT, sync pipeline, serialization
│   ├── crypto/        # libsodium wrappers, key storage
│   ├── crdt/          # HLC clock, operation log, conflict resolver
│   ├── sync/          # QR frame encoder/decoder, RS ECC, payload builder
│   └── serialization/ # MessagePack, zstd compression
└── presentation/      # Flutter UI: screens, widgets, Riverpod providers
    ├── app/           # App entry, router (go_router), theme
    ├── screens/       # One folder per feature
    ├── widgets/       # Reusable UI components
    └── providers/     # Riverpod AsyncNotifier providers
```

## Tech stack

| Layer | Choice | Reason |
|---|---|---|
| Runtime | Flutter 3.x (Dart) | Native ARM, true iOS/Android parity |
| Crypto | libsodium (sodium_libs) | Ed25519 + XChaCha20-Poly1305, constant-time |
| Key storage | flutter_secure_storage | Keychain (iOS) / Keystore (Android) |
| Database | drift + SQLCipher | Type-safe ORM, reactive streams, AES-256 at rest |
| CRDT | Custom op-log + HLC | ~300 LOC, Hybrid Logical Clocks, zero deps |
| Serialization | MessagePack | Binary, compact |
| Compression | zstd (flutter_zstd) | ~70% ratio with pre-trained dict |
| Frame ECC | Reed-Solomon RS(32,24) | 25% redundancy, 4-byte error recovery |
| QR scan | mobile_scanner | MLKit + Vision, 30fps on-device |
| QR generate | qr_flutter | Native Flutter widget |
| State | Riverpod 2 | Reactive, testable, no context threading |
| Navigation | go_router | Declarative, deep-link ready |

## Key design decisions

- **Single-currency groups** — avoids exchange rate complexity in the CRDT merge function
- **Min-replica = 2** — app blocks ADD_EXPENSE after 72h without sync (soft warn at 24h)
- **Amounts in minor units** — pence/cents as integers, no floating-point arithmetic anywhere
- **Delete wins over edit** — conservative conflict resolution policy
- **HLC timestamps** — replace wall-clock `DateTime.now()` for causal ordering across devices

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Running tests

```bash
flutter test test/unit/
flutter test integration_test/ --device-id <device_id>
```

## Algorithms

| Algorithm | File | LOC | Purpose |
|---|---|---|---|
| Hybrid Logical Clock | `infrastructure/crdt/hybrid_logical_clock.dart` | ~60 | Causal ordering |
| Min-cost debt settlement | `domain/usecases/balance/simplify_debts_usecase.dart` | ~40 | Simplified settlements |
| Reed-Solomon ECC | `infrastructure/sync/reed_solomon_codec.dart` | ~100 | QR frame error correction |
| CRDT conflict resolution | `infrastructure/crdt/conflict_resolver.dart` | ~40 | Delete-wins merge |

## Security model

1. **Identity** — Ed25519 keypair, private key never leaves the device secure enclave
2. **Operations** — every write is signed with the author's Ed25519 key
3. **Sync payloads** — XChaCha20-Poly1305 encrypted with a group-scoped key
4. **At-rest** — SQLCipher AES-256 page encryption on the database file
5. **QR interception** — encrypted payload is unreadable without the group key

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). All changes to `infrastructure/crypto/` and `infrastructure/sync/` require explicit security review in the PR.
