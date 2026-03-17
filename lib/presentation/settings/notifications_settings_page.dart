import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                        Icons.construction_rounded,
                        size: 80,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(150),
                      )
                      .animate(
                        onPlay:
                            (controller) => controller.repeat(reverse: true),
                      )
                      .scaleXY(
                        begin: 1.0,
                        end: 1.1,
                        duration: 1.seconds,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '¡Página en construcción!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Estamos trabajando para que pronto puedas personalizar tus plantillas de mensajes de WhatsApp.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),
        ),
      ),
    );
  }
}
