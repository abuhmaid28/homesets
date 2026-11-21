import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/homesets_colors.dart';
import '../../../core/theme/homesets_typography.dart';
import '../../../domain/models/domain_models.dart';
import '../../../domain/progress/progress_analytics.dart';
import '../../../l10n/app_localizations.dart';

/// Modal dialog for logging or editing body weight with strict [30.0, 300.0] kg validation (WP03, WP09, P5-R06).
class LogWeightDialog extends StatefulWidget {
  final double? initialWeight;
  final WeightEntry? entryToEdit;
  final ValueChanged<double>? onSave;
  final Future<void> Function(double weightKg)? onSaveAsync;

  const LogWeightDialog({
    super.key,
    this.initialWeight,
    this.entryToEdit,
    this.onSave,
    this.onSaveAsync,
  }) : assert(onSave != null || onSaveAsync != null, 'Must provide onSave or onSaveAsync');

  @override
  State<LogWeightDialog> createState() => _LogWeightDialogState();
}

class _LogWeightDialogState extends State<LogWeightDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.entryToEdit?.weightKg ?? widget.initialWeight;
    _controller = TextEditingController(
      text: prefill != null ? prefill.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final text = _controller.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(text);

    if (parsed == null || !ProgressAnalytics.isValidWeightKg(parsed)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.weightBoundsError;
      });
      return;
    }

    if (widget.onSaveAsync != null) {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });
      try {
        await widget.onSaveAsync!(parsed);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = AppLocalizations.of(context)!.saveFailed;
          });
        }
      }
    } else if (widget.onSave != null) {
      widget.onSave!(parsed);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.entryToEdit != null;

    return AlertDialog(
      backgroundColor: HomesetsColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: HomesetsColors.borderSubtle),
      ),
      title: Text(
        isEditing ? l10n.editWeight : l10n.logWeight,
        style: HomesetsTypography.heading2,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enterWeightKg,
              style: HomesetsTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
              ],
              autofocus: true,
              style: const TextStyle(
                color: HomesetsColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: HomesetsColors.surfaceElevated,
                hintText: '75.0',
                hintStyle: const TextStyle(color: HomesetsColors.textMuted),
                suffixText: 'kg',
                suffixStyle: const TextStyle(
                  color: HomesetsColors.lime,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: HomesetsColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: HomesetsColors.lime, width: 2),
                ),
                errorText: _errorMessage,
                errorMaxLines: 2,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: HomesetsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: HomesetsColors.lime,
            foregroundColor: HomesetsColors.textOnLime,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: HomesetsColors.textOnLime),
                )
              : Text(
                  l10n.saveWeight,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
