import 'package:flutter/material.dart';
import 'package:cobrador/presentation/shared/modals/home_actions_sheet.dart';

class HomeActionFab extends StatelessWidget {
  const HomeActionFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          builder: (context) => const HomeActionsSheet(),
        );
      },
      tooltip: 'Acciones rápidas',
      child: const Icon(Icons.add_rounded),
    );
  }
}
