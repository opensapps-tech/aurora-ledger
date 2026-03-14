import 'package:flutter/material.dart';
import '../common/identity_avatar.dart';

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.identityId,
    required this.alias,
    this.isCurrentUser = false,
  });

  final String identityId;
  final String alias;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IdentityAvatar(identityId: identityId, alias: alias),
      title: Row(
        children: [
          Text(alias),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).secondaryHeaderColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'You',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
