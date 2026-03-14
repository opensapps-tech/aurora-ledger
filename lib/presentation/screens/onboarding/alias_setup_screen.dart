import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../providers/identity_provider.dart';
import '../../widgets/common/aurora_button.dart';

class AliasSetupScreen extends ConsumerStatefulWidget {
  const AliasSetupScreen({super.key});

  @override
  ConsumerState<AliasSetupScreen> createState() => _AliasSetupScreenState();
}

class _AliasSetupScreenState extends ConsumerState<AliasSetupScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleCreateIdentity() async {
    final alias = _controller.text.trim();
    if (alias.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await ref.read(identityNotifierProvider.notifier).create(alias: alias);

    if (mounted) {
      setState(() => _isLoading = false);
      result.when(
        ok: (_) => context.go(Routes.home),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What should we call you?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLength: 30,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter your alias',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stored only on this device. Cosmetic only.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const Spacer(),
          AuroraButton(
            label: 'Create identity',
            isLoading: _isLoading,
            onPressed: _handleCreateIdentity,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
