import 'package:equatable/equatable.dart';

/// Net balance for a single member within a group.
class MemberBalance extends Equatable {
  const MemberBalance({
    required this.identityId,
    required this.alias,
    required this.netAmountMinorUnits,
    required this.currency,
  });

  final String identityId;
  final String alias;

  /// Positive = owed money by others. Negative = owes others.
  final int netAmountMinorUnits;
  final String currency;

  double get netAmount => netAmountMinorUnits / 100.0;
  bool get isSettled => netAmountMinorUnits == 0;

  @override
  List<Object?> get props => [identityId, netAmountMinorUnits, currency];
}

/// A simplified settlement transaction produced by the min-cost flow algorithm.
class Settlement extends Equatable {
  const Settlement({
    required this.fromIdentityId,
    required this.toIdentityId,
    required this.amountMinorUnits,
    required this.currency,
  });

  final String fromIdentityId;
  final String toIdentityId;
  final int amountMinorUnits;
  final String currency;

  double get amount => amountMinorUnits / 100.0;

  @override
  List<Object?> get props => [fromIdentityId, toIdentityId, amountMinorUnits, currency];
}
