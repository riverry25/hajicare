import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../sign_language/models/bisindo_prediction.dart';
import '../../sign_language/services/bisindo_camera_landmark_service.dart';
import '../../sign_language/services/bisindo_inference_service.dart';
import '../../sign_language/services/landmark_stream_buffer.dart';

/// Clean card displaying BISINDO ONNX inference status, live camera detection,
/// MediaPipe landmark stream, and self-test controls on the Communication screen.
class BisindoCard extends StatefulWidget {
  const BisindoCard({super.key});

  @override
  State<BisindoCard> createState() => _BisindoCardState();
}

class _BisindoCardState extends State<BisindoCard> {
  late final BisindoInferenceService _inferenceService;
  late final LandmarkStreamBuffer _streamBuffer;
  late final BisindoCameraLandmarkService _cameraService;

  bool _isLoading = true;
  bool _isTesting = false;
  bool _isStartingCamera = false;
  String? _errorMessage;
  BisindoPrediction? _latestPrediction;

  @override
  void initState() {
    super.initState();
    _inferenceService = BisindoInferenceService();

    _streamBuffer = LandmarkStreamBuffer(
      inferenceService: _inferenceService,
      throttleDuration: const Duration(milliseconds: 300),
      onPrediction: (prediction) {
        if (mounted) {
          setState(() {
            _latestPrediction = prediction;
          });
        }
      },
      onError: (err) {
        debugPrint('[BISINDO_CARD] Inference error: $err');
        if (mounted) {
          setState(() {
            _errorMessage = 'Gerakan belum dapat diproses. Silakan coba lagi.';
          });
        }
      },
    );

    _cameraService = BisindoCameraLandmarkService(streamBuffer: _streamBuffer);

    _cameraService.errorNotifier.addListener(_onCameraErrorChanged);
    _cameraService.isStreamingNotifier.addListener(_onCameraStateChanged);

    _initModel();
  }

  void _onCameraErrorChanged() {
    if (mounted && _cameraService.errorNotifier.value != null) {
      setState(() {
        _errorMessage = _cameraService.errorNotifier.value;
      });
    }
  }

  void _onCameraStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraService.errorNotifier.removeListener(_onCameraErrorChanged);
    _cameraService.isStreamingNotifier.removeListener(_onCameraStateChanged);
    unawaited(_disposePipeline());
    super.dispose();
  }

  Future<void> _disposePipeline() async {
    await _cameraService.dispose();
    _streamBuffer.dispose();
    await _inferenceService.dispose();
  }

  Future<void> _initModel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _inferenceService.initialize();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_isStartingCamera || _isLoading) return;

    if (_cameraService.isCameraActive) {
      await _cameraService.stopCamera();
      if (mounted) {
        setState(() {});
      }
    } else {
      setState(() {
        _isStartingCamera = true;
        _errorMessage = null;
      });

      var permission = await _cameraService.checkPermission();
      if (permission != 'granted') {
        permission = await _cameraService.requestPermission();
      }
      if (permission != 'granted') {
        if (mounted) {
          setState(() {
            _isStartingCamera = false;
            _errorMessage =
                'Izinkan akses kamera agar penerjemah BISINDO dapat digunakan.';
          });
        }
        return;
      }

      final success = await _cameraService.startCamera();
      if (mounted) {
        setState(() {
          _isStartingCamera = false;
          if (!success && _cameraService.lastError != null) {
            _errorMessage = _cameraService.lastError;
          }
        });
      }
    }
  }

  Future<void> _runSelfTest() async {
    if (_isTesting || _isLoading) return;

    setState(() {
      _isTesting = true;
      _errorMessage = null;
    });

    try {
      final prediction = await _inferenceService.runSelfTest();
      if (mounted) {
        setState(() {
          _latestPrediction = prediction;
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _errorMessage = 'Uji coba gagal: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isCameraActive = _cameraService.isCameraActive;
    final isRecognitionConfirmed = _latestPrediction?.isRecognized == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCameraActive
              ? Colors.green.withValues(alpha: 0.5)
              : AppColors.goldPrimary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title and Status Badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCameraActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.canvasCream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCameraActive
                        ? Colors.green
                        : AppColors.goldPrimary.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.sign_language_rounded,
                  color: isCameraActive ? Colors.green : AppColors.goldPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BISINDO AI Recognizer',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MediaPipe Holistic 543 • ONNX On-Device',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Camera Stream & Adapter Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.canvasCream,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  isCameraActive
                      ? Icons.videocam_rounded
                      : Icons.sensors_rounded,
                  size: 16,
                  color: isCameraActive ? Colors.green : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCameraActive
                        ? 'Kamera Aktif: Menganalisis gerakan isyarat (Buffer: ${_streamBuffer.bufferLength}/100)...'
                        : 'Kamera Siap: MediaPipe Holistic 543 → ONNX',
                    style: AppTypography.captionSmall.copyWith(
                      color: isCameraActive
                          ? Colors.green.shade800
                          : AppColors.textMuted,
                      fontWeight: isCameraActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.sosEmergency.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.sosEmergency,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.sosEmergency,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Prediction Display
          if (_latestPrediction != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.goldPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRecognitionConfirmed
                              ? 'HASIL DETEKSI ISYARAT'
                              : 'GERAKAN BELUM DIKENALI',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.goldPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isRecognitionConfirmed
                              ? _latestPrediction!.label
                              : 'Silakan ulangi perlahan',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.textHeadingColor(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRecognitionConfirmed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Stabil',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              _latestPrediction!.guidance ??
                  'Pastikan bahu dan tangan terlihat di dalam kamera.',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Camera Control Button (Realtime Live Detection)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isLoading || _isStartingCamera)
                  ? null
                  : _toggleCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCameraActive
                    ? AppColors.sosEmergency
                    : AppColors.espressoDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              icon: _isStartingCamera
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isCameraActive
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      size: 18,
                    ),
              label: Text(
                _isStartingCamera
                    ? 'Menghubungkan Kamera...'
                    : (isCameraActive
                          ? 'Hentikan Kamera Deteksi'
                          : 'Mulai Deteksi Kamera Realtime'),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Action Button: Run Self-Test
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isLoading || _isTesting || isCameraActive)
                  ? null
                  : _runSelfTest,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.espressoDark,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                side: BorderSide(
                  color: AppColors.goldPrimary.withValues(alpha: 0.4),
                ),
              ),
              icon: _isTesting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.goldPrimary,
                      ),
                    )
                  : const Icon(Icons.play_circle_outline_rounded, size: 16),
              label: Text(
                _isTesting
                    ? 'Menjalankan Self-Test...'
                    : 'Uji Prediksi Mandiri (Synthetic Sequence)',
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.tanMedium.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.tanMedium,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Memuat ONNX',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.tanMedium,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.sosEmergency.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          'Error',
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.sosEmergency,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      );
    }

    final isCameraActive = _cameraService.isCameraActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isCameraActive ? Colors.green : AppColors.goldPrimary)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isCameraActive ? Colors.green : AppColors.goldPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isCameraActive ? 'Live Kamera' : 'ONNX Siap',
            style: AppTypography.captionSmall.copyWith(
              color: isCameraActive
                  ? Colors.green.shade800
                  : AppColors.goldPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
