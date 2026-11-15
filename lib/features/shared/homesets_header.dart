import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../l10n/app_localizations.dart';

/// Neutral interim HOMESETS wordmark header (GOV18).
/// Employs clean typographic styling; strictly refrains from fabricating a logo.
class HomesetsHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final bool showTagline;

  const HomesetsHeader({
    super.key,
    this.leading,
    this.actions,
    this.showTagline = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(showTagline ? 76 : 56);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: leading != null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HOMESETS',
                style: HomesetsTypography.wordmark,
              ),
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: HomesetsColors.lime,
                ),
              ),
            ],
          ),
          if (showTagline && l10n != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.tagline,
              style: HomesetsTypography.bodySmall,
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}
