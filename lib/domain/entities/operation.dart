import 'package:equatable/equatable.dart';

/// Every mutation to the shared ledger is an immutable, signed operation.
/// The ledger is append-only. Nothing is ever deleted from the op-log.
class Operation extends Equatable {
  const Operation({
    required this.operationId,
    required this.groupId,
    required this.authorPublicKey,
    required this.hlcTimestamp,
    required this.type,
    required this.payload,
    required this.signature,
  });

  final String operationId;
  final String groupId;

  /// Ed25519 public key of the device that created this operation.
  final String authorPublicKey;

  /// Hybrid Logical Clock timestamp: [physicalMs, logicalCounter].
  final HlcTimestamp hlcTimestamp;

  final OperationType type;

  /// MessagePack-encoded operation payload. Type-specific structure.
  final List<int> payload;

  /// Ed25519 signature over (operationId + groupId + hlcTimestamp + type + payload).
  final List<int> signature;

  @override
  List<Object?> get props => [operationId, groupId, authorPublicKey, hlcTimestamp, type, signature];
}

enum OperationType {
  addExpense,
  editExpense,
  deleteExpense,
  settlePayment,
  addMember,    // future: group membership changes
}

/// Hybrid Logical Clock timestamp for causal ordering.
/// Replaces raw wall-clock timestamps to handle device clock drift.
class HlcTimestamp extends Equatable implements Comparable<HlcTimestamp> {
  const HlcTimestamp({required this.physicalMs, required this.logical});

  /// Wall-clock milliseconds (max of local and received timestamps).
  final int physicalMs;

  /// Logical counter for tie-breaking within the same physical millisecond.
  final int logical;

  @override
  int compareTo(HlcTimestamp other) {
    final cmp = physicalMs.compareTo(other.physicalMs);
    return cmp != 0 ? cmp : logical.compareTo(other.logical);
  }

  @override
  List<Object?> get props => [physicalMs, logical];

  @override
  String toString() => '$physicalMs:$logical';
}
