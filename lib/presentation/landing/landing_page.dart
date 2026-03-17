import 'package:flutter/material.dart';
import 'package:cobrador/presentation/landing/widgets/landing_navbar.dart';
import 'package:cobrador/presentation/landing/widgets/hero_section.dart';
import 'package:cobrador/presentation/landing/widgets/problem_section.dart';
import 'package:cobrador/presentation/landing/widgets/features_section.dart';
import 'package:cobrador/presentation/landing/widgets/how_it_works_section.dart';
import 'package:cobrador/presentation/landing/widgets/cta_section.dart';
import 'package:cobrador/presentation/landing/widgets/pricing_section.dart';
import 'package:cobrador/presentation/landing/widgets/landing_footer.dart';

/// Landing page — the public entry point for both patients and professionals.
///
/// Composed of independently-built sections in a scrollable layout.
/// Uses [LayoutBuilder] in child widgets for responsive breakpoints.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          LandingNavbar(),
          HeroSection(),
          ProblemSection(),
          FeaturesSection(),
          HowItWorksSection(),
          PricingSection(),
          CtaSection(),
          LandingFooter(),
        ],
      ),
    );
  }
}
