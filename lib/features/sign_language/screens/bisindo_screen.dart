import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../translator/services/tts_service.dart';
import '../controllers/bisindo_recognition_controller.dart';
import '../models/sign_token.dart';
import '../services/bisindo_camera_landmark_service.dart';
import '../services/bisindo_inference_service.dart';
import '../services/landmark_stream_buffer.dart';

/// Realtime BISINDO sequence recognition and structured transcript screen.
class BisindoScreen extends StatefulWidget {
  const BisindoScreen({super.key});

  @override
  State<BisindoScreen> createState() => _BisindoScreenState();
}

class _BisindoScreenState extends State<BisindoScreen> {
  static const _teal = Color(0xFF007C7A);
  static const _purple = Color(0xFF6547F5);

  late final BisindoInferenceService _inferenceService;
  late final BisindoRecognitionController _recognition;
  late final LandmarkStreamBuffer _streamBuffer;
  late final BisindoCameraLandmarkService _cameraService;
  late final TtsService _ttsService;

  bool _isModelInitialized = false;
  bool _isStartingCamera = false;
  bool _isPermissionDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _inferenceService = Get.find<BisindoInferenceService>();
    _recognition = Get.find<BisindoRecognitionController>();
    _ttsService = TtsService();
    _streamBuffer = LandmarkStreamBuffer(
      inferenceService: _inferenceService,
      windowSize: 100,
      throttleDuration: _recognition.config.predictionInterval,
      minimumFrames: 30,
      onPrediction: _recognition.handlePrediction,
      onError: _onInferenceError,
    );
    _cameraService = BisindoCameraLandmarkService(streamBuffer: _streamBuffer);
    _cameraService.errorNotifier.addListener(_onCameraErrorChanged);
    _cameraService.isStreamingNotifier.addListener(_onCameraStateChanged);
    _cameraService.framesCountNotifier.addListener(_onLandmarkFrame);
    unawaited(_loadModel());
  }

  Future<void> _loadModel() async {
    try {
      await _inferenceService.initialize();
      if (!mounted) return;
      setState(() => _isModelInitialized = true);
    } catch (error) {
      debugPrint('[BISINDO_UI] Model initialization error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Penerjemah BISINDO belum siap. Tutup halaman lalu coba lagi.';
      });
    }
  }

  void _onInferenceError(Object error) {
    debugPrint('[BISINDO_UI] Inference error: $error');
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Gerakan belum dapat diproses. Silakan coba lagi.';
    });
  }

  void _onCameraErrorChanged() {
    final error = _cameraService.errorNotifier.value;
    if (!mounted || error == null) return;
    setState(() => _errorMessage = error);
  }

  void _onCameraStateChanged() {
    if (!mounted) return;
    _recognition.setCameraActive(_cameraService.isCameraActive);
    setState(() {});
  }

  void _onLandmarkFrame() {
    if (_cameraService.framesCountNotifier.value > 0) {
      _recognition.registerHandFrame();
    }
  }

  Future<void> _toggleDetection() async {
    if (_isStartingCamera || !_isModelInitialized) return;
    if (_cameraService.isCameraActive) {
      await _cameraService.stopCamera();
      _recognition.setCameraActive(false);
      return;
    }

    setState(() {
      _isStartingCamera = true;
      _errorMessage = null;
    });

    var permission = await _cameraService.checkPermission();
    if (!mounted) return;
    if (permission != 'granted') {
      permission = await _cameraService.requestPermission();
      if (!mounted) return;
    }
    if (permission != 'granted') {
      setState(() {
        _isStartingCamera = false;
        _isPermissionDenied = true;
        _errorMessage = 'Izin kamera diperlukan untuk mendeteksi isyarat.';
      });
      return;
    }

    _isPermissionDenied = false;
    final started = await _cameraService.startCamera();
    if (!mounted) return;
    _recognition.setCameraActive(started);
    setState(() {
      _isStartingCamera = false;
      if (!started) _errorMessage = _cameraService.lastError;
    });
  }

  Future<void> _sendToAi() async {
    if (_recognition.rawTranscript.value.trim().isEmpty) {
      _showMessage('Belum ada hasil isyarat untuk dikirim.');
      return;
    }
    try {
      final sent = await _recognition.sendToAi();
      if (!sent && mounted) {
        _showMessage(
          'Layanan AI belum dikonfigurasi. Hasil mentah tetap tersimpan.',
        );
      }
    } catch (error) {
      debugPrint('[BISINDO_AI] request error: $error');
      if (mounted) _showMessage('AI belum dapat memproses teks saat ini.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _cameraService.errorNotifier.removeListener(_onCameraErrorChanged);
    _cameraService.isStreamingNotifier.removeListener(_onCameraStateChanged);
    _cameraService.framesCountNotifier.removeListener(_onLandmarkFrame);
    _ttsService.dispose();
    unawaited(_disposePipeline());
    super.dispose();
  }

  Future<void> _disposePipeline() async {
    _recognition.setCameraActive(false);
    await _cameraService.dispose();
    _streamBuffer.dispose();
    await _inferenceService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFFFFCFA),
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : const Color(0xFFFFFCFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            const Text('🤟', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 9),
            Text(
              'Isyarat ke Teks',
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
            _CameraPanel(
              isActive: _cameraService.isCameraActive,
              recognition: _recognition,
            ),
            if (_errorMessage != null) _buildErrorCard(),
            if (_isPermissionDenied) _buildPermissionAction(),
            const SizedBox(height: 14),
            _buildTokenChips(),
            const SizedBox(height: 14),
            _buildTranscriptCard(isDark),
            const SizedBox(height: 20),
            _buildControls(),
            const SizedBox(height: 16),
            _buildRecognitionStatus(),
            const SizedBox(height: 18),
            _buildAiButton(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Model lokal saat ini mengenali 8 isyarat kata. Dukungan alfabet aktif otomatis saat label LETTER_A–LETTER_Z tersedia di model.',
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

  Widget _buildTokenChips() {
    return Obx(() {
      final items = _recognition.tokens;
      return Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: items.isEmpty
            ? Text(
                'Hasil terkonfirmasi akan muncul di sini',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontStyle: FontStyle.italic,
                ),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                spacing: 7,
                runSpacing: 7,
                children: items.map(_buildTokenChip).toList(),
              ),
      );
    });
  }

  Widget _buildTokenChip(SignToken token) {
    if (token.type == SignTokenType.space) {
      return Container(
        width: 26,
        height: 40,
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _teal.withValues(alpha: 0.18)),
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _teal.withValues(alpha: 0.22)),
      ),
      child: Text(
        token.type == SignTokenType.letter
            ? token.value.toUpperCase()
            : token.value,
        style: AppTypography.bodyMedium.copyWith(
          color: _teal,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(bool isDark) {
    return Obx(() {
      final ai = _recognition.aiTranscript.value;
      final raw = _recognition.rawTranscript.value;
      final display = ai.isNotEmpty
          ? ai
          : raw.isNotEmpty
          ? raw
          : 'Mulai isyarat untuk melihat terjemahan...';
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 136),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainer : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 4, backgroundColor: _teal),
                const SizedBox(width: 10),
                Text(
                  ai.isEmpty ? 'TRANSKRIPSI' : 'TRANSKRIPSI AI',
                  style: AppTypography.captionSmall.copyWith(
                    color: _teal,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              display,
              style: raw.isEmpty
                  ? AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontStyle: FontStyle.italic,
                    )
                  : AppTypography.titleLarge.copyWith(
                      color: AppColors.textHeadingColor(context),
                      fontWeight: FontWeight.w800,
                    ),
            ),
            if (raw.isNotEmpty) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () =>
                    _ttsService.speak(text: display, languageCode: 'id'),
                icon: const Icon(Icons.volume_up_rounded, size: 19),
                label: const Text('Dengarkan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _teal,
                  backgroundColor: _teal.withValues(alpha: 0.06),
                  side: BorderSide.none,
                ),
              ),
            ],
            if (ai.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Hasil mentah: $raw',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
            ],
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
          label: _cameraService.isCameraActive ? 'STOP' : 'MULAI',
          icon: _isStartingCamera
              ? Icons.hourglass_top_rounded
              : _cameraService.isCameraActive
              ? Icons.stop_rounded
              : Icons.videocam_rounded,
          color: const Color(0xFFC62828),
          onTap: _isModelInitialized && !_isStartingCamera
              ? _toggleDetection
              : null,
        ),
        const SizedBox(width: 22),
        _RoundControl(
          label: 'HAPUS',
          icon: Icons.backspace_rounded,
          color: const Color(0xFFF3A000),
          onTap: _recognition.deleteLast,
        ),
        const SizedBox(width: 22),
        _RoundControl(
          label: 'RESET',
          icon: Icons.format_align_center_rounded,
          color: Colors.grey.shade600,
          onTap: _recognition.resetTranscript,
        ),
      ],
    );
  }

  Widget _buildRecognitionStatus() {
    return Obx(() {
      final progress = _recognition.confirmationProgress.value;
      final holding =
          _recognition.recognitionState.value == SignRecognitionState.holding;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Text(
              _recognition.statusText,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: holding ? _teal : AppColors.textBodyColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: _teal.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation(_teal),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _recognition.insertSpace,
              icon: const Icon(Icons.space_bar_rounded),
              label: const Text('SPASI'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: BorderSide(color: _teal.withValues(alpha: 0.4)),
                shape: const StadiumBorder(),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Auto-konfirmasi setelah stabil ±${_recognition.config.confirmationDuration.inMilliseconds} ms',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAiButton() {
    return Obx(() {
      final raw = _recognition.rawTranscript.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: raw.isEmpty || _recognition.isSendingToAi.value
                ? null
                : _sendToAi,
            icon: _recognition.isSendingToAi.value
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              raw.isEmpty ? 'Kirim ke AI' : 'Kirim ke AI  [$raw]',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _purple.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
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

  Widget _buildPermissionAction() {
    return Center(
      child: TextButton.icon(
        onPressed: _toggleDetection,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Izinkan kamera'),
      ),
    );
  }
}

class _CameraPanel extends StatelessWidget {
  final bool isActive;
  final BisindoRecognitionController recognition;

  const _CameraPanel({required this.isActive, required this.recognition});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SizedBox(
        height: 330,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: const Color(0xFF2B2522),
              child: isActive
                  ? const AndroidView(
                      viewType: 'com.hajicare.bisindo/camera_preview',
                      layoutDirection: TextDirection.ltr,
                      creationParams: <String, dynamic>{},
                      creationParamsCodec: StandardMessageCodec(),
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
                        ],
                      ),
                    ),
            ),
            Positioned(
              left: 14,
              top: 13,
              child: _CameraBadge(
                text: isActive ? '●  LIVE' : 'STANDBY',
                color: isActive ? const Color(0xFF315B46) : Colors.black54,
              ),
            ),
            const Positioned(
              left: 95,
              top: 13,
              child: _CameraBadge(
                text: 'BISINDO · 100F',
                color: Color(0xFF006D75),
              ),
            ),
            Obx(() {
              final label = recognition.currentCandidate.value;
              if (label == null) return const SizedBox.shrink();
              final state = recognition.recognitionState.value;
              final confirmed = state == SignRecognitionState.confirmed;
              return Positioned(
                right: 15,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007C7A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 9),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${confirmed ? '✓ ' : ''}${label.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 21,
                        ),
                      ),
                      Text(
                        '${(recognition.candidateConfidence.value * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Obx(() {
              final progress = recognition.confirmationProgress.value;
              if (progress <= 0 ||
                  recognition.recognitionState.value !=
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
                    color: Colors.black.withValues(alpha: 0.62),
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
                              Color(0xFF43D5C7),
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
}

class _CameraBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _CameraBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
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
            width: 60,
            height: 60,
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
