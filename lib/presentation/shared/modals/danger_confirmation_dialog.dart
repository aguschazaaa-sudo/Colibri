import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

class DangerConfirmationDialog extends StatefulWidget {
  final String title;
  final String warningText;
  final String confirmationWord;
  final String confirmButtonText;

  const DangerConfirmationDialog({
    super.key,
    required this.title,
    required this.warningText,
    required this.confirmationWord,
    required this.confirmButtonText,
  });

  @override
  State<DangerConfirmationDialog> createState() =>
      _DangerConfirmationDialogState();
}

class _DangerConfirmationDialogState extends State<DangerConfirmationDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    setState(() {
      _canConfirm =
          value.trim().toLowerCase() ==
          widget.confirmationWord.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.warningText),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Para confirmar, escribe: "${widget.confirmationWord}"',
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            onChanged: _onTextChanged,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escribe aquí...',
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.error, width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ActionButton(
          onPressed:
              _canConfirm ? () async => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            disabledBackgroundColor: colorScheme.error.withOpacity(0.3),
            disabledForegroundColor: colorScheme.onError.withOpacity(0.5),
          ),
          child: Text(widget.confirmButtonText),
        ),
      ],
    );
  }
}
