import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable widget to display the app logo in authentication pages.
class AuthLogo extends StatelessWidget {
  /// The height of the logo. Default is 64.
  final double size;

  const AuthLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/COLIBRI.svg',
      height: size,
      // We use the original colors of the SVG as it's the brand logo
    );
  }
}
