import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';

enum KineticButtonStyle {
  primary,
  secondary,
  danger,
  outline,
}

/// Tactile Kinetic Button with rounded ergonomics and clear visual hierarchy.
class KineticButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KineticButtonStyle style;
  final IconData? icon;
  final bool isExpanded;
  final bool isLoading;

  const KineticButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = KineticButtonStyle.primary,
    this.icon,
    this.isExpanded = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (style) {
      case KineticButtonStyle.primary:
        bg = HomesetsColors.lime;
        fg = HomesetsColors.textOnLime;
        border = Colors.transparent;
        break;
      case KineticButtonStyle.secondary:
        bg = HomesetsColors.surfaceElevated;
        fg = HomesetsColors.textPrimary;
        border = HomesetsColors.borderSubtle;
        break;
      case KineticButtonStyle.danger:
        bg = HomesetsColors.orange;
        fg = Colors.white;
        border = Colors.transparent;
        break;
      case KineticButtonStyle.outline:
        bg = Colors.transparent;
        fg = HomesetsColors.textPrimary;
        border = HomesetsColors.borderSubtle;
        break;
    }

    final content = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: HomesetsTypography.buttonText.copyWith(color: fg),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: 54,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: border == Colors.transparent ? 0 : 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
