import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/presentation/providers/use_case_providers.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:cobrador/domain/provider.dart' as domain;

// --- Controller ---

final profileUpdateControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfileUpdateController, void>(
      ProfileUpdateController.new,
    );

class ProfileUpdateController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateProfile({
    required String name,
    required String profession,
    required int defaultSessionDurationMinutes,
  }) async {
    final currentProvider = ref.read(authStateProvider).value;
    if (currentProvider == null) return;

    state = const AsyncLoading();

    final useCase = ref.read(updateProviderProfileUseCaseProvider);
    final trimmed = profession.trim();
    final updatedProvider = currentProvider.copyWith(
      name: name,
      profession: trimmed.isEmpty ? null : trimmed,
      defaultSessionDurationMinutes: defaultSessionDurationMinutes,
    );

    final result = await useCase.execute(updatedProvider);

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

// --- Page ---

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _professionController;
  bool _isInit = false;
  int _sessionDurationMinutes = 45;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _professionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  void _initFields(domain.Provider provider) {
    if (!_isInit) {
      _nameController.text = provider.name;
      _professionController.text = provider.profession ?? '';
      _sessionDurationMinutes = provider.defaultSessionDurationMinutes;
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.registerShell(title: 'Perfil del Profesional');

    ref.listen<AsyncValue<void>>(profileUpdateControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (next.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: colorScheme.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado exitosamente')),
          );
        }
      }
    });

    return authState.when(
      data: (provider) {
        if (provider == null) return const SizedBox.shrink();

        _initFields(provider);

        final saveButton = ActionButton(
          onPressed: () async {
            FocusScope.of(context).unfocus();
            await ref
                .read(profileUpdateControllerProvider.notifier)
                .updateProfile(
                  name: _nameController.text,
                  profession: _professionController.text,
                  defaultSessionDurationMinutes: _sessionDurationMinutes,
                );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('Guardar Cambios'),
          ),
        );

        final formCards = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              title: 'Información Personal',
              child: Column(
                children: [
                  _EditableNameField(controller: _nameController),
                  const SizedBox(height: AppSpacing.md),
                  _EditableProfessionField(
                    controller: _professionController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Cuenta',
              child: _ReadOnlyEmailField(email: provider.email),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Preferencias de Agenda',
              child: _SessionDurationDropdown(
                value: _sessionDurationMinutes,
                onChanged: (v) =>
                    setState(() => _sessionDurationMinutes = v ?? 45),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            saveButton,
          ],
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppSpacing.breakpointSm;

            final content =
                isWide
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 240,
                          child: _ProfileAvatarHero(
                            nameController: _nameController,
                            professionController: _professionController,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(child: formCards),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileAvatarHero(
                          nameController: _nameController,
                          professionController: _professionController,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        formCards,
                      ],
                    );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: content
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// --- Atoms ---

class _ProfileAvatarHero extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController professionController;

  const _ProfileAvatarHero({
    required this.nameController,
    required this.professionController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([nameController, professionController]),
      builder: (context, _) {
        final name = nameController.text;
        final profession = professionController.text.trim();
        final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (name.isNotEmpty)
              Text(
                name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            if (profession.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                profession,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyEmailField extends StatelessWidget {
  final String email;

  const _ReadOnlyEmailField({required this.email});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: email,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Correo Electrónico',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        prefixIcon: const Icon(Icons.email_outlined),
        suffixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _EditableNameField extends StatelessWidget {
  final TextEditingController controller;

  const _EditableNameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Nombre y Apellido',
        border: OutlineInputBorder(),
        hintText: 'Ej. Dr. Juan Pérez',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
    );
  }
}

class _EditableProfessionField extends StatelessWidget {
  final TextEditingController controller;

  const _EditableProfessionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Profesión / Especialidad',
        border: OutlineInputBorder(),
        hintText: 'Ej. Psicólogo/a, Kinesiólogo/a',
        prefixIcon: Icon(Icons.badge_outlined),
        helperText: 'Se usa en las notificaciones de WhatsApp',
      ),
    );
  }
}

class _SessionDurationDropdown extends StatelessWidget {
  const _SessionDurationDropdown({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int?> onChanged;

  static const _options = [15, 30, 45, 50, 60, 75, 90, 120];

  String _fmt(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Duración estándar de sesión',
        prefixIcon: Icon(Icons.timer_outlined),
        border: OutlineInputBorder(),
      ),
      items: _options
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(_fmt(m)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
