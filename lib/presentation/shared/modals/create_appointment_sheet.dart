import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/overlap_check_provider.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/shared/modals/danger_confirmation_dialog.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

class CreateAppointmentSheet extends ConsumerStatefulWidget {
  final String? initialPatientId;
  final Appointment? existingAppointment;

  const CreateAppointmentSheet({
    super.key,
    this.initialPatientId,
    this.existingAppointment,
  });

  @override
  ConsumerState<CreateAppointmentSheet> createState() =>
      _CreateAppointmentSheetState();
}

class _CreateAppointmentSheetState
    extends ConsumerState<CreateAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String _concept = '';
  double _amount = 0.0;
  DateTime _selectedDate = DateTime.now();
  int? _sessionDurationMinutes;
  final CurrencyTextInputFormatter _formatter =
      CurrencyTextInputFormatter.currency(
        locale: 'es_AR',
        symbol: '',
        decimalDigits: 0,
      );

  @override
  void initState() {
    super.initState();
    if (widget.existingAppointment != null) {
      final app = widget.existingAppointment!;
      _selectedPatientId = app.patientId;
      _concept = app.concept;
      _amount = app.totalAmount;
      _selectedDate = app.date;
      if (app.endTime != null) {
        final diff = app.endTime!.difference(app.date).inMinutes;
        if (diff > 0) _sessionDurationMinutes = diff;
      }
    } else {
      _selectedPatientId = widget.initialPatientId;
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? _selectedDate.hour,
          pickedTime?.minute ?? _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final auth = ref.read(firebaseAuthProvider);
        final providerId = auth.currentUser?.uid;
        if (providerId == null) throw Exception('No user logged in');

        if (_selectedPatientId == null) {
          throw Exception('Paciente no seleccionado');
        }

        final providerDefault =
            ref.read(authStateProvider).value?.defaultSessionDurationMinutes ??
            45;
        final duration = _sessionDurationMinutes ?? providerDefault;
        final computedEndTime = _selectedDate.add(Duration(minutes: duration));

        final now = DateTime.now();
        final isEdit = widget.existingAppointment != null;

        if (isEdit) {
          final updatedStatus = _amount == 0
              ? AppointmentStatus.liquidated
              : (widget.existingAppointment!.amountPaid >= _amount
                  ? AppointmentStatus.liquidated
                  : (_selectedDate.isAfter(now) &&
                            widget.existingAppointment!.amountPaid == 0
                        ? AppointmentStatus.scheduled
                        : AppointmentStatus.unpaid));

          final updatedAppointment = widget.existingAppointment!.copyWith(
            date: _selectedDate,
            concept: _concept,
            totalAmount: _amount,
            status: updatedStatus,
            endTime: computedEndTime,
          );

          await ref
              .read(
                ledgerProvider(
                  providerId: providerId,
                  patientId: _selectedPatientId!,
                ).notifier,
              )
              .updateAppointment(updatedAppointment);
        } else {
          final status = _amount == 0
              ? AppointmentStatus.liquidated
              : (_selectedDate.isAfter(now)
                  ? AppointmentStatus.scheduled
                  : AppointmentStatus.unpaid);

          final newAppointment = Appointment(
            id: '',
            patientId: _selectedPatientId!,
            providerId: providerId,
            date: _selectedDate,
            concept: _concept,
            totalAmount: _amount,
            amountPaid: 0.0,
            status: status,
            endTime: computedEndTime,
          );

          await ref
              .read(
                ledgerProvider(
                  providerId: providerId,
                  patientId: _selectedPatientId!,
                ).notifier,
              )
              .createAppointment(newAppointment);
        }

        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Turno agendado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;
    final providerDefault =
        ref.watch(authStateProvider).value?.defaultSessionDurationMinutes ?? 45;
    final computedEndTime = _selectedDate.add(
      Duration(minutes: _sessionDurationMinutes ?? providerDefault),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: insets.bottom + AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existingAppointment != null
                  ? 'Editar Turno'
                  : 'Agendar Turno',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            _PatientDropdown(
              selectedPatientId: _selectedPatientId,
              onChanged: (v) => setState(() => _selectedPatientId = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _StartDateField(
              selectedDate: _selectedDate,
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SessionDurationField(
              selectedDuration: _sessionDurationMinutes,
              providerDefault: providerDefault,
              onChanged: (v) => setState(() => _sessionDurationMinutes = v),
            ),
            if (providerId != null && _selectedPatientId != null)
              _OverlapWarnings(
                providerId: providerId,
                selectedDate: _selectedDate,
                endTime: computedEndTime,
                patientId: _selectedPatientId!,
                excludeAppointmentId: widget.existingAppointment?.id,
              ),
            _NonWorkingDayWarnings(selectedDate: _selectedDate),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: _concept,
              decoration: const InputDecoration(
                labelText: 'Concepto (e.g. Consulta general)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _concept = v ?? '',
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: widget.existingAppointment != null && _amount >= 0
                  ? _amount.toInt().toString()
                  : null,
              decoration: const InputDecoration(
                labelText: 'Monto a cobrar',
                prefixIcon: Icon(Icons.attach_money_rounded),
                helperText: 'Ingresá 0 para sesiones de obra social',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_formatter],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (_formatter.getUnformattedValue() < 0) {
                  return 'Monto inválido';
                }
                return null;
              },
              onSaved: (v) =>
                  _amount = _formatter.getUnformattedValue().toDouble(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FormActions(
              existingAppointment: widget.existingAppointment,
              selectedPatientId: _selectedPatientId,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Extracted widgets ────────────────────────────────────────────────────────

class _PatientDropdown extends ConsumerWidget {
  const _PatientDropdown({
    required this.selectedPatientId,
    required this.onChanged,
  });

  final String? selectedPatientId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) return const SizedBox.shrink();

    final patientsAsync = ref.watch(patientsProvider(providerId));

    return patientsAsync.when(
      data: (patients) {
        if (patients.isEmpty) {
          return const Text('Agregue un paciente primero');
        }
        return FormField<String>(
          initialValue: selectedPatientId,
          validator: (v) => v == null ? 'Seleccione un paciente' : null,
          builder: (state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<String>(
                  initialSelection: selectedPatientId,
                  width: constraints.maxWidth,
                  menuHeight: 240,
                  label: const Text('Paciente'),
                  leadingIcon: const Icon(Icons.person_outline_rounded),
                  enableFilter: true,
                  enableSearch: true,
                  errorText: state.errorText,
                  dropdownMenuEntries: patients.map((p) {
                    return DropdownMenuEntry(value: p.id, label: p.name);
                  }).toList(),
                  onSelected: (v) {
                    onChanged(v);
                    state.didChange(v);
                  },
                );
              },
            );
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error al cargar pacientes: $e'),
    );
  }
}

class _StartDateField extends StatelessWidget {
  const _StartDateField({
    required this.selectedDate,
    required this.onTap,
  });

  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha y Hora del Turno',
          prefixIcon: Icon(Icons.calendar_today_rounded),
        ),
        child: Text(DateFormat('dd/MM/yyyy HH:mm').format(selectedDate)),
      ),
    );
  }
}

class _SessionDurationField extends StatelessWidget {
  const _SessionDurationField({
    required this.selectedDuration,
    required this.providerDefault,
    required this.onChanged,
  });

  final int? selectedDuration;
  final int providerDefault;
  final ValueChanged<int?> onChanged;

  static const _options = [15, 30, 45, 50, 60, 75, 90, 120];

  String _fmt(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selectedDuration,
      decoration: const InputDecoration(
        labelText: 'Duración de la sesión',
        prefixIcon: Icon(Icons.timer_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text('Por defecto (${_fmt(providerDefault)})'),
        ),
        ..._options.map(
          (m) => DropdownMenuItem<int?>(value: m, child: Text(_fmt(m))),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Non-blocking overlap warning banners shown below the date fields.
class _OverlapWarnings extends ConsumerWidget {
  const _OverlapWarnings({
    required this.providerId,
    required this.selectedDate,
    required this.endTime,
    required this.patientId,
    required this.excludeAppointmentId,
  });

  final String providerId;
  final DateTime selectedDate;
  final DateTime endTime;
  final String patientId;
  final String? excludeAppointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      providerId: providerId,
      selectedDate: selectedDate,
      endTime: endTime,
      patientId: patientId,
      excludeAppointmentId: excludeAppointmentId,
    );

    final overlapAsync = ref.watch(overlapCheckProvider(params));

    return overlapAsync.when(
      data: (result) {
        if (!result.hasOverlap) return const SizedBox.shrink();
        return Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            if (result.samePatient.isNotEmpty)
              const _OverlapBanner(
                isMajor: true,
                message: 'Este paciente ya tiene un turno en este horario',
              ),
            if (result.otherPatients.isNotEmpty)
              const _OverlapBanner(
                isMajor: false,
                message: 'Otro paciente tiene un turno en este horario',
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OverlapBanner extends StatelessWidget {
  const _OverlapBanner({
    required this.isMajor,
    required this.message,
  });

  final bool isMajor;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        isMajor ? colorScheme.errorContainer : colorScheme.tertiaryContainer;
    final foregroundColor = isMajor
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;
    final icon = isMajor
        ? Icons.warning_rounded
        : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: foregroundColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Informational banners when the selected date falls on a holiday or vacation.
class _NonWorkingDayWarnings extends ConsumerWidget {
  const _NonWorkingDayWarnings({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(authStateProvider);
    final provider = providerAsync.valueOrNull;
    if (provider == null) return const SizedBox.shrink();

    final mmDd =
        '${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final isHoliday = provider.nonWorkingDays.contains(mmDd);
    final isVacation = provider.vacations.any(
      (v) =>
          !selectedDate.isBefore(v.startDate) &&
          !selectedDate.isAfter(v.endDate),
    );

    if (!isHoliday && !isVacation) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (isHoliday)
          _OverlapBanner(
            isMajor: false,
            message: 'Este día es feriado: ${_getHolidayName(mmDd)}',
          ),
        if (isVacation)
          const _OverlapBanner(
            isMajor: false,
            message: 'Este día cae en un período de vacaciones',
          ),
      ],
    );
  }

  String _getHolidayName(String mmDd) {
    switch (mmDd) {
      case '01-01':
        return 'Año Nuevo';
      case '03-24':
        return 'Día de la Memoria';
      case '04-02':
        return 'Día de Malvinas';
      case '05-01':
        return 'Día del Trabajador';
      case '05-25':
        return 'Revolución de Mayo';
      case '06-20':
        return 'Día de la Bandera';
      case '07-09':
        return 'Día de la Independencia';
      case '12-08':
        return 'Inmaculada Concepción';
      case '12-25':
        return 'Navidad';
      default:
        return 'Feriado';
    }
  }
}

class _FormActions extends ConsumerWidget {
  const _FormActions({
    required this.existingAppointment,
    required this.selectedPatientId,
    required this.onSubmit,
  });

  final Appointment? existingAppointment;
  final String? selectedPatientId;
  final Future<void> Function() onSubmit;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DangerConfirmationDialog(
        title: 'Eliminar Turno',
        warningText:
            'Esta acción es irreversible. El turno se eliminará permanentemente '
            'y los pagos asociados serán redistribuidos o devueltos como saldo a favor.',
        confirmationWord: 'ELIMINAR',
        confirmButtonText: 'Eliminar turno',
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final auth = ref.read(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;
    if (providerId == null || selectedPatientId == null) return;

    await ref
        .read(
          ledgerProvider(
            providerId: providerId,
            patientId: selectedPatientId!,
          ).notifier,
        )
        .deleteAppointment(existingAppointment!.id);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (existingAppointment != null) ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _handleDelete(context, ref),
              child: const Text('Eliminar'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          flex: 2,
          child: ActionButton(
            onPressed: onSubmit,
            child: Text(
              existingAppointment != null ? 'Guardar Cambios' : 'Agendar Turno',
            ),
          ),
        ),
      ],
    );
  }
}
