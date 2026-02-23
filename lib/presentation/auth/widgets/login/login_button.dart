import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
                : const Text('Iniciar sesión'),
      ),
    );
  }
}
