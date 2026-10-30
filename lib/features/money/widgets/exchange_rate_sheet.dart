import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../services/currency_rate_service.dart';
import '../services/money_currency_helper.dart';

/// Opens the SAR -> IDR exchange-rate sheet.
///
/// Resolves with the manual rate the user confirmed, or `null` when the sheet
/// was dismissed. Online refreshes are applied directly by
/// [CurrencyRateService] and propagate through `rateNotifier`.
Future<double?> showExchangeRateSheet(
  BuildContext context, {
  required double initialRate,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExchangeRateSheet(initialRate: initialRate),
  );
}

class ExchangeRateSheet extends StatefulWidget {
  final double initialRate;

  const ExchangeRateSheet({super.key, required this.initialRate});

  @override
  State<ExchangeRateSheet> createState() => _ExchangeRateSheetState();
}

class _ExchangeRateSheetState extends State<ExchangeRateSheet> {
  static const List<double> _presets = [4500, 4600, 4700, 4750, 4800];

  late final TextEditingController _rateController;
  final FocusNode _rateFocus = FocusNode();
  bool _isCheckingOnline = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.initialRate.round().toString(),
    );
  }

  @override
  void dispose() {
    // Disposed only after the route has fully unmounted this subtree, so the
    // TextField can never touch a disposed controller during the exit animation.
    _rateController.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  double? get _parsedRate => double.tryParse(
    _rateController.text.replaceAll(RegExp(r'[^0-9]'), ''),
  );

  void _selectPreset(double preset) {
    setState(() {
      _rateController.text = preset.round().toString();
      _errorText = null;
    });
  }

  Future<void> _fetchOnline() async {
    final rateUpdatedTitle = context.tr('money.rateUpdatedTitle');
    final cannotConnectTitle = context.tr('money.cannotConnectTitle');
    final cannotConnectMsg = context.tr('money.cannotConnectMsg');

    setState(() => _isCheckingOnline = true);
    final success = await CurrencyRateService.instance.fetchLatestOnlineRate();
    if (!mounted) return;

    final latest = CurrencyRateService.instance.currentRate;
    setState(() {
      _isCheckingOnline = false;
      if (success) {
        _rateController.text = latest.round().toString();
        _errorText = null;
      }
    });

    Get.snackbar(
      success ? rateUpdatedTitle : cannotConnectTitle,
      success
          ? '1 SAR = ${CurrencyFormatter.formatRupiah(latest)}'
          : cannotConnectMsg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.hc.surfaceSand,
      colorText: context.hc.textPrimary,
      margin: const EdgeInsets.all(AppSpacing.md),
    );
  }

  void _apply() {
    final value = _parsedRate;
    if (!CurrencyRateService.isValidManualRate(value)) {
      setState(() => _errorText = context.tr('money.invalidRateMsg'));
      return;
    }
    // Close the keyboard first so the route pops without a pending
    // MediaQuery/viewInsets rebuild racing the exit animation.
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final apiUtc = CurrencyRateService.instance.lastApiUtcTime;
    final currentVal = _parsedRate;

    final presets = <double>{
      CurrencyRateService.instance.currentRate.roundToDouble(),
      ..._presets,
    }.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          color: hc.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            side: BorderSide(color: hc.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdgeGutter,
              AppSpacing.md,
              AppSpacing.screenEdgeGutter,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: hc.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildHeader(hc, apiUtc),
                const SizedBox(height: AppSpacing.lg),

                // Quick presets
                Text(
                  context.tr('money.quickPresets'),
                  style: AppTypography.labelMedium.copyWith(
                    color: hc.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final preset in presets)
                      _buildPresetChip(hc, preset, currentVal == preset),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Manual input
                Text(
                  context.tr('money.manualRateLabel'),
                  style: AppTypography.labelMedium.copyWith(
                    color: hc.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildRateField(hc),
                const SizedBox(height: AppSpacing.md),

                // Fetch online
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hc.accentText,
                    side: BorderSide(color: hc.accent),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: _isCheckingOnline ? null : _fetchOnline,
                  icon: _isCheckingOnline
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: hc.accent,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded, size: 20),
                  label: Text(
                    _isCheckingOnline
                        ? context.tr('money.fetchingOnline')
                        : context.tr('money.fetchOnline'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: hc.accentText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Apply
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: hc.primary,
                    foregroundColor: hc.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: _isCheckingOnline ? null : _apply,
                  child: Text(
                    context.tr('money.applyRate'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: hc.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(HajiColors hc, String? apiUtc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: hc.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.currency_exchange_rounded,
            color: hc.accentText,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('money.rateSettingsTitle'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: hc.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                apiUtc != null
                    ? 'Live API: $apiUtc'
                    : 'SAR ↔ IDR ↔ USD (Dynamic FX)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  color: hc.textTertiary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: Icon(Icons.close_rounded, color: hc.textSecondary),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildPresetChip(HajiColors hc, double preset, bool isSelected) {
    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        CurrencyFormatter.formatRupiah(preset),
        style: TextStyle(
          color: isSelected ? hc.onPrimary : hc.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: hc.primary,
      backgroundColor: hc.surfaceSubtle,
      side: BorderSide(color: isSelected ? hc.primary : hc.border),
      onSelected: (selected) {
        if (selected) _selectPreset(preset);
      },
    );
  }

  Widget _buildRateField(HajiColors hc) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: _rateController,
      focusNode: _rateFocus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      onChanged: (_) => setState(() => _errorText = null),
      onSubmitted: (_) => _apply(),
      cursorColor: hc.accent,
      style: AppTypography.titleLarge.copyWith(
        color: hc.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixText: 'Rp  ',
        prefixStyle: AppTypography.titleLarge.copyWith(
          color: hc.accentText,
          fontWeight: FontWeight.w800,
        ),
        hintText: '4750',
        hintStyle: TextStyle(color: hc.textTertiary),
        errorText: _errorText,
        errorMaxLines: 2,
        filled: true,
        fillColor: hc.surfaceSubtle,
        border: border(hc.border),
        enabledBorder: border(hc.border),
        focusedBorder: border(hc.accent, 2),
        errorBorder: border(hc.danger),
        focusedErrorBorder: border(hc.danger, 2),
      ),
    );
  }
}
