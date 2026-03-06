import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cobrador/router/app_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for animation to finish + a bit more
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      // Mark splash as shown
      ref.read(splashShownProvider.notifier).state = true;
      // Navigate to root and let the router's redirect logic decide where to go
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.tertiaryContainer,
      body: Center(
        child: Hero(
          tag: 'app_logo',
          child: SvgPicture.asset('assets/images/COLIBRI.svg', width: 180)
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                delay: 200.ms,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
        ),
      ),
    );
  }
}
