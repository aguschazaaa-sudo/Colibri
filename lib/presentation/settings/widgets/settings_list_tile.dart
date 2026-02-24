import 'package:flutter/material.dart';

class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final primaryColor =
        isDestructive ? colorScheme.error : colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          color: primaryColor,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      isDestructive
                          ? colorScheme.error.withValues(alpha: 0.8)
                          : colorScheme.onSurfaceVariant,
                ),
              )
              : null,
      trailing:
          trailing ??
          (isDestructive
              ? null
              : const Icon(Icons.chevron_right_rounded, size: 20)),
      onTap: onTap,
    );
  }
}
