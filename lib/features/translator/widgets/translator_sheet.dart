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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => const HajiCareTranslatorSheet(),
    );
  }

  @override
  State<HajiCareTranslatorSheet> createState() => _HajiCareTranslatorSheetState();
}

class _HajiCareTranslatorSheetState extends State<HajiCareTranslatorSheet> {
  late final TextEditingController _inputController;
  final TranslationService _translationService = TranslationService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();

  Timer? _debounceTimer;

  // Defaults: Source = Indonesia, Target = Arabic
  String _sourceCode = 'id';
  String _targetCode = 'ar';

  String _resultText = '';
  bool _isTranslating = false;
  String _statusMessage = '';
  String? _speechMessage;

  _LanguageOption get _sourceLanguage =>
      _kLanguages.firstWhere((l) => l.code == _sourceCode, orElse: () => _kLanguages[0]);

  _LanguageOption get _targetLanguage =>
      _kLanguages.firstWhere((l) => l.code == _targetCode, orElse: () => _kLanguages[1]);

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();

    _speechService.onStatusChanged = (status, message) {
      if (!mounted) return;
      setState(() {
        _speechMessage = status == SpeechStatus.idle ? null : message;
      });
      if (status == SpeechStatus.done && _inputController.text.trim().isNotEmpty) {
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

    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performTranslation();
    });
  }

  Future<void> _performTranslation() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _statusMessage = 'Menerjemahkan…';
    });

    try {
      final source = TranslationService.languageFromCode(_sourceCode);
      final target = TranslationService.languageFromCode(_targetCode);

      final translated = await _translationService.translate(
        text: text,
        source: source,
        target: target,
        onStatusUpdate: (status) {
          if (mounted) setState(() => _statusMessage = status);
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
          _statusMessage = 'Gagal menerjemahkan: $e';
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
    HapticFeedback.lightImpact();
    _ttsService.speak(text: _resultText, languageCode: _targetCode);
  }

  void _copyResult() {
    if (_resultText.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _resultText.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Teks terjemahan disalin'),
        duration: const Duration(seconds: 1),
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

  void _selectLanguage({required bool isSource, required _LanguageOption option}) {
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
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.textHeading;
    final selectedCode = isSource ? _sourceCode : _targetCode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdgeGutter),
                  child: Text(
                    isSource ? 'Pilih Bahasa Asal' : 'Pilih Bahasa Tujuan',
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
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      lang.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? (isDark ? AppColors.darkPrimary : AppColors.espressoDark)
                            : headingColor,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
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
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.textHeading;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.espressoDark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenEdgeGutter,
          right: AppSpacing.screenEdgeGutter,
          top: AppSpacing.md,
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
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Header Bar ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.translate_rounded, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Penerjemah HajiCare',
                      style: AppTypography.titleLarge.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: bodyColor),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Source Language Section ───────────────────────────────────
              _buildLanguageSelectorButton(
                language: _sourceLanguage,
                onTap: () => _showLanguageSelector(isSource: true),
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Source Input Box ──────────────────────────────────────────
              _buildInputCard(
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
                primaryColor: primaryColor,
              ),

              if (_speechMessage != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _speechMessage!,
                    style: AppTypography.caption.copyWith(
                      color: _speechService.isListening
                          ? AppColors.sosEmergency
                          : bodyColor.withValues(alpha: 0.8),
                      fontWeight:
                          _speechService.isListening ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),

              // ── Swap Button (Center) ──────────────────────────────────────
              Center(
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _swapLanguages,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.canvasCream,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.outlineVariant.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.swap_vert_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Target Language Section ───────────────────────────────────
              _buildLanguageSelectorButton(
                language: _targetLanguage,
                onTap: () => _showLanguageSelector(isSource: false),
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Target Output Box ─────────────────────────────────────────
              _buildOutputCard(
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
                primaryColor: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelectorButton({
    required _LanguageOption language,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.textHeading;

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                language.name,
                style: AppTypography.titleSmall.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: headingColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
    required Color primaryColor,
  }) {
    final isListening = _speechService.isListening;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isListening
              ? AppColors.sosEmergency
              : (isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant.withValues(alpha: 0.35)),
          width: isListening ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardInnerGutter,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: 3,
              minLines: 1,
              style: AppTypography.bodyMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Ketik teks untuk diterjemahkan…',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: bodyColor.withValues(alpha: 0.55),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onInputChanged,
              onSubmitted: (_) => _performTranslation(),
            ),
          ),
          if (_inputController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear_rounded,
                size: 18,
                color: bodyColor.withValues(alpha: 0.6),
              ),
              onPressed: _clearInput,
              tooltip: 'Hapus Teks',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          IconButton(
            icon: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: isListening ? AppColors.sosEmergency : primaryColor,
              size: 24,
            ),
            tooltip: isListening ? 'Berhenti mendengarkan' : 'Input Suara',
            onPressed: _toggleListening,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
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
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.goldLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardInnerGutter,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _isTranslating
                ? Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _statusMessage.isNotEmpty ? _statusMessage : 'Menerjemahkan…',
                          style: AppTypography.bodySmall.copyWith(
                            color: bodyColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    hasResult ? _resultText : 'Hasil terjemahan…',
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: AppTypography.bodyLarge.copyWith(
                      color: hasResult ? headingColor : bodyColor.withValues(alpha: 0.45),
                      fontWeight: hasResult ? FontWeight.w600 : FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
          ),
          if (hasResult)
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                color: bodyColor.withValues(alpha: 0.75),
                size: 20,
              ),
              tooltip: 'Salin Teks',
              onPressed: _copyResult,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          IconButton(
            icon: Icon(
              isPlayingTts ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
              color: hasResult ? primaryColor : bodyColor.withValues(alpha: 0.35),
              size: 24,
            ),
            tooltip: isPlayingTts ? 'Hentikan Suara' : 'Dengarkan Pengucapan',
            onPressed: hasResult ? _speakResult : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
