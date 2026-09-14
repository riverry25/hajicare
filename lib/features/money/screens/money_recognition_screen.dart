
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/money_detection.dart';
import '../services/money_tts_service.dart';
import '../services/riyal_currency_helper.dart';

class MoneyRecognitionScreen extends StatefulWidget {
  const MoneyRecognitionScreen({super.key});

  @override
  State<MoneyRecognitionScreen> createState() => _MoneyRecognitionScreenState();
}

class _MoneyRecognitionScreenState extends State<MoneyRecognitionScreen>
    with SingleTickerProviderStateMixin {
  // Official Ultralytics Controller
  final YOLOViewController _yoloController = YOLOViewController();

  // Indonesian Multi-Money TTS Service
  final MoneyTtsService _ttsService = MoneyTtsService();

  // Model Asset Configuration
  static const String _modelAssetPath = 'assets/models/best_float16.tflite';

  // State
  bool _isModelLoaded = false;
  String? _modelError;
  bool _isScanningActive = true;
  bool _isTorchOn = false;
  LensFacing _currentLens = LensFacing.back;

  // Realtime Detections & Total
  List<MoneyDetection> _activeDetections = [];
  double _totalAmount = 0.0;
  // Mutable via confidence slider in UI
  // ignore: prefer_final_fields
  double _confidenceThreshold = 0.65;
  int _lastResultProcessedTime = 0;

  // Tap-to-focus visual feedback
  Offset? _focusPoint;

  // Animation controller for scanner indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initServices();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initServices() async {
    await _ttsService.init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ttsService.dispose();
    _yoloController.dispose();
    super.dispose();
  }

  /// Official YOLO detection callback.
  /// Handles MULTI-MONEY detection per frame without discarding duplicates.
  void _onYoloResult(List<YOLOResult> results) {
    if (!mounted || !_isScanningActive) return;

    // Rate-limit state update to ~15-20 FPS for UI performance
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastResultProcessedTime < 60) return;
    _lastResultProcessedTime = now;

    // CRITICAL: Process ALL valid detections individually.
    // Do NOT take results.first.
    final List<MoneyDetection> validDetections = [];

    for (final result in results) {
      if (result.confidence < _confidenceThreshold) continue;

      final info = RiyalCurrencyHelper.getInfo(result.className);
      if (info == null) {
        // Unknown class, fallback safely
        validDetections.add(
          MoneyDetection(
            className: result.className,
            displayName: result.className,
            spokenName: result.className,
            amount: 0.0,
            confidence: result.confidence,
            box: result.boundingBox,
            normalizedBox: result.normalizedBox,
            isCoin: false,
          ),
        );
        continue;
      }

      validDetections.add(
        MoneyDetection(
          className: result.className,
          displayName: info.displayName,
          spokenName: info.spokenName,
          amount: info.amount,
          confidence: result.confidence,
          box: result.boundingBox,
          normalizedBox: result.normalizedBox,
          isCoin: info.isCoin,
        ),
      );
    }

    // Calculate total from ALL detected money (including duplicate denominations)
    final double calculatedTotal = validDetections.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    setState(() {
      _activeDetections = validDetections;
      _totalAmount = calculatedTotal;
    });

    // Pass all valid detections to multi-money TTS service
    if (validDetections.isNotEmpty) {
      _ttsService.processDetections(validDetections);
    }
  }

  void _onModelLoaded(String path, YOLOTask? task) {
    debugPrint('Ultralytics YOLO model loaded successfully: $path ($task)');
    if (mounted) {
      setState(() {
        _isModelLoaded = true;
        _modelError = null;
      });
    }
  }

  void _onModelError(Object error, String path, YOLOTask? task) {
    debugPrint('Ultralytics YOLO model error: $error on path $path');
    if (mounted) {
      setState(() {
        _modelError = 'Model deteksi gagal dimuat: $error';
        _isModelLoaded = false;
      });
    }
  }

  Future<void> _toggleTorch() async {
    try {
      HapticFeedback.lightImpact();
      await _yoloController.toggleTorch();
      if (mounted) {
        setState(() {
          _isTorchOn = _yoloController.isTorchEnabled;
        });
      }
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      HapticFeedback.selectionClick();
      await _yoloController.switchCamera();
      if (mounted) {
        setState(() {
          _currentLens = _currentLens == LensFacing.back
              ? LensFacing.front
              : LensFacing.back;
          _isTorchOn = false;
        });
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  Future<void> _toggleScanning() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isScanningActive = !_isScanningActive;
      if (!_isScanningActive) {
        _activeDetections.clear();
        _totalAmount = 0.0;
        _ttsService.stop();
      }
    });

    if (_isScanningActive) {
      await _yoloController.resume();
    } else {
      await _yoloController.pause();
    }
  }

  void _handleTapToFocus(TapDownDetails details, BoxConstraints constraints) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = details.localPosition;
    final normX = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final normY = (local.dy / constraints.maxHeight).clamp(0.0, 1.0);

    HapticFeedback.selectionClick();
    _yoloController.tapToFocus(normX, normY);

    setState(() {
      _focusPoint = local;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _focusPoint == local) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera preview with YOLOView
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleTapToFocus(details, constraints),
                child: _buildCameraLayer(),
              );
            },
          ),

          // 2. Visual Viewfinder Frame Guide
          _buildViewfinderGuide(),

          // 3. Tap to Focus Indicator
          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 32,
              top: _focusPoint!.dy - 32,
              child: _buildFocusIndicator(),
            ),

          // 4. Top Navigation & Status Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),

          // 5. Bottom Accessible Multi-Money Result Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),

          // 6. Loading or Error Overlay
          if (!_isModelLoaded && _modelError == null) _buildLoadingOverlay(),
          if (_modelError != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    return YOLOView(
      modelPath: _modelAssetPath,
      task: YOLOTask.detect,
      controller: _yoloController,
      lensFacing: _currentLens,
      cameraResolution: '720p',
      confidenceThreshold: _confidenceThreshold,
      iouThreshold: 0.5,
      useGpu: true,
      streamingConfig: YOLOStreamingConfig.throttled(
        maxFPS: 20,
        includeDetections: true,
        includeClassifications: false,
        includeFps: false,
        includeProcessingTimeMs: false,
      ),
      onResult: _onYoloResult,
      onModelLoad: _onModelLoaded,
      onModelError: _onModelError,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenEdgeGutter,
        topPadding + AppSpacing.sm,
        AppSpacing.screenEdgeGutter,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.40),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Accessible Back Button
          Semantics(
            label: 'Kembali',
            button: true,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                iconSize: 24,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Kembali',
                onPressed: () {
                  _ttsService.stop();
                  Get.back();
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title & Live Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pindai Uang Riyal',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isScanningActive
                              ? AppColors.statusSafe
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isScanningActive ? 'Kamera Aktif' : 'Deteksi Dijeda',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Flashlight / Torch Button
          Semantics(
            label: _isTorchOn ? 'Matikan Senter' : 'Nyalakan Senter',
            button: true,
            child: Material(
              color: _isTorchOn
                  ? AppColors.accentGoldStar.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                iconSize: 22,
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? AppColors.primary : Colors.white,
                ),
                tooltip: _isTorchOn ? 'Matikan Senter' : 'Nyalakan Senter',
                onPressed: _toggleTorch,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Switch Camera Button
          Semantics(
            label: 'Ganti Kamera',
            button: true,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                iconSize: 22,
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                tooltip: 'Ganti Kamera',
                onPressed: _switchCamera,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderGuide() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 120),
          width: 310,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _activeDetections.isNotEmpty
                  ? AppColors.goldLight.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              _cornerMarker(Alignment.topLeft),
              _cornerMarker(Alignment.topRight),
              _cornerMarker(Alignment.bottomLeft),
              _cornerMarker(Alignment.bottomRight),
              if (_activeDetections.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Arahkan uang ke sini',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cornerMarker(Alignment alignment) {
    const double size = 20.0;
    const double thickness = 3.5;
    final color = _activeDetections.isNotEmpty
        ? AppColors.goldLight
        : Colors.white.withValues(alpha: 0.9);

    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: color, width: thickness)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: color, width: thickness)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: color, width: thickness)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: color, width: thickness)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFocusIndicator() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.goldLight, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.filter_center_focus, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final bool hasDetections = _activeDetections.isNotEmpty;
    final int count = _activeDetections.length;
    final formattedTotal = RiyalCurrencyHelper.formatAmount(_totalAmount);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdgeGutter,
            AppSpacing.md,
            AppSpacing.screenEdgeGutter,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle / Indicator bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              // Status & Count Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasDetections
                            ? Icons.monetization_on
                            : Icons.search_rounded,
                        color: hasDetections
                            ? AppColors.goldLight
                            : Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        hasDetections
                            ? '$count Uang Terdeteksi'
                            : 'Letakkan uang di dalam area kamera',
                        style: AppTypography.titleMedium.copyWith(
                          color: hasDetections
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (hasDetections)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldLight.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '$count item',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Multi-money Scrollable Breakdown List
              if (hasDetections)
                Container(
                  constraints: const BoxConstraints(maxHeight: 125),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    shrinkWrap: true,
                    itemCount: _activeDetections.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white10,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = _activeDetections[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Text(
                              item.isCoin ? '🪙' : '💵',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                item.displayName,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                '${item.confidencePercentage}%',
                                style: AppTypography.captionSmall.copyWith(
                                  color: item.confidence >= 0.8
                                      ? AppColors.statusSafe
                                      : AppColors.goldLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),

              // Hero Total Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.cardPadding,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL NOMINAL',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.goldLight,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasDetections ? formattedTotal : '0 Riyal',
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (hasDetections)
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.goldLight,
                          size: 28,
                        ),
                        tooltip: 'Bacakan Total',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _ttsService.speak(
                            'Total ${RiyalCurrencyHelper.totalToSpokenIndonesian(_totalAmount)}',
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Bottom Actions: Voice Toggle & Pause/Resume
              Row(
                children: [
                  // Voice Toggle
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: _ttsService.isVoiceEnabled
                              ? AppColors.goldLight
                              : Colors.white24,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _ttsService.isVoiceEnabled =
                              !_ttsService.isVoiceEnabled;
                          if (!_ttsService.isVoiceEnabled) {
                            _ttsService.stop();
                          }
                        });
                      },
                      icon: Icon(
                        _ttsService.isVoiceEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: _ttsService.isVoiceEnabled
                            ? AppColors.goldLight
                            : Colors.white54,
                        size: 20,
                      ),
                      label: Text(
                        _ttsService.isVoiceEnabled ? 'Suara ON' : 'Suara OFF',
                        style: AppTypography.labelLarge.copyWith(
                          color: _ttsService.isVoiceEnabled
                              ? Colors.white
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Pause / Resume Detection Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isScanningActive
                            ? AppColors.statusWarning
                            : AppColors.statusSafe,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: _toggleScanning,
                      icon: Icon(
                        _isScanningActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 20,
                      ),
                      label: Text(
                        _isScanningActive ? 'Jeda Pindai' : 'Mulai Pindai',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.goldLight,
              strokeWidth: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Memuat model deteksi...',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Menyiapkan kamera kecerdasan buatan',
              style: AppTypography.caption.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.statusDanger,
              size: 54,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gagal Memuat Deteksi',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _modelError ?? 'Model deteksi gagal dimuat',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldLight,
                foregroundColor: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  _modelError = null;
                  _isModelLoaded = false;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Kembali ke Menu',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
