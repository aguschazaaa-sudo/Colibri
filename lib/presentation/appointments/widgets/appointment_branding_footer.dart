import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Small centered branding row shown at the bottom of the appointment detail.
class AppointmentBrandingFooter extends StatelessWidget {
  const AppointmentBrandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/COLIBRI.svg',
          height: 14,
          colorFilter: ColorFilter.mode(colorScheme.outline, BlendMode.srcIn),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Colibrí',
          style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }
}
