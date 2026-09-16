import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/money_detection.dart';
import '../services/money_tts_service.dart';
import '../services/riyal_currency_helper.dart';
import '../services/smart_multi_pass_detector.dart';

/// State modes for photo-based money recognition.
enum RecognitionMode {
  camera,
  processing,
  result,
}

class MoneyRecognitionScreen extends StatefulWidget {
  const MoneyRecognitionScreen({super.key});

  @override
  State<MoneyRecognitionScreen> createState() => _MoneyRecognitionScreenState();
}

class _MoneyRecognitionScreenState extends State<MoneyRecognitionScreen> {
  // Official Ultralytics Controller for Camera Preview
  final YOLOViewController _yoloController = YOLOViewController();

  // Single-image YOLO inference instance
  late final YOLO _yolo;

  // Smart Multi-Pass Engine
  late final SmartMultiPassDetector _multiPassDetector;

  // Indonesian TTS Service
  final MoneyTtsService _ttsService = MoneyTtsService();

  // Model Asset Configuration
  static const String _modelAssetPath = 'assets/models/best_float16.tflite';

  // ---------------------------------------------------------------------------
  // TUNABLE PIPELINE CONFIGURATION
  // ---------------------------------------------------------------------------
  static const double _finalConfidenceThreshold = 0.65;
  static const double _candidateConfidenceThreshold = 0.50;
  static const double _crossPassIoUThreshold = 0.50;
  static const int _maxAdditionalPasses = 2;

  // UX State Machine
  RecognitionMode _mode = RecognitionMode.camera;
  String _processingStatus = 'Memeriksa foto...';

  // Camera & Model State
  bool _isModelLoaded = false;
  String? _modelError;
  bool _isTorchOn = false;
  LensFacing _currentLens = LensFacing.back;
  Offset? _focusPoint;

