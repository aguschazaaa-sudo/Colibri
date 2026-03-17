import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/landing/widgets/landing_footer.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
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
                      'Términos y Condiciones de Uso de Colibrí',
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
                    const _SectionTitle(
                      title: '1. Naturaleza del Servicio (SaaS B2B)',
                    ),
                    const _SectionText(
                      text:
                          'Colibrí es una plataforma de Software como Servicio (SaaS) diseñada exclusivamente para prestadores de salud autónomos ("Profesionales"). La plataforma facilita el seguimiento de saldos y envíos automáticos de recordatorios a pacientes. El Profesional actúa como suscriptor del servicio y es el único titular de la cuenta y responsable de los datos ingresados.',
                    ),

                    const _SectionTitle(
                      title: '2. Aislamiento de Datos (Multi-tenancy)',
                    ),
                    const _SectionText(
                      text:
                          'Colibrí garantiza un aislamiento total lógico y técnico entre las cuentas. Los datos ingresados por un Profesional A no tienen ningún tipo de relación, visibilidad ni conexión técnica con los datos del Profesional B. El profesional es el dueño exclusivo de la información de sus pacientes.',
                    ),

                    const _SectionTitle(
                      title: '3. El Motor de Deuda ("Ledger")',
                    ),
                    const _SectionText(
                      text:
                          'El uso de Colibrí implica la aceptación de su lógica contable. Todo "Turno" creado generará automáticamente un saldo deudor por su monto. Los ingresos o "Pagos" se aplicarán total o parcialmente a la deuda más antigua del paciente (criterio FIFO) salvo que el Profesional indique lo contrario de forma explícita en la operación.',
                    ),

                    const _SectionTitle(title: '4. Recordatorios por WhatsApp'),
                    const _SectionText(
                      text:
                          'Colibrí utiliza integraciones automatizadas (WhatsApp Business API) para enviar notificaciones a pacientes con saldos pendientes. El Profesional autoriza el envío de dichas comunicaciones en su nombre, asumiendo la responsabilidad sobre la exactitud de los montos cargados y consintiendo que el sistema priorice evitar la duplicidad de mensajes en periodos regulares.',
                    ),

                    const _SectionTitle(
                      title: '5. Pagos de Suscripción y Accesos',
                    ),
                    const _SectionText(
                      text:
                          'El servicio se ofrece mediante suscripción mensual. Si el estado de pago del Profesional entra en mora ("past_due") o es suspendido por impago ("suspended"), Colibrí bloqueará temporalmente la creación de nuevos datos (Turnos/Pacientes) pero mantendrá el acceso en modo lectura a la información preexistente para consulta. Los planes Base y Premium limitan características específicas, como el volumen de envíos mensuales.',
                    ),

                    const _SectionTitle(
                      title: '6. Responsabilidad sobre los Datos',
                    ),
                    const _SectionText(
                      text:
                          'Colibrí es una herramienta financiera y de gestión de agendas. El Profesional se compromete expresamente a NO utilizar Colibrí como Historia Clínica y se abstendrá de cargar diagnósticos, evoluciones, recetas o cualquier nota médica sensible que escape al estricto "Concepto del turno" (ej: "Consulta", "Sesión").',
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
