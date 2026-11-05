import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State that the AppShell renders (title, actions, FAB, optional endDrawer).
@immutable
class ShellState {
  final String title;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  /// Optional end drawer registered by the active page.
  /// On mobile, [AppShell] passes this to [Scaffold.endDrawer].
  final Widget? endDrawer;

  const ShellState({
    this.title = '',
    this.actions = const [],
    this.floatingActionButton,
    this.endDrawer,
  });

  ShellState copyWith({
    String? title,
    List<Widget>? actions,
    Widget? floatingActionButton,
    bool clearFab = false,
    Widget? endDrawer,
    bool clearEndDrawer = false,
  }) {
    return ShellState(
      title: title ?? this.title,
      actions: actions ?? this.actions,
      floatingActionButton:
          clearFab ? null : (floatingActionButton ?? this.floatingActionButton),
      endDrawer:
          clearEndDrawer ? null : (endDrawer ?? this.endDrawer),
    );
  }
}

class ShellStateNotifier extends StateNotifier<ShellState> {
  ShellStateNotifier() : super(const ShellState());

  void setPage({
    required String title,
    List<Widget> actions = const [],
    Widget? floatingActionButton,
    Widget? endDrawer,
  }) {
    state = ShellState(
      title: title,
      actions: actions,
      floatingActionButton: floatingActionButton,
      endDrawer: endDrawer,
    );
  }
}

final shellStateProvider =
    StateNotifierProvider<ShellStateNotifier, ShellState>(
      (ref) => ShellStateNotifier(),
    );