  // Captured Photo & Inference Results
  Uint8List? _capturedImageBytes;
  Size? _capturedImageSize;
  List<MoneyDetection> _capturedDetections = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _ttsService.init();
    try {
      _yolo = YOLO(
        modelPath: _modelAssetPath,
        task: YOLOTask.detect,
      );
      final loaded = await _yolo.loadModel();

      _multiPassDetector = SmartMultiPassDetector(
        yolo: _yolo,
        config: const MultiPassConfig(
          finalConfidenceThreshold: _finalConfidenceThreshold,
          candidateConfidenceThreshold: _candidateConfidenceThreshold,
          crossPassIoUThreshold: _crossPassIoUThreshold,
          maxAdditionalPasses: _maxAdditionalPasses,
        ),
      );

      if (mounted) {
        setState(() {
          _isModelLoaded = loaded;
        });
      }
    } catch (e) {
      debugPrint('Failed to load YOLO model: $e');
      if (mounted) {
        setState(() {
          _modelError = 'Gagal memuat model deteksi: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _yoloController.dispose();
    _yolo.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PHOTO CAPTURE & SMART MULTI-PASS INFERENCE WORKFLOW
  // ---------------------------------------------------------------------------

  Future<void> _captureAndAnalyze() async {
    if (_mode != RecognitionMode.camera) return;

    if (!_isModelLoaded) {
      Get.snackbar(
        'Menyiapkan Kamera',
        'Model deteksi sedang disiapkan, silakan coba sesaat lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppSpacing.md),
      );
      return;
    }

    setState(() {
      _mode = RecognitionMode.processing;
      _processingStatus = 'Memeriksa foto uang...';
    });

    try {
      // 1. Capture still photo from live preview
      Uint8List? photoBytes;
      try {
        photoBytes = await _yoloController.capturePhoto(withOverlays: false);
      } catch (e) {
        debugPrint('capturePhoto error: $e');
      }

      if (photoBytes == null || photoBytes.isEmpty) {
        try {
          photoBytes = await _yoloController.captureFrame();
        } catch (e) {
          debugPrint('captureFrame error: $e');
        }
      }

      if (photoBytes == null || photoBytes.isEmpty) {
        throw Exception('Gagal mengambil gambar dari kamera.');
      }

      // 2. Pause live camera preview while examining result
      await _yoloController.pause();

      // 3. Decode image dimensions to ensure pixel-perfect bounding box alignment
      final ui.Image decodedImage = await decodeImageFromList(photoBytes);
      final Size imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );

      // 4. Run Smart Multi-Pass Pipeline (Pass 1 Baseline -> Pass 2 Enhanced -> Pass 3 Tiled -> IoU Merge)
      final MultiPassDetectionResult result =
          await _multiPassDetector.processImage(
        photoBytes,
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              _processingStatus = status;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _capturedImageBytes = photoBytes;
        _capturedImageSize = imageSize;
        _capturedDetections = result.finalDetections;
        _totalAmount = result.totalAmount;
        _mode = RecognitionMode.result;
      });

      // 5. Speak announcement once in Indonesian
      await _ttsService.speakResults(result.finalDetections, result.totalAmount);
    } catch (e) {
      debugPrint('Capture & inference pipeline error: $e');
      if (!mounted) return;

      setState(() {
        _mode = RecognitionMode.camera;
      });

      Get.snackbar(
        'Gagal Memindai',
        'Terjadi kesalahan saat memproses gambar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppSpacing.md),
      );

      try {
        await _yoloController.resume();
      } catch (_) {}
    }
  }

  Future<void> _retakePhoto() async {
    _ttsService.stop();
    setState(() {
      _mode = RecognitionMode.camera;
      _capturedImageBytes = null;
      _capturedImageSize = null;
      _capturedDetections = [];
      _totalAmount = 0.0;
    });

    try {
      await _yoloController.resume();
    } catch (e) {
      debugPrint('Failed to resume YOLOView: $e');
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _yoloController.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _yoloController.switchCamera();
      setState(() {
        _currentLens = _currentLens == LensFacing.back
            ? LensFacing.front
            : LensFacing.back;
        _isTorchOn = false;
      });
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  void _onTapToFocus(TapDownDetails details) {
    if (_mode != RecognitionMode.camera) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = details.localPosition;
    final normalizedX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / box.size.height).clamp(0.0, 1.0);

    _yoloController.tapToFocus(normalizedX, normalizedY);

    setState(() {
      _focusPoint = localPosition;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _focusPoint == localPosition) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD ROUTING
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Primary View Layer based on RecognitionMode
          if (_mode == RecognitionMode.result && _capturedImageBytes != null)
            _buildResultView()
          else
            _buildCameraView(),

          // 2. Processing Loading Overlay with dynamic pass status
          if (_mode == RecognitionMode.processing)
            _buildProcessingOverlay(),

          // 3. Error Overlay if model failed to load
          if (_modelError != null && _mode == RecognitionMode.camera)
            _buildErrorOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CAMERA MODE WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildCameraView() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapToFocus,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Native YOLOView camera preview
          YOLOView(
            modelPath: _modelAssetPath,
            task: YOLOTask.detect,
            controller: _yoloController,
            lensFacing: _currentLens,
            confidenceThreshold: _candidateConfidenceThreshold,
            onModelLoad: (path, task) {
              _yoloController.setShowOverlays(false);
              if (mounted) {
                setState(() => _isModelLoaded = true);
              }
            },
            onModelError: (error, path, task) {
              if (mounted) {
                setState(() => _modelError = error.toString());
              }
            },
          ),

          // Tap to focus reticle indicator
          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 32,
              top: _focusPoint!.dy - 32,
              child: _buildFocusIndicator(),
            ),

          // Viewfinder guide overlay
          _buildViewfinderGuide(),

          // Top action bar
          _buildCameraTopBar(),

          // Bottom shutter & instruction bar
          _buildCameraBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCameraTopBar() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
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
              Colors.black.withValues(alpha: 0.88),
              Colors.black.withValues(alpha: 0.40),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back Button
            Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Get.back(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Screen Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Deteksi Uang Riyal',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Arahkan kamera & tekan tombol foto',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.canvasCream.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Sound Toggle (Large touch target)
            Material(
              color: _ttsService.isVoiceEnabled
                  ? AppColors.goldPrimary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.55),
              shape: CircleBorder(
                side: BorderSide(
                  color: _ttsService.isVoiceEnabled
                      ? AppColors.goldPrimary
                      : Colors.white24,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _ttsService.isVoiceEnabled = !_ttsService.isVoiceEnabled;
                  });
                },
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    _ttsService.isVoiceEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: _ttsService.isVoiceEnabled
                        ? AppColors.goldPrimary
                        : Colors.white60,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Torch Toggle
            Material(
              color: _isTorchOn
                  ? AppColors.goldPrimary
                  : Colors.black.withValues(alpha: 0.55),
              shape: CircleBorder(
                side: BorderSide(
                  color: _isTorchOn ? AppColors.goldPrimary : Colors.white24,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _toggleTorch,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isTorchOn ? AppColors.espressoDark : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Switch Camera
            Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white24, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _switchCamera,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.flip_camera_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinderGuide() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 90),
          width: 320,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              _cornerMarker(Alignment.topLeft),
              _cornerMarker(Alignment.topRight),
              _cornerMarker(Alignment.bottomLeft),
              _cornerMarker(Alignment.bottomRight),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.goldPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Arahkan uang ke area ini',
                        style: AppTypography.captionSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
    const double size = 26.0;
    const double thickness = 3.5;
    const color = AppColors.goldPrimary;

    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: color, width: thickness)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: color, width: thickness)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: color, width: thickness)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: color, width: thickness)
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
        border: Border.all(color: AppColors.goldPrimary, width: 2),
      ),
      child: const Center(
        child: Icon(
          Icons.filter_center_focus_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCameraBottomBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenEdgeGutter,
          AppSpacing.lg,
          AppSpacing.screenEdgeGutter,
          bottomPadding + AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.60),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instruction
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Letakkan lembaran uang SAR, lalu tekan tombol foto di bawah',
                textAlign: TextAlign.center,
                style: AppTypography.captionSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Large Shutter Button for Elderly Usability
            Semantics(
              label: 'Ambil Foto Uang Riyal',
              button: true,
              child: GestureDetector(
                onTap: _captureAndAnalyze,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldPrimary,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.espressoDark,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Pindai Uang',
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PROCESSING OVERLAY
  // ---------------------------------------------------------------------------

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.espressoDark, Color(0xFF22160E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.goldPrimary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  color: AppColors.goldPrimary,
                  strokeWidth: 3.8,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Menganalisis Uang...',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _processingStatus,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.canvasCream.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. RESULT VIEW
  // ---------------------------------------------------------------------------

  Widget _buildResultView() {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool hasDetections = _capturedDetections.isNotEmpty;

    final double aspectRatio = (_capturedImageSize != null &&
            _capturedImageSize!.height > 0)
        ? (_capturedImageSize!.width / _capturedImageSize!.height)
        : (3 / 4);

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          // Top Navigation Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenEdgeGutter,
              topPadding + AppSpacing.sm,
              AppSpacing.screenEdgeGutter,
              AppSpacing.sm2,
            ),
            color: AppColors.espressoDark,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  tooltip: 'Foto Ulang',
                  onPressed: _retakePhoto,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Hasil Deteksi Riyal',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Speaker Button to repeat TTS
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.goldPrimary,
                    ),
                    tooltip: 'Bacakan Ulang',
                    onPressed: () {
                      _ttsService.speakResults(
                        _capturedDetections,
                        _totalAmount,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenEdgeGutter,
                AppSpacing.md,
                AppSpacing.screenEdgeGutter,
                bottomPadding + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Captured Photo with Bounding Boxes
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            _capturedImageBytes!,
                            fit: BoxFit.fill,
                          ),
                          CustomPaint(
                            painter: MoneyBoundingBoxPainter(
                              detections: _capturedDetections,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Detection Status Header
                  if (hasDetections)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusPositive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.statusPositive.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.statusPositive,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${_capturedDetections.length} Lembar/Koin Terdeteksi',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.statusPositive,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.distanceWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.distanceWarning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.distanceWarning,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Belum Ada Uang Terdeteksi',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.distanceWarning,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pastikan pencahayaan cukup dan uang tidak terlipat, lalu coba foto lagi.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // List of Individual Detections
                  if (hasDetections) ...[
                    Text(
                      'Rincian Pecahan',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_capturedDetections.length, (index) {
                      final item = _capturedDetections[index];
                      final color = MoneyBoundingBoxPainter.getDenominationColor(
                        item.amount,
                        item.isCoin,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayName,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${item.isCoin ? "Uang Logam" : "Uang Kertas"} • Akurasi ${item.confidencePercentage}%',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.isCoin
                                  ? '${item.amount.toStringAsFixed(2)} SAR'
                                  : '${item.amount.toInt()} SAR',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.goldPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // TOTAL NOMINAL CARD (Islamic Luxury Aesthetic)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.espressoDark,
                          Color(0xFF22160E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: AppColors.goldPrimary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: AppColors.goldPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TOTAL NOMINAL RIYAL',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.goldPrimary,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          RiyalCurrencyHelper.formatAmount(_totalAmount),
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Terbilang: ${RiyalCurrencyHelper.totalToSpokenIndonesian(_totalAmount)}',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.canvasCream.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ACTION BUTTONS (54px height for elderly)
                  Row(
                    children: [
                      // Replay Voice Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.goldPrimary,
                                width: 1.5,
                              ),
                              foregroundColor: AppColors.goldPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                            onPressed: () {
                              _ttsService.speakResults(
                                _capturedDetections,
                                _totalAmount,
                              );
                            },
                            icon: const Icon(
                              Icons.volume_up_rounded,
                              size: 22,
                            ),
                            label: Text(
                              'Bacakan Suara',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.goldPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Retake Photo Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldPrimary,
                              foregroundColor: AppColors.espressoDark,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                            onPressed: _retakePhoto,
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              size: 22,
                              color: AppColors.espressoDark,
                            ),
                            label: Text(
                              'Pindai Lagi',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.espressoDark,
                                fontWeight: FontWeight.w800,
                              ),
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. ERROR OVERLAY
  // ---------------------------------------------------------------------------

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.sosEmergency,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gagal Memuat Model',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _modelError ?? 'Model deteksi gagal dimuat',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: AppColors.espressoDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _modelError = null;
                    _isModelLoaded = false;
                  });
                  _initServices();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Coba Lagi',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.espressoDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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

// =============================================================================
// BOUNDING BOX PAINTER FOR RESULT PHOTO
// =============================================================================

class MoneyBoundingBoxPainter extends CustomPainter {
  final List<MoneyDetection> detections;

  const MoneyBoundingBoxPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || detections.isEmpty) return;

    for (final detection in detections) {
      final norm = detection.normalizedBox;
      final left = (norm.left * size.width).clamp(0.0, size.width);
      final top = (norm.top * size.height).clamp(0.0, size.height);
      final right = (norm.right * size.width).clamp(0.0, size.width);
      final bottom = (norm.bottom * size.height).clamp(0.0, size.height);

      if (right <= left || bottom <= top) continue;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      final color = getDenominationColor(detection.amount, detection.isCoin);

      // 1. Semi-transparent fill inside box
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);

      // 2. High-contrast border
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8;
      canvas.drawRRect(rrect, strokePaint);

      // 3. Denomination Badge
      final badgeText =
          '${detection.displayName.toUpperCase()} (${detection.confidencePercentage}%)';
      final textSpan = TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      const paddingH = 7.0;
      const paddingV = 3.5;
      final badgeWidth = textPainter.width + (paddingH * 2);
      final badgeHeight = textPainter.height + (paddingV * 2);

      double badgeLeft = left;
      double badgeTop = top - badgeHeight;
      if (badgeTop < 0) {
        badgeTop = top;
      }
      if (badgeLeft + badgeWidth > size.width) {
        badgeLeft = size.width - badgeWidth;
      }

      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
        const Radius.circular(6),
      );

      final badgeBgPaint = Paint()
        ..color = color.withValues(alpha: 0.92)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(badgeRRect, badgeBgPaint);

      textPainter.paint(
        canvas,
        Offset(badgeLeft + paddingH, badgeTop + paddingV),
      );
    }
  }

  static Color getDenominationColor(double amount, bool isCoin) {
    if (isCoin) return const Color(0xFFF59E0B); // Amber / coin
    if (amount >= 500) return const Color(0xFF9333EA); // Purple (500 SAR)
    if (amount >= 200) return const Color(0xFF8D6E63); // Brown (200 SAR)
    if (amount >= 100) return const Color(0xFFE11D48); // Red / Crimson (100 SAR)
    if (amount >= 50) return const Color(0xFF16A34A); // Green (50 SAR)
    if (amount >= 20) return const Color(0xFFEA580C); // Deep orange (20 SAR)
    if (amount >= 10) return const Color(0xFFD97706); // Amber (10 SAR)
    if (amount >= 5) return const Color(0xFF0D9488); // Teal / Emerald (5 SAR)
    return const Color(0xFF78716C); // Stone / Tan (1 & 2 SAR)
  }

  @override
  bool shouldRepaint(covariant MoneyBoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
