import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:cobrador/providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;

  bool _canNavigate = false;
  bool _navigatePending = false;
  int _cyclesCompleted = 0;
  static const int _minCycles = 2;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this);

    _lottieController.addStatusListener(_onAnimationStatusChanged);

    // Safety timeout: if auth never resolves, navigate anyway after 10 seconds.
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_navigatePending) {
        _canNavigate = true;
        _triggerNavigation();
      }
    });

    // Check if auth is already resolved on the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = ref.read(authStateProvider);
      if (!authState.isLoading) {
        setState(() => _canNavigate = true);
      }
    });
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    _cyclesCompleted++;

    if (_canNavigate && _cyclesCompleted >= _minCycles) {
      _triggerNavigation();
    } else {
      _lottieController.forward(from: 0);
    }
  }

  void _triggerNavigation() {
    if (_navigatePending || !mounted) return;
    _navigatePending = true;

    ref.read(splashShownProvider.notifier).state = true;
    final destination = ref.read(preSplashDestinationProvider);
    ref.read(preSplashDestinationProvider.notifier).state = null;
    context.go(destination ?? '/');
  }

  @override
  void dispose() {
    _lottieController.removeStatusListener(_onAnimationStatusChanged);
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for future auth state changes after the first frame.
    ref.listen(authStateProvider, (_, next) {
      if (!next.isLoading && !_canNavigate) {
        setState(() => _canNavigate = true);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.tertiaryContainer,
      body: Center(
        child: Lottie.asset(
          'assets/lotties/logoAnimado.json',
          controller: _lottieController,
          width: 240,
          onLoaded: (composition) {
            _lottieController.duration = composition.duration;
            _lottieController.forward();
          },
        ),
      ),
    );
  }
}
