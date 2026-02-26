import 'package:flutter/material.dart';

class AdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget drawer;
  final Widget body;
  final Widget? floatingActionButton;
  final double breakpoint;

  const AdaptiveScaffold({
    super.key,
    this.appBar,
    required this.drawer,
    required this.body,
    this.floatingActionButton,
    this.breakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).width >= breakpoint;

    if (isLargeScreen) {
      return Scaffold(
        appBar: appBar,
        body: Row(children: [drawer, Expanded(child: body)]),
        floatingActionButton: floatingActionButton,
      );
    } else {
      return Scaffold(
        appBar: appBar,
        drawer: drawer,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }
  }
}
