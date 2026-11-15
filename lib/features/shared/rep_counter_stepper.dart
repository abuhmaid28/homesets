import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';

/// Large, tactile rep counter stepper with Direction A tabular figures.
class RepCounterStepper extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const RepCounterStepper({
    super.key,
    required this.count,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: HomesetsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomesetsColors.borderSubtle, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove,
            onPressed: count > min ? () => onChanged(count - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$count',
              style: HomesetsTypography.displayRepCount,
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onPressed: count < max ? () => onChanged(count + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Material(
      color: isEnabled ? HomesetsColors.surfaceHighlight : HomesetsColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: HomesetsColors.borderSubtle, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            size: 28,
            color: isEnabled ? HomesetsColors.lime : HomesetsColors.textMuted,
          ),
        ),
      ),
    );
  }
}
