import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderHistoryItem extends StatelessWidget {
  const ReminderHistoryItem({super.key, required this.log});

  final CommunicationLog log;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _initials {
    final name = log.patientName ?? log.patientId;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  /// Returns a human-readable relative time string.
  String _relativeTime(BuildContext context) {
    final diff = DateTime.now().difference(log.sentAt);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return DateFormat('d MMM', 'es').format(log.sentAt);
  }

  // ── Status badge ──────────────────────────────────────────────────────────

  (String label, Color bg, Color fg) _statusBadge(ColorScheme cs) {
    return switch (log.status) {
      'sent' => ('Enviado', cs.tertiaryContainer, cs.onTertiaryContainer),
      'pending' => ('Pendiente', cs.secondaryContainer, cs.onSecondaryContainer),
      _ => ('Fallido', cs.errorContainer, cs.onErrorContainer),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (badgeLabel, badgeBg, badgeFg) = _statusBadge(colorScheme);
    final displayName = log.patientName ?? 'Paciente';

    return ListTile(
      contentPadding: AppSpacing.edgeInsetsH,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          _initials,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        displayName,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Text(_relativeTime(context), style: textTheme.bodySmall),
          const SizedBox(width: 6),
          // WhatsApp icon
          Icon(Icons.chat_bubble_rounded, size: 13, color: colorScheme.tertiary),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Text(
          badgeLabel,
          style: textTheme.labelSmall?.copyWith(
            color: badgeFg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
