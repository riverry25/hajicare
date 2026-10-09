import '../../../core/locales/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

/// Language option representation for Translator.
class _LanguageOption {
  final String code;
  final String name;
  final String flag;

  const _LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}

const List<_LanguageOption> _kLanguages = [
  _LanguageOption(code: 'id', name: 'Indonesia', flag: '🇮🇩'),
  _LanguageOption(code: 'ar', name: 'العربية', flag: '🇸🇦'),
  _LanguageOption(code: 'en', name: 'English', flag: '🇬🇧'),
];

/// Quick phrases commonly needed by Indonesian pilgrims in Mecca/Medina.
/// Quick phrases commonly needed by pilgrims in Mecca/Medina.
class _QuickPhrase {
  final String label;
  final String idText;
  final String enText;
  final String arText;
  final String icon;

  const _QuickPhrase({
    required this.label,
    required this.idText,
    required this.enText,
    required this.arText,
    required this.icon,
  });

  String getTextForCode(String code) {
    switch (code) {
      case 'id':
        return idText;
      case 'en':
        return enText;
      case 'ar':
        return arText;
      default:
        return idText;
    }
  }
}

List<_QuickPhrase> _getQuickPhrases(BuildContext context) => [
  _QuickPhrase(
    label: context.tr('translator.lostPhrase'),
    idText: 'Tolong, saya tersesat dan butuh bantuan',
    enText: 'Help, I am lost and need assistance',
    arText: 'من فضلك، لقد ضللت طريقي وأحتاج إلى مساعدة',
    icon: '🆘',
  ),
  _QuickPhrase(
    label: context.tr('translator.exitPhrase'),
    idText: 'Di mana pintu keluar Masjidil Haram?',
    enText: 'Where is the exit of Masjidil Haram?',
    arText: 'أين مخرج المسجد الحرام؟',
    icon: '🕋',
  ),
  _QuickPhrase(
    label: context.tr('translator.medicalPhrase'),
    idText: 'Saya merasa sakit dan butuh dokter',
    enText: 'I feel sick and need a doctor',
    arText: 'أشعر بالمرض وأحتاج إلى طبيب',
    icon: '🩺',
  ),
  _QuickPhrase(
    label: context.tr('translator.toiletPhrase'),
    idText: 'Di mana toilet dan tempat wudhu terdekat?',
    enText: 'Where is the nearest restroom and wudhu area?',
    arText: 'أين أقرب دورة مياه ومكان للوضوء؟',
    icon: '🚾',
  ),
  _QuickPhrase(
    label: context.tr('translator.zamzamPhrase'),
    idText: 'Di mana tempat minum air Zamzam?',
    enText: 'Where can I drink Zamzam water?',
    arText: 'أين مكان شرب ماء زمزم؟',
    icon: '💧',
  ),
  _QuickPhrase(
    label: context.tr('translator.pricePhrase'),
    idText: 'Berapa harga barang ini?',
    enText: 'How much is this item?',
    arText: 'بكم هذا؟',
    icon: '🏷️',
  ),
  _QuickPhrase(
    label: context.tr('translator.taxiPhrase'),
    idText: 'Tolong antar saya ke hotel ini',
    enText: 'Please take me to this hotel',
    arText: 'من فضلك خذني إلى هذا الفندق',
    icon: '🚕',
  ),
];

/// Bottom sheet modal for Penerjemah HajiCare.
class HajiCareTranslatorSheet extends StatefulWidget {
  const HajiCareTranslatorSheet({super.key});

  /// Displays the translator bottom sheet.
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = AppColors.isDark(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) => const HajiCareTranslatorSheet(),
    );
  }

  @override
  State<HajiCareTranslatorSheet> createState() =>
      _HajiCareTranslatorSheetState();
}

