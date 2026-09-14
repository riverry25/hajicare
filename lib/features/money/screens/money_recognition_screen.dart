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

  // Indonesian TTS Service
  final MoneyTtsService _ttsService = MoneyTtsService();

  // Model Asset Configuration
  static const String _modelAssetPath = 'assets/models/best_float16.tflite';

  // UX State Machine
  RecognitionMode _mode = RecognitionMode.camera;

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

  // Confidence threshold for valid detections (critical requirement >= 0.65)
  final double _confidenceThreshold = 0.65;

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
  // PHOTO CAPTURE & SINGLE-IMAGE INFERENCE WORKFLOW
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

      // 4. Run single-image inference using official YOLO API
      final Map<String, dynamic> inferenceResult = await _yolo.predict(
        photoBytes,
        confidenceThreshold: _confidenceThreshold,
      );

      // 5. Extract all detections without discarding duplicates
      final rawDetections = (inferenceResult['detections'] as List?)
              ?.map((d) => YOLOResult.fromMap(d as Map))
              .toList() ??
          [];

      final List<MoneyDetection> validList = [];
      for (final res in rawDetections) {
        // Strict confidence filtering
        if (res.confidence < _confidenceThreshold) continue;

        final info = RiyalCurrencyHelper.getInfo(res.className);
        if (info == null) continue;

        validList.add(MoneyDetection(
          className: res.className,
          displayName: info.displayName,
          spokenName: info.spokenName,
          amount: info.amount,
          confidence: res.confidence,
          box: res.boundingBox,
          normalizedBox: res.normalizedBox,
          isCoin: info.isCoin,
        ));
      }

      // 6. Calculate total nominal of all detected physical objects
      final double total = validList.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );

      if (!mounted) return;

      setState(() {
        _capturedImageBytes = photoBytes;
        _capturedImageSize = imageSize;
        _capturedDetections = validList;
        _totalAmount = total;
        _mode = RecognitionMode.result;
      });

      // 7. Speak announcement once in Indonesian
      await _ttsService.speakResults(validList, total);
    } catch (e) {
      debugPrint('Capture and analyze failed: $e');
      if (!mounted) return;

      Get.snackbar(
        'Gagal Memproses Foto',
        'Terjadi kesalahan saat memproses foto. Silakan coba kembali.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.md,
      );

      await _yoloController.resume();
      setState(() {
        _mode = RecognitionMode.camera;
      });
    }
  }

  /// Returns to camera preview mode to capture a new photo.
  Future<void> _retakePhoto() async {
    await _ttsService.stop();
    await _yoloController.resume();
    if (!mounted) return;
    setState(() {
      _mode = RecognitionMode.camera;
      _capturedImageBytes = null;
      _capturedImageSize = null;
      _capturedDetections = [];
      _totalAmount = 0.0;
    });
  }

  // ---------------------------------------------------------------------------
  // CAMERA CONTROLS
  // ---------------------------------------------------------------------------

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

          // 2. Processing Loading Overlay
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
          // Native YOLOView camera preview (no realtime onResult callback)
          YOLOView(
            modelPath: _modelAssetPath,
            task: YOLOTask.detect,
            controller: _yoloController,
            lensFacing: _currentLens,
            confidenceThreshold: _confidenceThreshold,
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
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.35),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back Button
            Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Kembali',
                onPressed: () => Get.back(),
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
                    'Pindai Uang Riyal',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Arahkan kamera & ambil foto',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Sound Toggle
            Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: Icon(
                  _ttsService.isVoiceEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: _ttsService.isVoiceEnabled
                      ? AppColors.goldLight
                      : Colors.white54,
                ),
                tooltip: _ttsService.isVoiceEnabled
                    ? 'Matikan Suara'
                    : 'Aktifkan Suara',
                onPressed: () {
                  setState(() {
                    _ttsService.isVoiceEnabled = !_ttsService.isVoiceEnabled;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Torch Toggle
            Material(
              color: _isTorchOn
                  ? AppColors.accentGoldStar.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? AppColors.primary : Colors.white,
                ),
                tooltip: _isTorchOn ? 'Matikan Senter' : 'Nyalakan Senter',
                onPressed: _toggleTorch,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Switch Camera
            Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                tooltip: 'Ganti Kamera',
                onPressed: _switchCamera,
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
          margin: const EdgeInsets.only(bottom: 80),
          width: 320,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
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
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Arahkan uang ke area ini',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
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
    const double size = 22.0;
    const double thickness = 3.5;
    const color = AppColors.goldLight;

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
        border: Border.all(color: AppColors.goldLight, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.filter_center_focus, color: Colors.white, size: 28),
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
              Colors.black.withValues(alpha: 0.90),
              Colors.black.withValues(alpha: 0.50),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instruction
            Text(
              'Posisikan uang di dalam bingkai, lalu tekan tombol di bawah',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Shutter Button
            Semantics(
              label: 'Ambil Foto Uang',
              button: true,
              child: GestureDetector(
                onTap: _captureAndAnalyze,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldLight,
                      width: 4,
                    ),
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            Text(
              'Ambil Foto',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
      color: Colors.black.withValues(alpha: 0.80),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.goldLight.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  color: AppColors.accentGoldStar,
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Memeriksa Uang...',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sedang menganalisis nominal uang pada foto',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white70,
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

    // Aspect ratio of the captured image
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
              AppSpacing.sm,
            ),
            color: AppColors.primary,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Foto Ulang',
                  onPressed: _retakePhoto,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Hasil Pindai Uang',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Speaker Button to repeat TTS
                IconButton(
                  icon: const Icon(Icons.volume_up, color: AppColors.goldLight),
                  tooltip: 'Bacakan Ulang',
                  onPressed: () {
                    _ttsService.speakResults(
                      _capturedDetections,
                      _totalAmount,
                    );
                  },
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
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
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
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusSafe.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.statusSafe.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.statusSafe,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${_capturedDetections.length} Uang Terdeteksi',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.statusSafe,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.statusWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.statusWarning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.statusWarning,
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
                                    color: AppColors.statusWarning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pastikan uang terlihat jelas dan coba foto lagi.',
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

                  // List of ALL Individual Detections
                  if (hasDetections) ...[
                    Text(
                      'Rincian Uang',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...List.generate(_capturedDetections.length, (index) {
                      final item = _capturedDetections[index];
                      final color = MoneyBoundingBoxPainter.getDenominationColor(
                        item.amount,
                        item.isCoin,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${item.isCoin ? "Uang Logam" : "Uang Kertas"} • Akurasi ${item.confidencePercentage}%',
                                    style: AppTypography.caption.copyWith(
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
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // TOTAL NOMINAL CARD
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryContainer,
                          AppColors.espressoDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.accentGoldStar,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL NOMINAL',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.goldLight,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          RiyalCurrencyHelper.formatAmount(_totalAmount),
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Terbilang: ${RiyalCurrencyHelper.totalToSpokenIndonesian(_totalAmount)}',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      // Replay Voice Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.goldLight),
                            foregroundColor: AppColors.goldLight,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () {
                            _ttsService.speakResults(
                              _capturedDetections,
                              _totalAmount,
                            );
                          },
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Bacakan Hasil'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Retake Photo Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGoldStar,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: _retakePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text(
                            'Foto Ulang',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
              'Gagal Memuat Model',
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
                _initServices();
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
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
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
        ..strokeWidth = 2.5;
      canvas.drawRRect(rrect, strokePaint);

      // 3. Denomination Badge
      final badgeText =
          '${detection.displayName.toUpperCase()} (${detection.confidencePercentage}%)';
      final textSpan = TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      const paddingH = 6.0;
      const paddingV = 3.0;
      final badgeWidth = textPainter.width + (paddingH * 2);
      final badgeHeight = textPainter.height + (paddingV * 2);

      // Place badge at top-left of box (shift down if box touches top border)
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
        const Radius.circular(4),
      );

      final badgeBgPaint = Paint()
        ..color = color.withValues(alpha: 0.90)
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
