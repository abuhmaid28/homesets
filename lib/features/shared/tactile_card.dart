import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';

/// Tactile container card with subtle rounded micro-borders and soft elevation.
class TactileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isHighlighted;

  const TactileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        (isHighlighted ? HomesetsColors.surfaceHighlight : HomesetsColors.surfaceCard);
    final effectiveBorder = borderColor ??
        (isHighlighted ? HomesetsColors.limeDim : HomesetsColors.borderSubtle);

    final card = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: effectiveBorder, width: isHighlighted ? 1.5 : 1),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: HomesetsColors.lime.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: HomesetsColors.lime.withValues(alpha: 0.1),
          highlightColor: HomesetsColors.lime.withValues(alpha: 0.05),
          child: card,
        ),
      );
    }

    return card;
  }
}
