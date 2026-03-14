import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../data/repositories/identity_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/identity_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/balance/compute_balances_usecase.dart';
import '../../domain/usecases/balance/simplify_debts_usecase.dart';
import '../../domain/usecases/expense/add_expense_usecase.dart';
import '../../domain/usecases/expense/settle_payment_usecase.dart';
import '../../domain/usecases/group/create_group_usecase.dart';
import '../../domain/usecases/group/join_group_usecase.dart';
import '../../domain/usecases/identity/create_identity_usecase.dart';
import '../../domain/usecases/identity/get_identity_usecase.dart';
import '../../domain/usecases/sync/apply_sync_packet_usecase.dart';
import '../../domain/usecases/sync/prepare_sync_packet_usecase.dart';
import '../../infrastructure/crdt/conflict_resolver.dart';
import '../../infrastructure/crdt/hybrid_logical_clock.dart';
import '../../infrastructure/crypto/crypto_service.dart';
import '../../infrastructure/crypto/crypto_service_impl.dart';
import '../../infrastructure/crypto/key_storage_service.dart';
import '../../infrastructure/crypto/key_storage_service_impl.dart';
import '../../infrastructure/serialization/msgpack_serializer.dart';
import '../../infrastructure/serialization/zstd_compressor.dart';
import '../../infrastructure/sync/qr_frame_encoder.dart';
import '../../infrastructure/sync/reed_solomon_codec.dart';
import '../../infrastructure/sync/sync_payload_builder.dart';
import '../../infrastructure/sync/sync_payload_parser.dart';
import 'sodium_provider.dart';

// Database
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// DAOs
final identityDaoProvider = Provider((ref) => ref.read(appDatabaseProvider).identityDao);
final groupDaoProvider = Provider((ref) => ref.read(appDatabaseProvider).groupDao);
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
  final builder = SyncPayloadBuilder(
    ref.read(msgpackProvider),
    ref.read(compressorProvider),
    ref.read(cryptoServiceProvider),
    ref.read(keyStorageProvider),
    ref.read(frameEncoderProvider),
  );
  return PrepareSyncPacketUsecase(ref.read(syncRepositoryProvider), builder);
});
final applySyncUsecaseProvider = Provider((ref) =>
    ApplySyncPacketUsecase(ref.read(syncRepositoryProvider), ref.read(groupRepositoryProvider)));
