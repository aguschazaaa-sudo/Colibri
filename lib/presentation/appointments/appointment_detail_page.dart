import 'dart:io';
import 'dart:ui' as ui;

import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/appointments/platform_share_stub.dart'
    if (dart.library.js_interop) 'package:cobrador/presentation/appointments/platform_share_web.dart';
import 'package:cobrador/presentation/appointments/widgets/appointment_branding_footer.dart';
import 'package:cobrador/presentation/appointments/widgets/appointment_detail_header.dart';
import 'package:cobrador/presentation/appointments/widgets/appointment_edit_button.dart';
import 'package:cobrador/presentation/appointments/widgets/appointment_financial_card.dart';
import 'package:cobrador/presentation/appointments/widgets/appointment_info_card.dart';
import 'package:cobrador/presentation/appointments/widgets/appointment_patient_balance_card.dart';
import 'package:cobrador/presentation/appointments/widgets/atoms/appointment_date_display.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Full-screen page that displays appointment details.
///
/// Designed as a "comprobante de turno" — screenshot-friendly so professionals
/// can share the capture with patients as a booking confirmation.
/// Lives outside the [ShellRoute] so no bottom navigation bar is shown.
class AppointmentDetailPage extends ConsumerStatefulWidget {
  final Appointment appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailPage> createState() =>
      _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends ConsumerState<AppointmentDetailPage> {
  final _repaintKey = GlobalKey();

  Future<void> _shareAsImage() async {
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final fileName = 'turno_${widget.appointment.id}.png';

    if (kIsWeb) {
      await downloadBytesOnWeb(bytes, fileName);
      return;
    }

    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: 'Detalle de turno');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(firebaseAuthProvider);
    final providerId =
        auth.currentUser?.uid ?? widget.appointment.providerId;

    final patientsAsync = ref.watch(patientsProvider(providerId));
    final patientName = patientsAsync.valueOrNull
            ?.where((p) => p.id == widget.appointment.patientId)
            .firstOrNull
            ?.name ??
        'Cargando...';
    final patient = patientsAsync.valueOrNull
        ?.where((p) => p.id == widget.appointment.patientId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primaryContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        leading: const BackButton(),
        title: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir turno',
            onPressed: _shareAsImage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _repaintKey,
          child: _DetailBody(
            appointment: widget.appointment,
            patientName: patientName,
            patient: patient,
          ),
        ),
      ),
      bottomNavigationBar:
          AppointmentEditButton(appointment: widget.appointment),
    );
  }
}

/// Extracted organism that holds the scrollable content.
///
/// Keeping it separate from [_AppointmentDetailPageState.build] keeps both
/// within the 60-80 line limit and isolates RepaintBoundary repaints.
class _DetailBody extends StatelessWidget {
  final Appointment appointment;
  final String patientName;
  final Patient? patient;

  const _DetailBody({
    required this.appointment,
    required this.patientName,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppointmentDetailHeader(
            patientName: patientName,
            status: appointment.status,
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: AppointmentDateDisplay(date: appointment.date),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppointmentInfoCard(appointment: appointment),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppointmentFinancialCard(appointment: appointment),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppointmentPatientBalanceCard(patient: patient),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const AppointmentBrandingFooter(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
