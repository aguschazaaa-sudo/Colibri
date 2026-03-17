import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State that the AppShell renders (title, actions, FAB).
@immutable
class ShellState {
  final String title;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  const ShellState({
    this.title = '',
    this.actions = const [],
    this.floatingActionButton,
  });

  ShellState copyWith({
    String? title,
    List<Widget>? actions,
    Widget? floatingActionButton,
    bool clearFab = false,
  }) {
    return ShellState(
      title: title ?? this.title,
      actions: actions ?? this.actions,
      floatingActionButton:
          clearFab ? null : (floatingActionButton ?? this.floatingActionButton),
    );
  }
}

class ShellStateNotifier extends StateNotifier<ShellState> {
  ShellStateNotifier() : super(const ShellState());

  void setPage({
    required String title,
    List<Widget> actions = const [],
    Widget? floatingActionButton,
  }) {
    state = ShellState(
      title: title,
      actions: actions,
      floatingActionButton: floatingActionButton,
    );
  }
}

final shellStateProvider =
    StateNotifierProvider<ShellStateNotifier, ShellState>(
      (ref) => ShellStateNotifier(),
    );
