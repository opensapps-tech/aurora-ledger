import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/identity_provider.dart';
import '../../widgets/common/aurora_button.dart';
import '../../widgets/expense/amount_input_field.dart';
import '../../widgets/expense/participant_selector.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _payerId;
  Set<String> _selectedParticipants = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current user as payer if possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaults();
    });
  }

  void _initDefaults() {
    final identity = ref.read(identityNotifierProvider).value;
    final groups = ref.read(groupNotifierProvider).value;
    if (groups == null) return;
    
    final group = groups.firstWhere((g) => g.groupId == widget.groupId);
    
    setState(() {
      _payerId = identity?.identityId ?? group.creatorIdentityId;
      // In a real app, identityId is derived from publicKey.
      // Here we need to be careful with IDs vs public keys.
      // Group entity has memberPublicKeys.
      // Expense entity uses identityIds.
      
      // Let's assume for now that identityId is available.
      _selectedParticipants = Set.from(group.memberPublicKeys.map((pk) => pk)); // Simplified
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payerId == null) return;

    final amountDouble = double.parse(_amountController.text);
    final amountMinorUnits = (amountDouble * 100).toInt();

    final groups = ref.read(groupNotifierProvider).value;
    final group = groups!.firstWhere((g) => g.groupId == widget.groupId);

    setState(() => _isLoading = true);

    final result = await ref.read(expenseNotifierProvider(widget.groupId).notifier).add(
      groupId: widget.groupId,
      amountMinorUnits: amountMinorUnits,
      currency: group.currency,
      payerIdentityId: _payerId!,
      participantIdentityIds: _selectedParticipants.toList(),
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      result.when(
        ok: (_) => context.pop(),
        err: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: groupsAsync.when(
        data: (groups) {
          final group = groups.firstWhere((g) => g.groupId == widget.groupId);
          final members = group.memberPublicKeys;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  AmountInputField(
                    controller: _amountController,
                    currency: group.currency,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'What was it for?',
                      hintText: 'e.g. Dinner',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter a description' : null,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _payerId,
                    decoration: const InputDecoration(labelText: 'Paid by'),
                    items: members.map((id) {
                      return DropdownMenuItem(
                        value: id,
                        child: Text(id.substring(0, 8)), // TODO: use real alias
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _payerId = val),
                  ),
                  const SizedBox(height: 24),
                  ParticipantSelector(
                    memberIdentityIds: members,
                    identityAliases: {}, // TODO
                    selectedIds: _selectedParticipants,
                    onChanged: (val) => setState(() => _selectedParticipants = val),
                  ),
                  const SizedBox(height: 40),
                  AuroraButton(
                    label: 'Add Expense',
                    isLoading: _isLoading,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
