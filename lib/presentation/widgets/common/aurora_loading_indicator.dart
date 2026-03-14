import 'package:flutter/material.dart';

class AuroraLoadingIndicator extends StatelessWidget {
  const AuroraLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
