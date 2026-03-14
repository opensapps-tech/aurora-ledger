import 'package:equatable/equatable.dart';

/// A shared expense computed from ADD_EXPENSE / EDIT_EXPENSE operations.
/// This is a read-model projected from the operation log — never stored directly.
class Expense extends Equatable {
  const Expense({
    required this.expenseId,
    required this.groupId,
    required this.amountMinorUnits,
    required this.currency,
    required this.payerIdentityId,
    required this.participantIdentityIds,
    required this.notes,
    required this.createdAt,
    required this.authorPublicKey,
    this.isDeleted = false,
    this.editedAt,
  });

  final String expenseId;
  final String groupId;

  /// Amount in minor units (pence, cents) to avoid floating-point arithmetic.
  final int amountMinorUnits;

  final String currency;
  final String payerIdentityId;
  final List<String> participantIdentityIds;
  final String notes;
  final DateTime createdAt;
  final String authorPublicKey;
  final bool isDeleted;
  final DateTime? editedAt;

  /// Amount as a display decimal. e.g. 1050 → 10.50
  double get amount => amountMinorUnits / 100.0;

  /// Amount owed per participant (equal split).
  double get splitAmount => participantIdentityIds.isEmpty
      ? 0
      : amount / participantIdentityIds.length;

  // TODO: Extend with custom split ratios (v2 feature)

  @override
  List<Object?> get props => [
        expenseId, groupId, amountMinorUnits, currency,
        payerIdentityId, participantIdentityIds, notes, createdAt, isDeleted,
      ];

  Expense copyWith({
    String? expenseId,
    String? groupId,
    int? amountMinorUnits,
    String? currency,
    String? payerIdentityId,
    List<String>? participantIdentityIds,
    String? notes,
    DateTime? createdAt,
    String? authorPublicKey,
    bool? isDeleted,
    DateTime? editedAt,
  }) {
    return Expense(
      expenseId: expenseId ?? this.expenseId,
      groupId: groupId ?? this.groupId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currency: currency ?? this.currency,
      payerIdentityId: payerIdentityId ?? this.payerIdentityId,
      participantIdentityIds: participantIdentityIds ?? this.participantIdentityIds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      authorPublicKey: authorPublicKey ?? this.authorPublicKey,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
