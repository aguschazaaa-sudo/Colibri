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

  String get _typeLabel => switch (log.messageType) {
        'appointment_reminder' => 'Recordatorio de turno',
        'payment_reminder' => 'Aviso de deuda',
        _ => 'Recordatorio',
      };

  String get _contentSnippet {
    final vars = log.variables;
    switch (log.messageType) {
      case 'appointment_reminder':
        final fecha = vars?['fecha_turno'];
        final hora = vars?['hora_turno'];
        if (fecha != null && hora != null) return '$fecha a las $hora';
        if (fecha != null) return fecha;
        return '';
      case 'payment_reminder':
        // Prefer monto_total from template variables (already formatted).
        // Fall back to totalDebtAtThatTime if variables are unavailable.
        final montoTotal = vars?['monto_total'];
        if (montoTotal != null && montoTotal.isNotEmpty) return montoTotal;
        final amount = log.totalDebtAtThatTime;
        return NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 0)
            .format(amount);
      default:
        // Task 6.2: handles null and unknown messageType gracefully — returns empty string.
        return '';
    }
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_typeLabel, style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
          Row(
            children: [
              if (_contentSnippet.isNotEmpty) ...[
                Text(_contentSnippet, style: textTheme.bodySmall),
                const SizedBox(width: 4),
                Text('·', style: textTheme.bodySmall),
                const SizedBox(width: 4),
              ],
              Text(_relativeTime(context), style: textTheme.bodySmall),
              const SizedBox(width: 6),
              Icon(Icons.chat_bubble_rounded, size: 13, color: colorScheme.tertiary),
            ],
          ),
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
