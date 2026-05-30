import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppCardTone { normal, sand, dark, coral }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.tone = AppCardTone.normal,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final AppCardTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForTone(tone);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.foreground),
        child: IconTheme.merge(
          data: IconThemeData(color: colors.foreground),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: card,
      ),
    );
  }

  _CardColors _colorsForTone(AppCardTone tone) {
    return switch (tone) {
      AppCardTone.normal => const _CardColors(
        background: AppColors.card,
        foreground: AppColors.foreground,
        border: AppColors.border,
      ),
      AppCardTone.sand => const _CardColors(
        background: AppColors.sand,
        foreground: AppColors.foreground,
        border: AppColors.border,
      ),
      AppCardTone.dark => const _CardColors(
        background: AppColors.ink,
        foreground: AppColors.background,
        border: AppColors.ink,
      ),
      AppCardTone.coral => const _CardColors(
        background: AppColors.coral,
        foreground: Colors.white,
        border: AppColors.coralDark,
      ),
    };
  }
}

class _CardColors {
  const _CardColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
