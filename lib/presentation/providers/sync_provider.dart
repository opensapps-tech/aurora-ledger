import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/sync_constants.dart';
import '../../infrastructure/sync/qr_frame_decoder.dart';
import 'service_providers.dart';

part 'sync_provider.freezed.dart';
part 'sync_provider.g.dart';

enum SyncPhase { idle, sending, receiving, complete, error }

@freezed
class SyncState with _$SyncState {
  const factory SyncState({
    @Default(SyncPhase.idle) SyncPhase phase,
    @Default([]) List<List<int>> outboundFrames,
    @Default(0) int currentFrameIndex,
    @Default(0.0) double scanProgress,
    String? errorMessage,
    DateTime? completedAt,
  }) = _SyncState;
}

@riverpod
class SyncNotifier extends _$SyncNotifier {
  QrFrameDecoder? _decoder;
  Timer? _frameTimer;

  @override
  SyncState build(String groupId) {
    ref.onDispose(() {
      _frameTimer?.cancel();
    });
    return const SyncState();
  }

  Future<void> startSend({required Set<String> remoteKnownIds}) async {
    state = state.copyWith(phase: SyncPhase.sending);
    
    final prepareSyncPacketUsecase = ref.read(prepareSyncUsecaseProvider);
    final result = await prepareSyncPacketUsecase.call(
      groupId: groupId,
      remoteKnownOperationIds: remoteKnownIds,
    );

    result.when(
      ok: (frames) {
        state = state.copyWith(
          outboundFrames: frames,
          currentFrameIndex: 0,
        );
        _startAnimationTimer();
      },
      err: (failure) {
        state = state.copyWith(
          phase: SyncPhase.error,
          errorMessage: failure.message,
        );
      },
    );
  }

  void _startAnimationTimer() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(
      const Duration(milliseconds: 1000 ~/ SyncConstants.qrDisplayFps),
      (_) => nextFrame(),
    );
  }

  void nextFrame() {
    if (state.outboundFrames.isEmpty) return;
    
    state = state.copyWith(
      currentFrameIndex: (state.currentFrameIndex + 1) % state.outboundFrames.length,
    );
  }

  void onFrameScanned(List<int> rawFrame) async {
    _decoder ??= QrFrameDecoder();
    
    final result = _decoder!.addFrame(rawFrame);
    
    state = state.copyWith(
      scanProgress: _decoder!.progress,
    );

    await result.when(
      ok: (assembledPayload) async {
        if (assembledPayload != null) {
          state = state.copyWith(phase: SyncPhase.receiving);
          
          final applySyncUsecase = ref.read(applySyncUsecaseProvider);
          final applyResult = await applySyncUsecase.call(
            groupId: groupId,
            encryptedPayload: assembledPayload,
          );

          applyResult.when(
            ok: (_) {
              state = state.copyWith(
                phase: SyncPhase.complete,
                completedAt: DateTime.now(),
              );
            },
            err: (failure) {
              state = state.copyWith(
                phase: SyncPhase.error,
                errorMessage: failure.message,
              );
            },
          );
        }
      },
      err: (failure) {
        state = state.copyWith(
          phase: SyncPhase.error,
          errorMessage: failure.message,
        );
      },
    );
  }

  void reset() {
    _frameTimer?.cancel();
    _decoder = null;
    state = const SyncState();
  }
}
