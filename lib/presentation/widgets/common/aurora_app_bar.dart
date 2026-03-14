import 'package:flutter/material.dart';

class AuroraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuroraAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.centerTitle,
  });

  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool? centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      leading: leading,
      centerTitle: centerTitle,
    );
  }
}
