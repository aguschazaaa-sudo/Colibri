import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/presentation/onboarding/widgets/onboarding_card.dart';
import 'package:cobrador/presentation/providers/onboarding_providers.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  final PageController _controller = PageController();
  int _page = 0;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _pageOffset = _controller.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final pages = _buildPages(context);
    final isLast = _page == pages.length - 1;

    // Determine current background color based on scroll offset
    Color? bgColor;
    if (pages.isNotEmpty) {
      if (_pageOffset <= 0) {
        bgColor = pages.first.pageColor;
      } else if (_pageOffset >= pages.length - 1) {
        bgColor = pages.last.pageColor;
      } else {
        final lowerIndex = _pageOffset.floor();
        final upperIndex = lowerIndex + 1;
        final t = _pageOffset - lowerIndex;
        bgColor = Color.lerp(
          pages[lowerIndex].pageColor,
          pages[upperIndex].pageColor,
          t,
        );
      }
    }
    bgColor ??= Theme.of(context).colorScheme.surface;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        // Enforce max width for tablet/web
        final isWide = constraints.maxWidth > 600;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ClipRRect(
              borderRadius:
                  isWide ? BorderRadius.circular(32) : BorderRadius.zero,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  color: bgColor,
                  child: SafeArea(
                    child: Column(
                      children: [
                        _TopBar(
                          onSkip: _complete,
                          textColor:
                              Theme.of(
                                context,
                              ).colorScheme.onSurface, // Or a contrasting color
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: pages.length,
                            onPageChanged:
                                (value) => setState(() => _page = value),
                            itemBuilder: (context, index) {
                              return OnboardingPageContent(
                                title: pages[index].title,
                                body: pages[index].body,
                                graphic: pages[index].graphic,
                                badgeText: pages[index].badgeText,
                              );
                            },
                          ),
                        ),
                        _Footer(
                          page: _page,
                          total: pages.length,
                          primaryLabel: isLast ? 'Empezar' : 'Siguiente',
                          onPrimary: () => _handlePrimary(isLast),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return Material(
      color: Colors.black45, // Backdrop for tablets when capped width
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Colors.transparent),
          disableAnimations
              ? content
              : content
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
        ],
      ),
    );
  }

  List<_OnboardingPageData> _buildPages(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Page 1: Gestón centralizada - Primarios
    final p1Primary = colorScheme.primary;
    final p1Bg = colorScheme.primaryContainer.withAlpha(80);

    // Page 2: Control Financiero - Verdes/Teal (exito)
    const p2Primary = Color(0xFF00796B); // Teal custom
    final p2Bg = p2Primary.withAlpha(30);

    // Page 3: Agenda Inteligente - Púrpuras
    const p3Primary = Color(0xFF673AB7);
    final p3Bg = p3Primary.withAlpha(30);

    // Page 4: Piloto Automático - Dorados/Terciario
    final p4Primary = colorScheme.tertiary;
    final p4Bg = colorScheme.tertiaryContainer.withAlpha(80);

    return [
      _OnboardingPageData(
        title: 'Todo en un solo lugar',
        body:
            'Toca el (+) inferior para agregar tu primer paciente o agendar un turno. Desliza por los turnos de hoy para registrar pagos al instante.',
        graphic: OnboardingGraphic(
          icon: Icons.swipe_rounded,
          primaryColor: p1Primary,
          secondaryColor: colorScheme.secondary,
        ),
        pageColor: p1Bg,
        badgeText: null,
      ),
      _OnboardingPageData(
        title: 'Saldos siempre claros',
        body:
            'Cada turno suma al saldo del paciente. Al registrar un pago, se descuenta de los turnos más antiguos automáticamente.',
        graphic: OnboardingGraphic(
          icon: Icons.account_balance_wallet_rounded,
          primaryColor: p2Primary,
          secondaryColor: p2Primary.withAlpha(150),
        ),
        pageColor: p2Bg,
        badgeText: null,
      ),
      _OnboardingPageData(
        title: 'Tu tiempo vale',
        body:
            'Configura tus días no laborables y vacaciones. Los turnos recurrentes saltarán esas fechas solos, sin que tengas que reprogramar nada.',
        graphic: OnboardingGraphic(
          icon: Icons.edit_calendar_rounded,
          primaryColor: p3Primary,
          secondaryColor: p3Primary.withAlpha(150),
        ),
        pageColor: p3Bg,
        badgeText: null,
      ),
      _OnboardingPageData(
        title: 'Cobramos por vos',
        body:
            'Con el plan basico una vez al mes enviamos WhatsApps a quienes tienen saldo pendiente. Con Premium, además también recordamos los turnos un día antes para que tus pacientes nuca se olviden de asistir.',
        graphic: OnboardingGraphic(
          icon: Icons.auto_awesome_rounded,
          primaryColor: p4Primary,
          secondaryColor: colorScheme.onTertiaryContainer,
        ),
        pageColor: p4Bg,
        badgeText: 'Premium',
      ),
    ];
  }

  Future<void> _handlePrimary(bool isLast) async {
    if (isLast) {
      await _complete();
      return;
    }

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final duration = disableAnimations ? Duration.zero : 300.ms;

    await _controller.nextPage(duration: duration, curve: Curves.easeOutCubic);
  }

  Future<void> _complete() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    HapticFeedback.lightImpact();
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSkip;
  final Color textColor;

  const _TopBar({required this.onSkip, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: textColor.withAlpha(180),
          ),
          child: const Text(
            'Saltar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int page;
  final int total;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Color activeColor;

  const _Footer({
    required this.page,
    required this.total,
    required this.primaryLabel,
    required this.onPrimary,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          _Dots(page: page, total: total, activeColor: activeColor),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 56, // Slightly taller button for premium feel
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: activeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int page;
  final int total;
  final Color activeColor;

  const _Dots({
    required this.page,
    required this.total,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == page;
        return AnimatedContainer(
          duration: disableAnimations ? Duration.zero : 300.ms,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : colorScheme.onSurface.withAlpha(40),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String body;
  final Widget graphic;
  final Color pageColor;
  final String? badgeText;

  const _OnboardingPageData({
    required this.title,
    required this.body,
    required this.graphic,
    required this.pageColor,
    required this.badgeText,
  });
}
