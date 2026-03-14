# Changelog

All notable changes to Aurora Ledger will be documented here.
Format: [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Initial project scaffold
- Domain entities: Identity, Group, Operation, Expense, Balance, Settlement
- Core: Result<T,E> type, Failure hierarchy, HLC timestamp
- Infrastructure: CryptoService interface (libsodium impl placeholder)
- Infrastructure: HybridLogicalClock, OperationLog, ConflictResolver, OperationMerger
- Infrastructure: QrFrameEncoder / QrFrameDecoder, ReedSolomonCodec (placeholder)
- Infrastructure: SyncPayloadBuilder pipeline
- Domain use cases: CreateIdentity, CreateGroup, JoinGroup, AddExpense, SettlePayment,
  ComputeBalances, SimplifyDebts, PrepareSyncPacket, ApplySyncPacket
- Data: drift schema v1 (identities, groups, operations tables)
- Data: IdentityRepositoryImpl, GroupRepositoryImpl
- Presentation: app shell, go_router routes, Material 3 theme
- CI: analyze, test, build-android, build-ios, release workflows
- L10n: English ARB strings baseline
