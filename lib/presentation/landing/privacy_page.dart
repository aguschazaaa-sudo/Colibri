import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/landing/widgets/landing_footer.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Política de Privacidad',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.sectionPadding(context),
              child: AppSpacing.constrained(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Política de Privacidad de Colibrí',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Última actualización: Noviembre 2024',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _SectionTitle(title: '1. Tipos de Datos Recopilados'),
                    const _SectionText(
                      text:
                          'Colibrí recolecta y almacena, bajo la administración del Profesional de la Salud ("Usted"), datos limitados estrictamente a la gestión financiera y operativa: Nombres y apellidos de pacientes, números de teléfono para notificaciones, fechas de turnos, conceptos administrativos (ej: "consulta", "sesión") y saldos/pagos. Colibrí encripta y protege las credenciales de los Profesionales (emails, contraseñas, tokens de autenticación).',
                    ),

                    const _SectionTitle(
                      title: '2. Prohibición de Datos Clínicos Sensibles',
                    ),
                    const _SectionText(
                      text:
                          'Nuestra arquitectura está diseñada para la gestión financiera. Queda terminantemente prohibido, tanto a nivel operativo como según nuestras Reglas de Seguridad y Privacidad, la inclusión de expedientes médicos, historiales clínicos, notas de diagnóstico o información sensible protegida por leyes de salud en campos de texto de la aplicación.',
                    ),

                    const _SectionTitle(
                      title: '3. Aislamiento Tecnológico y de Seguridad',
                    ),
                    const _SectionText(
                      text:
                          'El almacenamiento (Firestore) aplica firewalls lógicos a todas las consultas mediante el "providerId". Esto previene de forma mandatoria que datos pertenecientes a un Profesional sean interrogados o servidos accidentalmente a otra cuenta, cumpliendo estrictas normas de Multi-tenancy. Por seguridad, Colibrí también suprime "Información de Identidad Personal (PII)" (ej: nombres y montos) en todos sus logs de servidor de producción.',
                    ),

                    const _SectionTitle(
                      title:
                          '4. Compartición con Terceros (Comunicación WhatsApp)',
                    ),
                    const _SectionText(
                      text:
                          'Para cumplir su funcionalidad principal, Colibrí transfiere los números de teléfono, nombres y montos adeudados específicos a canales seguros de la API oficial de WhatsApp Business (Meta). Meta actúa como procesador de estas comunicaciones. Colibrí no vende ni cede bases de datos de pacientes a anunciantes o terceros bajo ningún concepto.',
                    ),

                    const _SectionTitle(
                      title: '5. Derechos del Profesional y de sus Pacientes',
                    ),
                    const _SectionText(
                      text:
                          'El Profesional que suscribe el servicio es el Custodio / Responsable de los Datos. Tiene control total para crear, editar o eliminar los registros de sus pacientes dentro de la plataforma. Si cancela la suscripción, los registros podrán permanecer bloqueados y, tras el período de retención legal, serán eliminados definitivamente de la base de datos central.',
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  const _SectionText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.6,
      ),
    );
  }
}
