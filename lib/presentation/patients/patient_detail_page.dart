import 'dart:io';
import 'dart:ui' as ui;

import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/appointments/platform_share_stub.dart'
    if (dart.library.js_interop) 'package:cobrador/presentation/appointments/platform_share_web.dart';
import 'package:cobrador/presentation/patients/widgets/edit_patient_modal.dart';
import 'package:cobrador/presentation/patients/widgets/recurring_appointments_list.dart';
import 'package:cobrador/presentation/patients/widgets/unpaid_appointments_list.dart';
import 'package:cobrador/presentation/shared/modals/create_appointment_sheet.dart';
import 'package:cobrador/presentation/shared/modals/create_recurring_appointment_sheet.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';

import 'widgets/patient_debt_summary_card.dart';
import 'widgets/patient_header_card.dart';

class PatientDetailPage extends ConsumerWidget {
  final String patientId;
  final Patient? patientObj;

  const PatientDetailPage({
    super.key,
    required this.patientId,
    this.patientObj,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (patientObj != null) {
      return _PatientDetailBody(patient: patientObj!);
    }

    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) {
      ref.registerShell(title: 'Detalle de Paciente');
      return const Center(child: Text('Usuario no autenticado'));
    }

    final patientsAsync = ref.watch(patientsProvider(providerId));

    return patientsAsync.when(
      data: (patients) {
        final patient = patients.cast<Patient?>().firstWhere(
          (p) => p?.id == patientId,
          orElse: () => null,
        );

        if (patient == null) {
          ref.registerShell(title: 'Paciente no encontrado');
          return const Center(child: Text('Paciente no encontrado'));
        }

        return _PatientDetailBody(patient: patient);
      },
      loading: () {
        ref.registerShell(title: 'Cargando...');
        return const Center(child: CircularProgressIndicator());
      },
      error: (e, st) {
        ref.registerShell(title: 'Error');
        return Center(child: Text('Error: $e'));
      },
    );
  }
}

class _PatientDetailBody extends ConsumerStatefulWidget {
  final Patient patient;

  const _PatientDetailBody({required this.patient});

  @override
  ConsumerState<_PatientDetailBody> createState() =>
      _PatientDetailBodyState();
}

class _PatientDetailBodyState extends ConsumerState<_PatientDetailBody> {
  final _repaintKey = GlobalKey();

  Future<void> _shareAsImage() async {
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final fileName = 'paciente_${widget.patient.id}.png';

    if (kIsWeb) {
      await downloadBytesOnWeb(bytes, fileName);
      return;
    }

    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Ficha de ${widget.patient.name}',
    );
  }

  void _showAddAppointmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Turno puntual'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CreateAppointmentSheet(
                    initialPatientId: widget.patient.id,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: const Text('Turno recurrente'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CreateRecurringAppointmentSheet(
                    initialPatientId: widget.patient.id,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.registerShell(
      title: widget.patient.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          tooltip: 'Compartir ficha',
          onPressed: _shareAsImage,
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () =>
              showEditPatientModal(context, ref, widget.patient),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAppointmentMenu(context),
        child: const Icon(Icons.add),
      ),
    );

    final infoPanel = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PatientHeaderCard(patient: widget.patient),
          const SizedBox(height: AppSpacing.lg),
          PatientDebtSummaryCard(patient: widget.patient),
        ],
      ),
    );

    final appointmentsPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UnpaidAppointmentsList(patientId: widget.patient.id),
        const SizedBox(height: AppSpacing.lg),
        RecurringAppointmentsList(patientId: widget.patient.id),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppSpacing.breakpointSm;

        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 300, child: infoPanel),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: appointmentsPanel),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  infoPanel,
                  const SizedBox(height: AppSpacing.lg),
                  appointmentsPanel,
                ],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xxl,
          ),
          child: RepaintBoundary(
            key: _repaintKey,
            child: ColoredBox(
              color: colorScheme.surface,
              child: content,
            ),
          ),
        );
      },
    );
  }
}
