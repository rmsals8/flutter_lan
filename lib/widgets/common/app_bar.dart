import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation,
      centerTitle: false,
      iconTheme: const IconThemeData(
        color: AppTheme.primaryColor, // 뒤로가기 버튼 등의 색상
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}