import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/bisindo_recognition_controller.dart';
import '../models/sign_token.dart';
import '../services/bisindo_yolo_service.dart';

/// Realtime BISINDO Sign Language to Text and Speech screen.
/// Uses YOLOv8 (best.tflite) for alphabet recognition via the front camera.
class BisindoScreen extends StatefulWidget {
  const BisindoScreen({super.key});

  @override
  State<BisindoScreen> createState() => _BisindoScreenState();
}

class _BisindoScreenState extends State<BisindoScreen> {
  static Color _accent(BuildContext context) => AppColors.isDark(context)
      ? AppColors.darkPrimary
      : AppColors.espressoDark;
  static Color _accentGold(BuildContext context) => AppColors.isDark(context)
      ? AppColors.accentGoldStar
      : AppColors.goldPrimary;

  late final BisindoRecognitionController _recognition;
  late final BisindoYoloService _yoloService;
  late final YOLOViewController _yoloController;

  bool _isCameraActive = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _recognition = Get.find<BisindoRecognitionController>();
    _yoloService = BisindoYoloService();
    _yoloController = YOLOViewController();
    unawaited(_initLabels());
  }

  Future<void> _initLabels() async {
    try {
      await _yoloService.loadLabels();
    } catch (e) {
      debugPrint('[BISINDO_YOLO] Label load error: $e');
      // fallback A-Z labels are used automatically
    }
  }

  void _onYoloResult(List<YOLOResult> results) {
    if (!_isCameraActive) return;

    if (results.isEmpty) {
      _recognition.handleNoHand();
      return;
    }

    final confident = results
        .where(
          (r) => r.confidence >= BisindoYoloService.kDefaultConfidenceThreshold,
        )
        .toList();

    if (confident.isEmpty) {
      _recognition.handleNoHand();
      return;
    }

    final prediction = _yoloService.processDetections(confident);
    if (prediction.isRecognized) {
      _recognition.handlePrediction(prediction);
    } else {
      _recognition.handleNoHand();
    }
  }

  void _onModelLoaded(String modelPath, YOLOTask? task) {
    debugPrint('[BISINDO_YOLO] Model loaded: $modelPath task=$task');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      unawaited(_yoloController.setShowOverlays(false));
    }
  }

  void _onModelError(Object error, String modelPath, YOLOTask? task) {
    debugPrint('[BISINDO_YOLO] Model error: $error');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat model: $error';
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_isLoading) return;
    if (_isCameraActive) {
      await _yoloController.stop();
      _recognition.setCameraActive(false);
      if (mounted) setState(() => _isCameraActive = false);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isCameraActive = true;
      });
      _recognition.setCameraActive(true);
    }
  }

  @override
  void dispose() {
    _recognition.setCameraActive(false);
    _yoloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.cardBgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textHeadingColor(context),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.sign_language_rounded,
              color: AppColors.textHeadingColor(context),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'BISINDO Translator',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textHeadingColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _buildCameraPanel(),
            if (_errorMessage != null) _buildErrorCard(),
            const SizedBox(height: 16),
            _buildUnifiedResultCard(),
            const SizedBox(height: 18),
            _buildRecognitionStatus(),
            const SizedBox(height: 18),
            _buildControls(),
            const SizedBox(height: 18),
            _buildSpeakButton(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Arahkan tangan ke kamera untuk mendeteksi huruf BISINDO secara langsung.',
                textAlign: TextAlign.center,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SizedBox(
        height: 330,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.espressoDark,
              child: _isCameraActive
                  ? YOLOView(
                      modelPath: BisindoYoloService.kModelPath,
                      task: YOLOTask.detect,
                      controller: _yoloController,
                      lensFacing: LensFacing.front,
                      cameraResolution: '720p',
                      confidenceThreshold:
                          BisindoYoloService.kDefaultConfidenceThreshold,
                      iouThreshold: 0.45,
                      onResult: _onYoloResult,
                      onModelLoad: _onModelLoaded,
                      onModelError: _onModelError,
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sign_language_rounded,
                            color: Colors.white.withValues(alpha: 0.82),
                            size: 54,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Kamera belum aktif',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tekan tombol MULAI di bawah',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              left: 14,
              top: 13,
              child: _CameraBadge(
                text: _isCameraActive ? 'LIVE' : 'STANDBY',
                isLive: _isCameraActive,
                color: _isCameraActive
                    ? AppColors.emeraldIslamic
                    : Colors.black54,
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Obx(() {
              final label = _recognition.currentCandidate.value;
              if (label == null || label.isEmpty) {
                return const SizedBox.shrink();
              }
              final state = _recognition.recognitionState.value;
              final confirmed = state == SignRecognitionState.confirmed;
              final holding = state == SignRecognitionState.holding;
              final progress = _recognition.holdProgress.value;
              final conf = (_recognition.candidateConfidence.value * 100)
                  .round();
              final isSingleChar = label.length == 1;

              return Positioned(
                right: 20,
                bottom: 26,
                child: AnimatedScale(
                  scale: confirmed ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSingleChar ? 22 : 18,
                      vertical: isSingleChar ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6B58),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: confirmed
                            ? AppColors.accentGoldStar
                            : Colors.white.withValues(alpha: 0.35),
                        width: confirmed ? 2.5 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (confirmed) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accentGoldStar,
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              isSingleChar ? label.toUpperCase() : label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: isSingleChar ? 34 : 20,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$conf%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (holding && progress > 0) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: isSingleChar ? 36 : 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.accentGoldStar,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            Obx(() {
              final progress = _recognition.holdProgress.value;
              if (progress <= 0 ||
                  _recognition.recognitionState.value !=
                      SignRecognitionState.holding) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.accentGoldStar,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedResultCard() {
    return Obx(() {
      final isDark = AppColors.isDark(context);
      final items = _recognition.tokens;
      final raw = _recognition.rawTranscript.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainer : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 4,
                      backgroundColor: AppColors.emeraldIslamic,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HASIL TERJEMAHAN ISYARAT',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.emeraldIslamic,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (items.isNotEmpty)
                  Text(
                    '${items.length} Gerakan',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              alignment: Alignment.centerLeft,
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Mulai isyarat untuk melihat kotak hasil terjemahan...',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: items.map(_buildGestureBox).toList(),
                      ),
                    ),
            ),
            if (raw.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
                height: 1,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      raw,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _recognition.speakTranscript,
                    icon: const Icon(Icons.volume_up_rounded, size: 18),
                    label: const Text('Dengarkan'),
                    style: TextButton.styleFrom(
                      foregroundColor: _accent(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildGestureBox(SignToken token) {
    final isDark = AppColors.isDark(context);

    if (token.type == SignTokenType.space) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 38,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F6F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFC7E2D8),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.space_bar_rounded,
            size: 20,
            color: AppColors.textSecondaryColor(context),
          ),
        ),
      );
    }

    final isLetter = token.type == SignTokenType.letter;
    final text = isLetter ? token.value.toUpperCase() : token.value;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isLetter ? 14 : 16,
        vertical: 10,
      ),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.emeraldIslamic.withValues(alpha: 0.15)
            : const Color(0xFFF0F8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.emeraldIslamic.withValues(alpha: 0.45)
              : const Color(0xFFB5DEC8),
          width: 1.3,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? AppColors.goldLight : const Color(0xFF0F5A47),
            fontSize: isLetter ? 17 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildRecognitionStatus() {
    return Obx(() {
      final progress = _recognition.holdProgress.value;
      final holding =
          _recognition.recognitionState.value == SignRecognitionState.holding;
      final confirmed =
          _recognition.recognitionState.value == SignRecognitionState.confirmed;
      final gold = _accentGold(context);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (holding)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(gold),
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    _recognition.statusText,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: confirmed
                          ? AppColors.emeraldIslamic
                          : holding
                          ? gold
                          : AppColors.textBodyColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: gold.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  confirmed ? AppColors.emeraldIslamic : gold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tahan gerakan ±${_recognition.config.confirmationDuration.inMilliseconds} ms hingga penuh',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundControl(
          label: _isCameraActive ? 'STOP' : 'MULAI',
          icon: _isLoading
              ? Icons.hourglass_top_rounded
              : _isCameraActive
              ? Icons.stop_rounded
              : Icons.videocam_rounded,
          color: _isCameraActive
              ? AppColors.sosEmergency
              : AppColors.emeraldIslamic,
          onTap: !_isLoading ? _toggleCamera : null,
        ),
        const SizedBox(width: 20),
        _RoundControl(
          label: 'HAPUS',
          icon: Icons.backspace_rounded,
          color: AppColors.distanceWarning,
          onTap: _recognition.deleteLast,
        ),
        const SizedBox(width: 20),
        _RoundControl(
          label: 'SPASI',
          icon: Icons.space_bar_rounded,
          color: _accent(context),
          onTap: _recognition.insertSpace,
        ),
        const SizedBox(width: 20),
        _RoundControl(
          label: 'RESET',
          icon: Icons.refresh_rounded,
          color: AppColors.textMuted,
          onTap: _recognition.resetTranscript,
        ),
      ],
    );
  }

  Widget _buildSpeakButton() {
    return Obx(() {
      final raw = _recognition.rawTranscript.value.trim();
      final isSpeaking = _recognition.isSpeaking.value;
      final accent = _accent(context);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: raw.isEmpty ? null : _recognition.speakTranscript,
            icon: isSpeaking
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.record_voice_over_rounded, size: 22),
            label: Text(
              isSpeaking
                  ? 'Sedang Membaca...'
                  : raw.isEmpty
                  ? 'UCAPKAN (TEKS KOSONG)'
                  : 'UCAPKAN HASIL',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accent.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 2,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _errorMessage!,
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isLive;

  const _CameraBadge({
    required this.text,
    required this.color,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _RoundControl({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: onTap == null ? 0.06 : 0.10),
              border: Border.all(
                color: color.withValues(alpha: onTap == null ? 0.18 : 0.55),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: color.withValues(alpha: onTap == null ? 0.35 : 1),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}
