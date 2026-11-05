import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _PageState { idle, loading, success, error }

class ReportarErrorPage extends StatefulWidget {
  const ReportarErrorPage({super.key});

  @override
  State<ReportarErrorPage> createState() => _ReportarErrorPageState();
}

class _ReportarErrorPageState extends State<ReportarErrorPage> {
  _PageState _state = _PageState.idle;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _professionalController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _professionalController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _state = _PageState.loading);

    try {
      await FirebaseFirestore.instance.collection('error_reports').add({
        'phone': _phoneController.text.trim(),
        'professionalName': _professionalController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      });
      if (mounted) setState(() => _state = _PageState.success);
    } catch (_) {
      debugPrint('Error submitting report');
      if (mounted) setState(() => _state = _PageState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reportar un error',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.sectionPadding(context),
              child: AppSpacing.constrained(
                child: _state == _PageState.success
                    ? _SuccessPanel(onBack: () => context.go('/'))
                    : _ReportForm(
                        formKey: _formKey,
                        phoneController: _phoneController,
                        professionalController: _professionalController,
                        descriptionController: _descriptionController,
                        pageState: _state,
                        onSubmit: _submit,
                        onRetry: () => setState(() => _state = _PageState.idle),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _FooterText(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ─── Form ────────────────────────────────────────────────────────────────────

class _ReportForm extends StatelessWidget {
  const _ReportForm({
    required this.formKey,
    required this.phoneController,
    required this.professionalController,
    required this.descriptionController,
    required this.pageState,
    required this.onSubmit,
    required this.onRetry,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController professionalController;
  final TextEditingController descriptionController;
  final _PageState pageState;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isLoading = pageState == _PageState.loading;
    final hasError = pageState == _PageState.error;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recibiste un mensaje por error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Completá el formulario y nos encargaremos de revisarlo.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (hasError) ...[
            _ErrorBanner(onRetry: onRetry),
            const SizedBox(height: AppSpacing.lg),
          ],
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Tu número de teléfono *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Este campo es requerido'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: professionalController,
            decoration: const InputDecoration(
              labelText: 'Nombre del profesional mencionado (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción del problema (opcional)',
              helperText: '¿Qué decía el mensaje? ¿Qué está mal?',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar reporte'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success panel ────────────────────────────────────────────────────────────

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Icon(
          Icons.check_circle_outline,
          size: AppSpacing.xxxl,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '¡Reporte enviado!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Gracias por avisarnos. Revisaremos el problema y contactaremos al profesional correspondiente.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton(
          onPressed: onBack,
          child: const Text('Volver al inicio'),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Hubo un error al enviar. Por favor, intenta nuevamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _FooterText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Colibrí — Sistema de gestión para profesionales de salud',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
}
