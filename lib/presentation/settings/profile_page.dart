import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/presentation/providers/use_case_providers.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/domain/provider.dart' as domain;

// --- Controller ---

final profileUpdateControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfileUpdateController, void>(
      ProfileUpdateController.new,
    );

class ProfileUpdateController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateName(String newName) async {
    final currentProvider = ref.read(authStateProvider).value;
    if (currentProvider == null) return;

    state = const AsyncLoading();

    final useCase = ref.read(updateProviderProfileUseCaseProvider);
    final updatedProvider = currentProvider.copyWith(name: newName);

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
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFields(domain.Provider provider) {
    if (!_isInit) {
      _nameController.text = provider.name;
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del Profesional')),
      body: authState.when(
        data: (provider) {
          if (provider == null) return const SizedBox.shrink();

          _initFields(provider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AvatarHeader(name: provider.name),
                    const SizedBox(height: AppSpacing.xxl),
                    _ReadOnlyEmailField(email: provider.email),
                    const SizedBox(height: AppSpacing.md),
                    _EditableNameField(controller: _nameController),
                    const SizedBox(height: AppSpacing.xxl),
                    ActionButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await ref
                            .read(profileUpdateControllerProvider.notifier)
                            .updateName(_nameController.text);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                )
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// --- Atomics ---

class _AvatarHeader extends StatelessWidget {
  final String name;

  const _AvatarHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tus Datos',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
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
      decoration: const InputDecoration(
        labelText: 'Nombre y Apellido',
        border: OutlineInputBorder(),
        hintText: 'Ej. Dr. Juan Pérez',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre no puede estar vacío';
        }
        return null;
      },
    );
  }
}
