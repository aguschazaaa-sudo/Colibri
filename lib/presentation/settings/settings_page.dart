import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: const Center(
        child: Text(
          'Funcionalidad de Ajustes en construcción. \n\n// TODO: Implementar vista de ajustes',
        ),
      ),
    );
  }
}
