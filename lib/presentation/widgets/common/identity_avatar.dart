import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class IdentityAvatar extends StatelessWidget {
  const IdentityAvatar({
    super.key,
    required this.identityId,
    required this.alias,
    this.radius = 20,
  });

  final String identityId;
  final String alias;
  final double radius;

  Color _getDeterministicColor() {
    final bytes = utf8.encode(identityId);
    final hash = sha256.convert(bytes);
    final h = (hash.bytes[0] + (hash.bytes[1] << 8)) % 360;
    return HSVColor.fromAHSV(1.0, h.toDouble(), 0.6, 0.8).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final initials = alias.isNotEmpty ? alias[0].toUpperCase() : '?';
    final backgroundColor = _getDeterministicColor();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
