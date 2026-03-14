import 'package:flutter/material.dart';

class ParticipantSelector extends StatelessWidget {
  const ParticipantSelector({
    super.key,
    required this.memberIdentityIds,
    required this.identityAliases,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<String> memberIdentityIds;
  final Map<String, String> identityAliases;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Split between:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: memberIdentityIds.map((id) {
            final alias = identityAliases[id] ?? id.substring(0, 8);
            final isSelected = selectedIds.contains(id);
            return FilterChip(
              label: Text(alias),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = Set<String>.from(selectedIds);
                if (selected) {
                  newSelection.add(id);
                } else {
                  if (newSelection.length > 1) {
                    newSelection.remove(id);
                  }
                }
                onChanged(newSelection);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
