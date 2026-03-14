import 'package:aurora_ledger/domain/entities/operation.dart';

/// Hybrid Logical Clock (HLC) for causal operation ordering.
///
/// Solves the mobile clock problem: device clocks drift, jump on NTP sync,
/// and can be manually set. HLC gives monotonically increasing timestamps
/// that respect causality even across disconnected devices.
///
/// Reference: Kulkarni et al., "Logical Physical Clocks", 2014.
/// Implementation: ~60 LOC, zero dependencies.
class HybridLogicalClock {
  HybridLogicalClock() : _last = HlcTimestamp(physicalMs: 0, logical: 0);

  HlcTimestamp _last;

  /// Returns the current HLC timestamp for a locally-created event.
  HlcTimestamp now() {
    final wallMs = DateTime.now().millisecondsSinceEpoch;
    final physMs = wallMs > _last.physicalMs ? wallMs : _last.physicalMs;
    final logical = physMs == _last.physicalMs ? _last.logical + 1 : 0;
    _last = HlcTimestamp(physicalMs: physMs, logical: logical);
    return _last;
  }

  /// Advances the clock on receiving a remote timestamp.
  /// Call this when applying an incoming operation before recording it.
  HlcTimestamp receive(HlcTimestamp remote) {
    final wallMs = DateTime.now().millisecondsSinceEpoch;
    final physMs = [wallMs, _last.physicalMs, remote.physicalMs].reduce((a, b) => a > b ? a : b);
    final int logical;
    if (physMs == _last.physicalMs && physMs == remote.physicalMs) {
      logical = [_last.logical, remote.logical].reduce((a, b) => a > b ? a : b) + 1;
    } else if (physMs == _last.physicalMs) {
      logical = _last.logical + 1;
    } else if (physMs == remote.physicalMs) {
      logical = remote.logical + 1;
    } else {
      logical = 0;
    }
    _last = HlcTimestamp(physicalMs: physMs, logical: logical);
    return _last;
  }

  HlcTimestamp get current => _last;
}
