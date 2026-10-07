import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ribbon_fold_painter.dart';

/// Modal dialog for modifying pilgrim safe radius threshold.
/// Designed to precisely match the visual language of [CreateRoomDialog],
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
    final isDarkDialog = AppColors.isDark(context);
    final dialogBg = isDarkDialog
        ? AppColors.darkSurface
        : AppColors.surfaceWhite;
    final headingClr = isDarkDialog
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyClr = isDarkDialog ? AppColors.darkTextBody : AppColors.textBody;

    final currentVal = int.tryParse(_radiusCtrl.text.trim());

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── 1. Main Card Body ─────────────────────────────────────────
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
                border: Border.all(
                  color: isDarkDialog
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1,
                ),
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
                    // Title
                    Text(
                      context.tr('dashboard.safeRadiusTitle'),
                      style: AppTypography.titleMedium.copyWith(
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
                      style: AppTypography.bodySmall.copyWith(
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
                              color: isDarkDialog
                                  ? Colors.white38
                                  : const Color(0xFF9E8E81),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            suffixText: context.tr('dashboard.meterUnit'),
                            suffixStyle: TextStyle(
                              color: isDarkDialog
                                  ? AppColors.goldLight
                                  : AppColors.espressoDark.withValues(
                                      alpha: 0.75,
                                    ),
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
                                color: isDarkDialog
                                    ? AppColors.darkOutlineVariant
                                    : const Color(0xFFD4C7BC),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkDialog
                                    ? AppColors.darkOutlineVariant
                                    : const Color(0xFFD4C7BC),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkDialog
                                    ? AppColors.goldLight
                                    : AppColors.espressoDark,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.sosEmergency,
                                width: 1.4,
                              ),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.sosEmergency,
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
                            style: const TextStyle(
                              color: AppColors.sosEmergency,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick suggestion chips (Presets)
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
                                      ? (isDarkDialog
                                            ? AppColors.goldLight.withValues(
                                                alpha: 0.25,
                                              )
                                            : AppColors.espressoDark)
                                      : (isDarkDialog
                                            ? AppColors.goldLight.withValues(
                                                alpha: 0.1,
                                              )
                                            : const Color(0xFFF7F2EB)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDarkDialog
                                              ? AppColors.goldLight
                                              : AppColors.espressoDark)
                                        : (isDarkDialog
                                              ? AppColors.goldLight.withValues(
                                                  alpha: 0.25,
                                                )
                                              : AppColors.goldLight.withValues(
                                                  alpha: 0.45,
                                                )),
                                    width: isSelected ? 1.2 : 0.8,
                                  ),
                                ),
                                child: Text(
                                  '$preset m',
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isDarkDialog
                                              ? AppColors.goldLight
                                              : Colors.white)
                                        : (isDarkDialog
                                              ? AppColors.goldLight
                                              : AppColors.espressoDark),
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
                            foregroundColor: isDarkDialog
                                ? Colors.white60
                                : const Color(0xFF8C7A6B),
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

            // ── 2. Floating Hero Card (Compact header) ───────────────────
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              height: 86,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkDialog
                        ? [const Color(0xFF38251A), const Color(0xFF1F140D)]
                        : [AppColors.espressoDark, const Color(0xFF563B2A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Ambient Background Circular Glows
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -15,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Center Hero Graphic
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldPrimary.withValues(alpha: 0.25),
                                  AppColors.goldPrimary.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.track_changes_rounded,
                                color: AppColors.accentGoldStar,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'SAFE RADIUS',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Protruding Ribbon Submit Button ─────────────────────────
            Positioned(
              bottom: 0,
              right: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ribbon fold triangle at the top-right corner
                  Positioned(
                    top: -10,
                    right: 0,
                    child: CustomPaint(
                      size: const Size(10, 10),
                      painter: RibbonFoldPainter(
                        color: isDarkDialog
                            ? const Color(0xFF140D08)
                            : const Color(0xFF160D07),
                      ),
                    ),
                  ),

                  // Main Pill Submit Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSubmitting ? null : _submit,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(5),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isDarkDialog
                              ? AppColors.darkPrimaryContainer
                              : AppColors.espressoDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 13.5,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SIMPAN RADIUS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.8,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
