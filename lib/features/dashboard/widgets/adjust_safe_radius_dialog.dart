import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/haji_dialog_hero_header.dart';
import '../../../core/widgets/haji_dialog_ribbon_button.dart';
import '../../../core/widgets/haji_transparent_dialog.dart';

/// Modal dialog for modifying pilgrim safe radius threshold.
/// Designed to precisely match the visual language of [CreateRoomDialog]
/// featuring a floating hero card header, minimalist underline input with
/// suggestion pills, and a protruding ribbon action button.
class AdjustSafeRadiusDialog extends StatefulWidget {
  const AdjustSafeRadiusDialog({super.key});

  /// Displays the [AdjustSafeRadiusDialog].
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdjustSafeRadiusDialog(),
    );
  }

  @override
  State<AdjustSafeRadiusDialog> createState() => _AdjustSafeRadiusDialogState();
}

class _AdjustSafeRadiusDialogState extends State<AdjustSafeRadiusDialog> {
  late final TextEditingController _radiusCtrl;
  String? _inputError;
  bool _isSubmitting = false;

  static const List<int> _presetRadii = [50, 100, 150, 200, 300, 500];

  @override
  void initState() {
    super.initState();
    final state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final current = state?.safeRadiusMeters.value.toInt() ?? 200;
    _radiusCtrl = TextEditingController(text: current.toString());
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final text = _radiusCtrl.text.trim();
    if (text.isEmpty) {
      setState(() {
        _inputError = context.tr('dashboard.radiusRequired');
      });
      return;
    }

    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) {
      setState(() {
        _inputError = context.tr('dashboard.radiusPositive');
      });
      return;
    }

    if (parsed > 5000) {
      setState(() {
        _inputError = context.tr('dashboard.radiusMax');
      });
      return;
    }

    setState(() {
      _inputError = null;
      _isSubmitting = true;
    });

    final state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    final success = await state?.setSafeRadius(parsed.toDouble()) ?? false;

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(success);
    }

    if (success) {
      AppAlert.success(
        context,
        title: context.tr('dashboard.safeDistanceUpdated'),
        message: context.tr('dashboard.radiusApplied', {'meters': parsed}),
      );
    } else {
      AppAlert.error(
        context,
        title: context.tr('dashboard.safeDistanceFailed'),
        message: context.tr('dashboard.saveRetry'),
        okText: context.tr('common.tryAgain'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final isDarkDialog = hc.isDark;
    final dialogBg = hc.surface;
    final headingClr = hc.textPrimary;
    final bodyClr = hc.textSecondary;

    final currentVal = int.tryParse(_radiusCtrl.text.trim());

    return HajiTransparentDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. Main Card Body
            Container(
              margin: const EdgeInsets.only(
                top: 28,
                bottom: 12,
                right: 10,
                left: 10,
              ),
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 14),
              decoration: BoxDecoration(
                color: dialogBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: hc.borderSubtle, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkDialog ? 0.45 : 0.09,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('dashboard.safeRadiusTitle'),
                      style: context.text.titleMedium.copyWith(
                        color: headingClr,
                        fontWeight: FontWeight.w800,
                        fontSize: 17.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      context.tr('dashboard.safeRadiusDesc'),
                      style: context.text.bodySmall.copyWith(
                        color: bodyClr.withValues(alpha: 0.85),
                        height: 1.35,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Minimalist Underline Text Field with Meter Suffix
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _radiusCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.done,
                          maxLength: 5,
                          onSubmitted: (_) => _submit(),
                          style: TextStyle(
                            color: headingClr,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Misal: 200',
                            hintStyle: TextStyle(
                              color: hc.textTertiary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            suffixText: context.tr('dashboard.meterUnit'),
                            suffixStyle: TextStyle(
                              color: isDarkDialog ? hc.accent : hc.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            filled: false,
                            contentPadding: const EdgeInsets.fromLTRB(
                              0,
                              6,
                              0,
                              2,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: hc.borderSubtle,
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: hc.borderSubtle,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkDialog ? hc.accent : hc.primary,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: hc.danger,
                                width: 1.4,
                              ),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: hc.danger,
                                width: 1.8,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            setState(() {
                              if (_inputError != null) _inputError = null;
                            });
                          },
                        ),
                        if (_inputError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _inputError!,
                            style: TextStyle(
                              color: hc.danger,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _presetRadii.map((preset) {
                          final isSelected = currentVal == preset;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  _radiusCtrl.text = preset.toString();
                                  _inputError = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDarkDialog ? hc.accent : hc.primary)
                                      : (isDarkDialog
                                            ? hc.surfaceSand
                                            : hc.surfaceSubtle),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDarkDialog
                                              ? hc.accent
                                              : hc.primary)
                                        : hc.borderSubtle,
                                    width: isSelected ? 1.2 : 0.8,
                                  ),
                                ),
                                child: Text(
                                  '$preset m',
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isDarkDialog
                                              ? hc.onPrimary
                                              : Colors.white)
                                        : hc.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom Row: Cancel button on left, space reserved for protruding button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: hc.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 150,
                        ), // Spacer for protruding button
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Floating Hero Card (Compact header
            const Positioned(
              top: 0,
              left: 22,
              right: 22,
              child: HajiDialogHeroHeader(
                icon: Icons.track_changes_rounded,
                title: 'SAFE RADIUS',
              ),
            ),

            // 3. Protruding Ribbon Submit Button
            Positioned(
              bottom: 0,
              right: 0,
              child: HajiDialogRibbonButton(
                label: 'SIMPAN RADIUS',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