class _HajiCareTranslatorSheetState extends State<HajiCareTranslatorSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _inputController;
  final TranslationService _translationService = TranslationService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();

  late final AnimationController _pulseController;
  Timer? _debounceTimer;

  // Defaults: Source = Indonesia, Target = Arabic
  String _sourceCode = 'id';
  String _targetCode = 'ar';

  String _resultText = '';
  bool _isTranslating = false;
  String _statusMessage = '';
  String? _speechMessage;

  _LanguageOption get _sourceLanguage => _kLanguages.firstWhere(
    (l) => l.code == _sourceCode,
    orElse: () => _kLanguages[0],
  );

  _LanguageOption get _targetLanguage => _kLanguages.firstWhere(
    (l) => l.code == _targetCode,
    orElse: () => _kLanguages[1],
  );

  String _getBarLanguageName(String code) {
    switch (code) {
      case 'id':
        return context.tr('translator.langIndonesia');
      case 'ar':
        return 'العربية';
      case 'en':
        return context.tr('translator.langEnglish');
      default:
        return code;
    }
  }

  String _getSpeechLanguageName(String code) {
    switch (code) {
      case 'id':
        return context.tr('translator.langIndonesia');
      case 'ar':
        return context.tr('translator.langArabic');
      case 'en':
        return context.tr('translator.langEnglish');
      default:
        return code;
    }
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'id':
        return context.tr('translator.langIndonesia');
      case 'ar':
        return context.tr('translator.langArabic');
      case 'en':
        return context.tr('translator.langEnglish');
      default:
        return code;
    }
  }

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _speechService.onStatusChanged = (status, message) {
      if (!mounted) return;
      String? localizedMessage;
      if (status == SpeechStatus.idle) {
        localizedMessage = null;
      } else if (status == SpeechStatus.permissionDenied) {
        localizedMessage = context.tr('translator.speechPermissionDenied');
      } else if (status == SpeechStatus.serviceUnavailable) {
        localizedMessage = context.tr('translator.speechUnavailable');
      } else if (message.contains('tidak terdeteksi') ||
          message.contains('no_match')) {
        localizedMessage = context.tr('translator.speechNoMatch');
      } else if (status == SpeechStatus.done) {
        localizedMessage = null;
      } else {
        localizedMessage = message;
      }

      setState(() {
        _speechMessage = localizedMessage;
      });
      if (status == SpeechStatus.done &&
          _inputController.text.trim().isNotEmpty) {
        _performTranslation();
      }
    };

    _speechService.onResult = (recognizedWords, isFinal) {
      if (!mounted) return;
      setState(() {
        _inputController.text = recognizedWords;
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: recognizedWords.length),
        );
      });
      if (isFinal && recognizedWords.trim().isNotEmpty) {
        _performTranslation();
      }
    };

    _ttsService.onStateChanged = (_) {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pulseController.dispose();
    _inputController.dispose();
    _translationService.dispose();
    _speechService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _resultText = '';
        _isTranslating = false;
        _statusMessage = '';
      });
      return;
    }

    setState(() {});

    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performTranslation();
    });
  }

  Future<void> _performTranslation() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _statusMessage = context.tr('translator.translating');
    });

    try {
      final source = TranslationService.languageFromCode(_sourceCode);
      final target = TranslationService.languageFromCode(_targetCode);

      final translated = await _translationService.translate(
        text: text,
        source: source,
        target: target,
        onStatusUpdate: (status) {
          if (!mounted) return;
          String localizedStatus = status;
          if (status.contains('Menyiapkan bahasa sumber')) {
            localizedStatus = context.tr('translator.preparingSourceModel');
          } else if (status.contains('Menyiapkan bahasa tujuan')) {
            localizedStatus = context.tr('translator.preparingTargetModel');
          } else if (status.contains('Bahasa belum siap') ||
              status.contains('Bahasa belum dapat disiapkan')) {
            localizedStatus = context.tr('translator.modelDownloadFailed');
          }
          setState(() => _statusMessage = localizedStatus);
        },
      );

      if (mounted) {
        setState(() {
          _resultText = translated;
          _isTranslating = false;
          _statusMessage = '';
        });
      }
    } catch (e) {
      debugPrint('[HajiCareTranslator] translation error: $e');
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _statusMessage = context.tr('translator.translationError');
        });
      }
    }
  }

  void _swapLanguages() {
    HapticFeedback.lightImpact();
    setState(() {
      final tempCode = _sourceCode;
      _sourceCode = _targetCode;
      _targetCode = tempCode;

      final tempText = _inputController.text;
      _inputController.text = _resultText;
      _resultText = tempText;
    });

    if (_inputController.text.trim().isNotEmpty) {
      _performTranslation();
    }
  }

  void _toggleListening() {
    HapticFeedback.lightImpact();
    _speechService.toggleListening(languageCode: _sourceCode);
  }

  void _speakResult() {
    if (_resultText.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _ttsService.speak(text: _resultText, languageCode: _targetCode);
  }

  void _copyResult() {
    if (_resultText.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _resultText.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('translator.copiedReady')),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  void _clearInput() {
    HapticFeedback.lightImpact();
    _debounceTimer?.cancel();
    setState(() {
      _inputController.clear();
      _resultText = '';
      _isTranslating = false;
      _statusMessage = '';
    });
  }

  void _applyQuickPhrase(_QuickPhrase phrase) {
    HapticFeedback.selectionClick();
    final sourceText = phrase.getTextForCode(_sourceCode);
    final targetText = phrase.getTextForCode(_targetCode);

    if (sourceText.isNotEmpty &&
        targetText.isNotEmpty &&
        sourceText != targetText) {
      setState(() {
        _inputController.text = sourceText;
        _resultText = targetText;
        _isTranslating = false;
        _statusMessage = '';
      });
      return;
    }

    setState(() {
      _inputController.text = sourceText;
    });

    _performTranslation();
  }

  void _selectLanguage({
    required bool isSource,
    required _LanguageOption option,
  }) {
    HapticFeedback.selectionClick();
    setState(() {
      if (isSource) {
        if (_targetCode == option.code) {
          _targetCode = _sourceCode;
        }
        _sourceCode = option.code;
      } else {
        if (_sourceCode == option.code) {
          _sourceCode = _targetCode;
        }
        _targetCode = option.code;
      }
    });

    if (_inputController.text.trim().isNotEmpty) {
      _performTranslation();
    }
  }

  void _showLanguageSelector({required bool isSource}) {
    HapticFeedback.lightImpact();
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final selectedCode = isSource ? _sourceCode : _targetCode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdgeGutter,
                  ),
                  child: Text(
                    isSource
                        ? context.tr('translator.selectSourceLang')
                        : context.tr('translator.selectTargetLang'),
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._kLanguages.map((lang) {
                  final isSelected = lang.code == selectedCode;
                  return ListTile(
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      _getLanguageDisplayName(lang.code),
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.espressoDark)
                            : headingColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.espressoDark,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _selectLanguage(isSource: isSource, option: lang);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.espressoDark;
    final isListening = _speechService.isListening;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenEdgeGutter,
          right: AppSpacing.screenEdgeGutter,
          top: AppSpacing.sm,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Drag Handle ───────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              // ── Header Bar ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('translator.title'),
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.tr('translator.subtitle'),
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: bodyColor),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: context.tr('common.close'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Unified Top Language Switcher Bar ─────────────────────────
              _buildTopLanguageBar(isDark, primaryColor, headingColor),
              const SizedBox(height: AppSpacing.md),

              // ── Source Input Card ─────────────────────────────────────────
              _buildInputCard(
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
                primaryColor: primaryColor,
                isListening: isListening,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Hero Central Microphone Voice Action (Large & Adaptive) ──
              _buildCenterMicHeroSection(
                context: context,
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
                primaryColor: primaryColor,
                isListening: isListening,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Target Output Card ────────────────────────────────────────
              _buildOutputCard(
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Quick Pilgrimage Phrases ──────────────────────────────────
              _buildQuickPhrasesSection(
                isDark,
                headingColor,
                bodyColor,
                primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern unified language bar: [ Source Flag + Name ] [ ⇄ ] [ Target Flag + Name ]
  Widget _buildTopLanguageBar(
    bool isDark,
    Color primaryColor,
    Color headingColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.espressoDark.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Source Language Button
          Expanded(
            child: InkWell(
              onTap: () => _showLanguageSelector(isSource: true),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs + 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _sourceLanguage.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        _getBarLanguageName(_sourceLanguage.code),
                        style: AppTypography.labelLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: headingColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center Swap Icon Button
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _swapLanguages,
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkSurfaceContainerHighest
                      : AppColors.surfaceWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.06,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // Target Language Button
          Expanded(
            child: InkWell(
              onTap: () => _showLanguageSelector(isSource: false),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs + 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _targetLanguage.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        _getBarLanguageName(_targetLanguage.code),
                        style: AppTypography.labelLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: headingColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
    required Color primaryColor,
    required bool isListening,
  }) {
    final hasInput = _inputController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isListening
              ? AppColors.sosEmergency
              : (isDark
                    ? AppColors.darkOutlineVariant
                    : AppColors.espressoDark.withValues(alpha: 0.10)),
          width: isListening ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardInnerGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _inputController,
            maxLines: 4,
            minLines: 2,
            style: AppTypography.bodyLarge.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: context.tr('translator.typeOrMicPrompt'),
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: bodyColor.withValues(alpha: 0.45),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onInputChanged,
            onSubmitted: (_) => _performTranslation(),
          ),
          if (hasInput) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: _clearInput,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear_rounded,
                            size: 16,
                            color: bodyColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              context.tr('translator.clear'),
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _performTranslation();
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              context.tr('translator.translateAction'),
                              style: AppTypography.captionSmall.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Prominent, tactile, and adaptive center microphone hero section.
  /// Designed without box shadow for a crisp, clean, and modern appearance.
  Widget _buildCenterMicHeroSection({
    required BuildContext context,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
    required Color primaryColor,
    required bool isListening,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated Pulse & Hero Central Microphone Button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = _pulseController.value;
              final ringSize = isListening ? 88.0 + (pulseValue * 14.0) : 80.0;
              final ringColor = isListening
                  ? AppColors.sosEmergency.withValues(
                      alpha: 0.15 + (pulseValue * 0.20),
                    )
                  : (isDark
                        ? AppColors.goldPrimary.withValues(alpha: 0.15)
                        : AppColors.canvasCream);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow / Wave Ripple
                  Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringColor,
                    ),
                  ),

                  // Secondary Ripple Ring (when recording)
                  if (isListening)
                    Container(
                      width: ringSize - 14,
                      height: ringSize - 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sosEmergency.withValues(
                          alpha: 0.22 + (pulseValue * 0.20),
                        ),
                      ),
                    ),

                  // Tactile Hero Circle Button (Large 70x70, NO box shadow)
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _toggleListening,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isListening
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFE53935),
                                    Color(0xFFC62828),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.accentGoldStar,
                                          AppColors.goldPrimary,
                                        ]
                                      : [
                                          AppColors.espressoDark,
                                          AppColors.primaryContainer,
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.mic_rounded,
                            color: isListening
                                ? Colors.white
                                : (isDark
                                      ? AppColors.espressoDark
                                      : Colors.white),
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Primary Title Label
          Text(
            isListening
                ? context.tr('translator.listeningPrompt')
                : context.tr('translator.speakInLanguage', {
                    'lang': _getSpeechLanguageName(_sourceLanguage.code),
                  }),
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: isListening ? AppColors.sosEmergency : headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),

          // Helper Subtitle
          Text(
            isListening
                ? context.tr('translator.tapToStopListening')
                : context.tr('translator.tapToStartListening'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isListening
                  ? AppColors.sosEmergency.withValues(alpha: 0.85)
                  : bodyColor.withValues(alpha: 0.70),
              fontWeight: FontWeight.w500,
            ),
          ),

          // Speech Status or Error Notice (if any)
          if (_speechMessage != null && !isListening) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: bodyColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: bodyColor.withValues(alpha: 0.15)),
              ),
              child: Text(
                _speechMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.captionSmall.copyWith(color: bodyColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutputCard({
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
    required Color primaryColor,
  }) {
    final isArabic = _targetCode == 'ar';
    final hasResult = _resultText.trim().isNotEmpty;
    final isPlayingTts = _ttsService.isPlaying;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerHighest
            : AppColors.canvasCream.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.goldLight.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardInnerGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Output Box
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('translator.translationResult', {
                    'lang': _getBarLanguageName(_targetLanguage.code),
                  }),
                  style: AppTypography.captionSmall.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isTranslating) ...[
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Output Text Content
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: _isTranslating
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _statusMessage.isNotEmpty
                          ? _statusMessage
                          : context.tr('translator.translating'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Align(
                    alignment: isArabic
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      hasResult
                          ? _resultText
                          : context.tr('translator.outputPlaceholder'),
                      textDirection: (hasResult && isArabic)
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: (isArabic && hasResult)
                          ? AppTypography.displayMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            )
                          : AppTypography.bodyLarge.copyWith(
                              color: hasResult
                                  ? headingColor
                                  : bodyColor.withValues(alpha: 0.45),
                              fontWeight: hasResult
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              height: 1.35,
                            ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Bottom Action Toolbar for Result (Copy & Audio Pronunciation)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasResult) ...[
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    color: bodyColor.withValues(alpha: 0.75),
                    size: 20,
                  ),
                  tooltip: context.tr('translator.copyTooltip'),
                  onPressed: _copyResult,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: hasResult ? _speakResult : null,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasResult
                          ? (isPlayingTts
                                ? AppColors.sosEmergency
                                : primaryColor.withValues(alpha: 0.12))
                          : bodyColor.withValues(alpha: 0.06),
                    ),
                    child: Center(
                      child: Icon(
                        isPlayingTts
                            ? Icons.stop_circle_rounded
                            : Icons.volume_up_rounded,
                        color: hasResult
                            ? (isPlayingTts ? Colors.white : primaryColor)
                            : bodyColor.withValues(alpha: 0.25),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Quick Haji Phrases horizontal carousel for instant one-tap translation
  Widget _buildQuickPhrasesSection(
    bool isDark,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final quickPhraseHeight = (42.0 * textScale).clamp(42.0, 68.0);
    final phrases = _getQuickPhrases(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.accentGoldStar,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.tr('translator.quickPhrasesTitle'),
                style: AppTypography.labelLarge.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: quickPhraseHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: phrases.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final phrase = phrases[index];
              return InkWell(
                onTap: () => _applyQuickPhrase(phrase),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: (4.0 * textScale).clamp(2.0, 8.0),
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.espressoDark.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(phrase.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        phrase.label,
                        style: AppTypography.captionSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
