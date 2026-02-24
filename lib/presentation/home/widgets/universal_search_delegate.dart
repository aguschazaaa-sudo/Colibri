import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class UniversalSearchDelegate extends SearchDelegate<Patient?> {
  final WidgetRef ref;

  UniversalSearchDelegate(this.ref)
    : super(
        searchFieldLabel: 'Buscar por nombre, tel o email',
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
      );

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    final patientsAsync = ref.watch(patientsProvider(providerId));

    return patientsAsync.when(
      data: (patients) {
        final filteredPatients =
            patients.where((p) {
              final q = query.toLowerCase();
              final matchesName = p.name.toLowerCase().contains(q);
              final matchesPhone = p.phoneNumber.toLowerCase().contains(q);
              final matchesEmail =
                  p.email != null && p.email!.toLowerCase().contains(q);
              return matchesName || matchesPhone || matchesEmail;
            }).toList();

        if (filteredPatients.isEmpty) {
          return const Center(
            child: Text('No se encontraron pacientes para tu búsqueda.'),
          );
        }

        final currencyFormat = NumberFormat.currency(
          locale: 'es_AR',
          symbol: '\$',
          decimalDigits: 0,
        );

        return ListView.builder(
          itemCount: filteredPatients.length,
          itemBuilder: (context, index) {
            final patient = filteredPatients[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(patient.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(patient.name),
              subtitle: Text(patient.phoneNumber),
              trailing: Text(
                currencyFormat.format(patient.totalDebt),
                style: TextStyle(
                  color: patient.totalDebt > 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                close(context, patient);
                context.push('/patients/${patient.id}', extra: patient);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  }
}
