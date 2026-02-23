import 'package:flutter/material.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directorio de Pacientes')),
      body: const Center(
        child: Text(
          'Funcionalidad de Pacientes en construcción. \n\n// TODO: Implementar vista de pacientes',
        ),
      ),
    );
  }
}
