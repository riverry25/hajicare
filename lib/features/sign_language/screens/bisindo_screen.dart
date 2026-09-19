import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../models/bisindo_prediction.dart';
import '../services/bisindo_camera_landmark_service.dart';
import '../services/bisindo_inference_service.dart';
import '../services/landmark_stream_buffer.dart';

/// Dedicated BISINDO screen featuring realtime CameraX + MediaPipe holistic landmarking,
/// sliding temporal buffer (100 frames), and on-device ONNX prototype matching.
class BisindoScreen extends StatefulWidget {
  const BisindoScreen({super.key});

  @override
  State<BisindoScreen> createState() => _BisindoScreenState();
}

class _BisindoScreenState extends State<BisindoScreen> {
  late final BisindoInferenceService _inferenceService;
  late final LandmarkStreamBuffer _streamBuffer;
  late final BisindoCameraLandmarkService _cameraService;

  bool _isModelInitialized = false;
  bool _isStartingCamera = false;
  bool _isPermissionDenied = false;
  String? _errorMessage;
  BisindoPrediction? _latestPrediction;

  int _bufferCount = 0;

  @override
  void initState() {
    super.initState();
    _initPipeline();
  }

  void _initPipeline() {
    _inferenceService = Get.isRegistered<BisindoInferenceService>()
        ? Get.find<BisindoInferenceService>()
        : Get.put(BisindoInferenceService(), permanent: true);

    _streamBuffer = LandmarkStreamBuffer(
      inferenceService: _inferenceService,
      windowSize: 100,
      throttleDuration: const Duration(milliseconds: 300),
      onPrediction: (prediction) {
        if (mounted) {
          setState(() {
            _latestPrediction = prediction;
            _errorMessage = null;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Inference error: $err';
          });
        }
      },
    );

    _cameraService = BisindoCameraLandmarkService(streamBuffer: _streamBuffer);
    _cameraService.errorNotifier.addListener(_onCameraErrorChanged);
    _cameraService.isStreamingNotifier.addListener(_onCameraStateChanged);
    _cameraService.framesCountNotifier.addListener(_onFramesCountChanged);

    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _inferenceService.initialize();
      if (mounted) {
        setState(() {
          _isModelInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat model BISINDO: $e';
        });
      }
    }
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

