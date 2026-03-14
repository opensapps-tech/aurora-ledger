import 'package:aurora_ledger/core/extensions/datetime_extensions.dart';
import 'package:equatable/equatable.dart';

/// A shared expense group.
/// Identified by [groupId]; holds a symmetric [groupKey] for payload encryption.
class Group extends Equatable {
  const Group({
    required this.groupId,
    required this.name,
    required this.currency,
    required this.createdAt,
    required this.creatorIdentityId,
    required this.memberPublicKeys,
    this.lastSyncedAt,
  });

  final String groupId;
  final String name;

  /// ISO 4217 currency code. Single-currency by design. e.g. 'GBP'.
  final String currency;

  final DateTime createdAt;
  final String creatorIdentityId;

  /// Public keys of all group members (hex-encoded).
  final List<String> memberPublicKeys;

  /// Last time this device successfully completed a bilateral sync.
  final DateTime? lastSyncedAt;

  bool get requiresSyncWarning {
    if (lastSyncedAt == null) return memberPublicKeys.length > 1;
    return lastSyncedAt!.isOlderThan(hours: 24);
  }

  @override
  List<Object?> get props => [
        groupId, name, currency, createdAt,
        creatorIdentityId, memberPublicKeys, lastSyncedAt,
      ];
}
