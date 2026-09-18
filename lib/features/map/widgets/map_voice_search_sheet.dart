import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Google Maps-styled Voice Search Bottom Sheet.
/// Allows pilgrims and officers to search locations by speaking or picking smart suggestions.
class MapVoiceSearchSheet extends StatefulWidget {
  const MapVoiceSearchSheet({super.key});

  /// Displays the voice search sheet and returns the recognized query string if any.
  static Future<String?> show(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = AppColors.isDark(context);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => const MapVoiceSearchSheet(),
    );
  }

  @override
  State<MapVoiceSearchSheet> createState() => _MapVoiceSearchSheetState();
}

class _MapVoiceSearchSheetState extends State<MapVoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _recognizedWords = '';
  String _statusMessage = 'Menyiapkan mikrofon...';
  double _soundLevel = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<String> _quickSuggestions = [
    'Posko Medis',
    'Tempat Wudhu',
    'Toilet Terdekat',
    'Tenda Mina',
    'Maktab 11',
    'Masjid Al Haram',
    'Terminal Bus',
    'Pos Pantau',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'listening') {
            setState(() {
              _isListening = true;
              _statusMessage = 'Mendengarkan... Silakan bicara';
            });
          } else if (status == 'notListening' || status == 'done') {
            setState(() {
              _isListening = false;
              if (_recognizedWords.isNotEmpty) {
                _statusMessage = 'Selesai mendengarkan';
              } else {
                _statusMessage = 'Ketuk ikon mikrofon untuk berbicara lagi';
              }
            });
          }
        },
        onError: (errorNotification) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _statusMessage = errorNotification.errorMsg.contains('error_no_match')
                ? 'Suara tidak terdeteksi. Coba lagi atau pilih rekomendasi.'
                : 'Mikrofon siap. Ketuk untuk mencoba lagi.';
          });
        },
      );

      if (mounted) {
        setState(() {});
        if (_speechEnabled) {
          _startListening();
        } else {
          setState(() {
            _statusMessage = 'Izin mikrofon diperlukan atau layanan suara tidak tersedia.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechEnabled = false;
          _statusMessage = 'Layanan suara offline. Anda bisa menggunakan saran cepat di bawah.';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _recognizedWords = '';
      _isListening = true;
      _statusMessage = 'Mendengarkan... Silakan bicara';
    });

    try {
      // Find Indonesian locale if available, else system default
      final locales = await _speechToText.locales();
      String? targetLocaleId;
      for (final loc in locales) {
        if (loc.localeId.startsWith('id') || loc.localeId.contains('ID')) {
          targetLocaleId = loc.localeId;
          break;
        }
      }

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
          localeId: targetLocaleId,
        ),
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() {
              _soundLevel = (level / 10).clamp(0.0, 1.0);
            });
          }
        },
      );
    } catch (e) {
      debugPrint('[VoiceSearch] listen error: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _recognizedWords = result.recognizedWords;
    });

    if (result.finalResult && _recognizedWords.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.of(context).pop(_recognizedWords.trim());
        }
      });
    }
  }

  Future<void> _stopListening() async {
    HapticFeedback.lightImpact();
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _submitRecognized(String text) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenEdgeGutter,
          right: AppSpacing.screenEdgeGutter,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
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
            const SizedBox(height: AppSpacing.md),

            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.mic_rounded, color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Pencarian Suara',
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: bodyColor,
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Live status prompt
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: _isListening ? primaryColor : bodyColor.withValues(alpha: 0.8),
                fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Interactive Pulsing Mic Orb (Google Maps UX) ─────────────────
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow / Wave Pulse
                  if (_isListening) ...[
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale = _pulseAnimation.value + (_soundLevel * 0.3);
                        return Container(
                          width: 96 * scale,
                          height: 96 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.15),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.22),
                      ),
                    ),
                  ],

                  // Core Mic Button
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [
                                AppColors.sosEmergency,
                                const Color(0xFFE53935),
                              ]
                            : [
                                primaryColor,
                                AppColors.goldDark,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppColors.sosEmergency : primaryColor)
                              .withValues(alpha: 0.38),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Transcription Result Display Box ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer.withValues(alpha: 0.6)
                    : AppColors.canvasCream.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _recognizedWords.isNotEmpty
                      ? primaryColor.withValues(alpha: 0.4)
                      : (isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _recognizedWords.isNotEmpty
                          ? '"$_recognizedWords"'
                          : (_isListening
                              ? 'Katakan nama lokasi...'
                              : 'Ketuk mic di atas atau pilih saran cepat di bawah'),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: _recognizedWords.isNotEmpty
                            ? headingColor
                            : bodyColor.withValues(alpha: 0.65),
                        fontWeight: _recognizedWords.isNotEmpty
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontStyle: _recognizedWords.isNotEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (_recognizedWords.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_rounded, color: primaryColor),
                      tooltip: 'Cari Sekarang',
                      onPressed: () => _submitRecognized(_recognizedWords),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Quick Suggestions Header & Chips ────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saran Pencarian Cepat:',
                style: AppTypography.captionSmall.copyWith(
                  color: bodyColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickSuggestions.map((suggestion) {
                return InkWell(
                  onTap: () => _submitRecognized(suggestion),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.canvasCreamSubtle,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 13,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          suggestion,
                          style: AppTypography.captionSmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