  void _onFramesCountChanged() {
    if (mounted) {
      setState(() {
        _bufferCount = _streamBuffer.bufferLength;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.errorNotifier.removeListener(_onCameraErrorChanged);
    _cameraService.isStreamingNotifier.removeListener(_onCameraStateChanged);
    _cameraService.framesCountNotifier.removeListener(_onFramesCountChanged);

    _cameraService.stopCamera();
    _cameraService.dispose();
    _streamBuffer.dispose();
    super.dispose();
  }

  Future<void> _toggleDetection() async {
    if (_isStartingCamera) return;

    if (_cameraService.isCameraActive) {
      await _cameraService.stopCamera();
      if (mounted) {
        setState(() {
          _bufferCount = 0;
        });
      }
      return;
    }

    setState(() {
      _isStartingCamera = true;
      _errorMessage = null;
    });

    // 1. Check and request camera permission
    final permStatus = await _cameraService.checkPermission();
    if (permStatus != 'granted') {
      final reqResult = await _cameraService.requestPermission();
      if (reqResult != 'granted') {
        if (mounted) {
          setState(() {
            _isStartingCamera = false;
            _isPermissionDenied = true;
            _errorMessage = 'Izin kamera diperlukan untuk mendeteksi isyarat.';
          });
        }
        return;
      }
    }

    _isPermissionDenied = false;

    // 2. Start CameraX and MediaPipe Tasks
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

  /// Diagnostic tool: Feeds synthetic landmark motion into the exact same pipeline
  /// to demonstrate prediction shifts across prototypes (Air, Saya, Tuli).
  Future<void> _runDiagnosticGesture(String targetClass) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // Generate synthetic motion frame sequence with distinct hand/body kinematics
      final frames = _generateDiagnosticSequence(targetClass);
      for (final frame in frames) {
        _streamBuffer.addFrame(frame);
      }
      setState(() {
        _bufferCount = _streamBuffer.bufferLength;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Uji diagnostik gagal: $e';
      });
    }
  }

  List<List<List<double>>> _generateDiagnosticSequence(String targetClass) {
    // Generate 40 frames with class-specific hand placement
    final int frames = 40;
    final double handOffset = targetClass == 'Air'
        ? 0.15
        : (targetClass == 'Saya' ? -0.10 : 0.0);

    return List.generate(frames, (t) {
      final double progress = t / frames;
      final double wave = math.sin(progress * math.pi * 2);

      return List.generate(543, (i) {
        if (i == 0) return [0.5, 0.2, 0.0]; // Nose
        if (i == 2) return [0.48, 0.18, 0.0];
        if (i == 5) return [0.52, 0.18, 0.0];
        if (i == 11) return [0.40, 0.35, 0.0]; // Left shoulder
        if (i == 12) return [0.60, 0.35, 0.0]; // Right shoulder
        if (i == 13) return [0.35, 0.50 + 0.05 * wave, 0.0];
        if (i == 14) return [0.65, 0.50 - 0.05 * wave, 0.0];
        if (i >= 501 && i < 522) {
          // Left hand
          return [0.30 + handOffset + 0.05 * wave, 0.65, 0.0];
        }
        if (i >= 522 && i < 543) {
          // Right hand
          return [0.70 - handOffset - 0.05 * wave, 0.65, 0.0];
        }
        return [0.0, 0.0, 0.0];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isCameraActive = _cameraService.isCameraActive;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkSurface
          : AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.canvasCream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textHeadingColor(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BISINDO',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textHeadingColor(context),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Bahasa Isyarat Indonesia',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.goldPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Camera Viewport
              _buildCameraViewport(isCameraActive, isDark),
              const SizedBox(height: 12),

              // 2. Detection Status Chips
              _buildStatusRow(isCameraActive, isDark),
              const SizedBox(height: 14),

              // 3. Permission Alert (if denied)
              if (_isPermissionDenied) ...[
                _buildPermissionAlert(),
                const SizedBox(height: 14),
              ],

              // 4. Error Message (if any)
              if (_errorMessage != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 14),
              ],

              // 5. Prediction Result Card
              _buildPredictionCard(isDark),
              const SizedBox(height: 18),

              // 6. Action Button: [Mulai Deteksi] / [Hentikan Deteksi]
              _buildActionButton(isCameraActive),
              const SizedBox(height: 20),

              // 7. Diagnostic Quick Test (Air / Saya / Tuli)
              _buildDiagnosticSection(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraViewport(bool isCameraActive, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 310,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainer : Colors.black,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCameraActive
                ? Colors.green.shade600
                : AppColors.goldPrimary.withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Active Native CameraX Preview
            if (isCameraActive)
              const AndroidView(
                viewType: 'com.hajicare.bisindo/camera_preview',
                layoutDirection: TextDirection.ltr,
                creationParams: <String, dynamic>{},
                creationParamsCodec: StandardMessageCodec(),
              )
            else
              // Idle state view
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.goldPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kamera Siap',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tekan "Mulai Deteksi" untuk mengaktifkan',
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

            // Subtle posture alignment guide overlay
            IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Live Camera Tag
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCameraActive
                      ? Colors.red.withValues(alpha: 0.85)
                      : Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCameraActive ? Colors.white : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCameraActive ? 'LIVE' : 'STANDBY',
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(bool isCameraActive, bool isDark) {
    final statusText = !isCameraActive
        ? 'Kamera siap'
        : (_bufferCount >= 100 ? 'Menganalisis...' : 'Mengumpulkan gerakan...');

    return Row(
      children: [
        // Status Chip
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.canvasCreamSubtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isCameraActive
                    ? Colors.green.withValues(alpha: 0.4)
                    : AppColors.goldPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCameraActive ? Icons.radar_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: isCameraActive ? Colors.green : AppColors.goldPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textHeadingColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Buffer Chip
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.canvasCreamSubtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.layers_rounded,
                  size: 16,
                  color: AppColors.goldPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Buffer $_bufferCount/100',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textHeadingColor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.sosEmergency.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.sosEmergency, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kamera diperlukan untuk mendeteksi bahasa isyarat.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.sosEmergency,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleDetection,
            child: const Text('Izinkan'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        _errorMessage!,
        style: AppTypography.captionSmall.copyWith(color: AppColors.sosEmergency),
      ),
    );
  }

  Widget _buildPredictionCard(bool isDark) {
    final pred = _latestPrediction;
    final String label = pred?.label ?? 'Menunggu Isyarat...';
    final int confidencePercent = pred != null
        ? (pred.confidence * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: pred != null
              ? AppColors.goldPrimary.withValues(alpha: 0.5)
              : AppColors.canvasCreamSubtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: BISINDO Tag & Confidence Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sign_language_rounded,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BISINDO',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (pred != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$confidencePercent%',
                    style: AppTypography.captionSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Predicted Word
          Text(
            label,
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.textHeadingColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 12),

          // Top candidate chips
          Text(
            'Kandidat Teratas:',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (pred != null && pred.candidates.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: pred.candidates.take(4).map((c) {
                final isTop = c.classId == pred.classId;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isTop
                        ? AppColors.goldPrimary.withValues(alpha: 0.15)
                        : (isDark
                            ? AppColors.darkSurface
                            : AppColors.canvasCream),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isTop
                          ? AppColors.goldPrimary
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${c.label} (${(c.confidence * 100).toStringAsFixed(0)}%)',
                    style: AppTypography.captionSmall.copyWith(
                      color: isTop
                          ? AppColors.goldPrimary
                          : AppColors.textMuted,
                      fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'Air • Saya • Terima kasih • Tuli • Apa • Siapa • Di mana • Keluarga',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isCameraActive) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (!_isModelInitialized || _isStartingCamera)
            ? null
            : _toggleDetection,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCameraActive
              ? AppColors.sosEmergency
              : AppColors.espressoDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 2,
        ),
        icon: _isStartingCamera
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isCameraActive
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                size: 22,
              ),
        label: Text(
          _isStartingCamera
              ? 'Menghubungkan Kamera...'
              : (isCameraActive ? 'Hentikan Deteksi' : 'Mulai Deteksi'),
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.5)
            : AppColors.canvasCreamSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bug_report_rounded,
                size: 16,
                color: AppColors.goldPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Diagnostic Quick Test (Verifikasi Model ONNX)',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _runDiagnosticGesture('Air'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.goldPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text('Uji Air', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _runDiagnosticGesture('Saya'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.goldPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text('Uji Saya', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _runDiagnosticGesture('Tuli'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.goldPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text('Uji Tuli', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
