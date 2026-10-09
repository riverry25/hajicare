import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../models/currency_code.dart';
import '../models/money_detection.dart';
import '../services/currency_rate_service.dart';
import '../services/money_aggregator.dart';
import '../services/money_currency_helper.dart';
import '../services/money_tts_service.dart';
import '../services/smart_multi_pass_detector.dart';

/// State modes for photo-based money recognition.
enum RecognitionMode { camera, processing, result }

class MoneyRecognitionScreen extends StatefulWidget {
  final ImagePicker? imagePicker;

  const MoneyRecognitionScreen({super.key, this.imagePicker});

  @override
  State<MoneyRecognitionScreen> createState() => _MoneyRecognitionScreenState();
}

class _MoneyRecognitionScreenState extends State<MoneyRecognitionScreen> {
  // Official Ultralytics Controller for Camera Preview
  final YOLOViewController _yoloController = YOLOViewController();

  // Image picker instance for gallery photo selection
  ImagePicker? _imagePicker;

  // Single-image YOLO inference instance
  late final YOLO _yolo;

  // Smart Multi-Pass Engine
  late final SmartMultiPassDetector _multiPassDetector;

  // Indonesian TTS Service
  final MoneyTtsService _ttsService = MoneyTtsService();

  // Active SAR to IDR exchange rate (default 1 SAR ≈ Rp 4,750)
  double _exchangeRate = CurrencyRateService.defaultRate;

  // Multi-Currency Model Asset Configuration (SAR, IDR, USD)
  static const String _modelAssetPath =
      'assets/models/money_recognition.tflite';

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
  Map<CurrencyCode, double> _totalsByCurrency = {};
  CurrencyCode _conversionTarget = CurrencyCode.idr;
  double _convertedGrandTotal = 0.0;
  bool _isConversionAvailable = true;

  @override
  void initState() {
    super.initState();
    CurrencyRateService.instance.rateNotifier.addListener(_onRateChanged);
    _initServices();
  }

  void _onRateChanged() {
    if (mounted) {
      setState(() {
        _exchangeRate = CurrencyRateService.instance.currentRate;
        _recalculateConversions();
      });
    }
  }

  Future<void> _initServices() async {
    await _ttsService.init();
    await CurrencyRateService.instance.init();
    if (mounted) {
      setState(() {
        _exchangeRate = CurrencyRateService.instance.currentRate;
      });
    }
    try {
      _yolo = YOLO(modelPath: _modelAssetPath, task: YOLOTask.detect);
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

      if (loaded) {
        AppLogger.info(
          'Multi-currency model ready ($_modelAssetPath)',
          tag: 'MoneyAI',
        );
      }

      if (mounted) {
        setState(() {
          _isModelLoaded = loaded;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load YOLO model: $e', tag: 'MoneyAI');
      if (mounted) {
        setState(() {
          _modelError =
              'Pemindai uang belum siap. Tutup lalu buka kembali halaman ini.';
        });
      }
    }
  }

  void _recalculateConversions() {
    try {
      _convertedGrandTotal = MoneyAggregator.grandTotalIn(
        totals: _totalsByCurrency,
        targetCurrency: _conversionTarget,
        conversionService: CurrencyRateService.instance,
      );
      _isConversionAvailable = true;
    } catch (e) {
      debugPrint('[MoneyFX] Recalculate error: $e');
      _isConversionAvailable = false;
    }
  }

  @override
  void dispose() {
    CurrencyRateService.instance.rateNotifier.removeListener(_onRateChanged);
    _ttsService.dispose();
    _yoloController.dispose();
    _yolo.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PHOTO CAPTURE & SMART MULTI-PASS INFERENCE WORKFLOW
  // ---------------------------------------------------------------------------

  /// Unified multi-pass image analysis for both camera shots and gallery photos.
  Future<void> _analyzeImageBytes(
    Uint8List photoBytes, {
    String failureMessage =
        'Uang belum dapat dikenali. Pastikan gambar terang dan tidak buram, lalu coba lagi.',
  }) async {
    setState(() {
      _mode = RecognitionMode.processing;
      _processingStatus = 'Memeriksa foto uang...';
    });

    try {
      // 1. Pause live camera preview while examining result
      try {
        await _yoloController.pause();
      } catch (e) {
        debugPrint('[MoneyAI] pause error: $e');
      }

      // 2. Decode image dimensions to ensure pixel-perfect bounding box alignment
      final ui.Image decodedImage = await decodeImageFromList(photoBytes);
      final Size imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );

      // 3. Run Smart Multi-Pass Pipeline
      final MultiPassDetectionResult result = await _multiPassDetector
          .processImage(
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

      _capturedImageBytes = photoBytes;
      _capturedImageSize = imageSize;
      _capturedDetections = result.finalDetections;
      _totalsByCurrency = result.totalsByCurrency;
      _recalculateConversions();

      setState(() {
        _mode = RecognitionMode.result;
      });

      // 4. Speak accessible result once (isolated try/catch so speech failure never breaks UI)
      try {
        final speech = _ttsService.buildSpeechSentence(
          detections: result.finalDetections,
          totalsByCurrency: result.totalsByCurrency,
          targetCurrency: _conversionTarget,
          conversionService: CurrencyRateService.instance,
          isConversionAvailable: _isConversionAvailable,
        );
        await _ttsService.speak(speech);
      } catch (e) {
        debugPrint('[MoneyTTS] Speech error: $e');
      }
    } catch (e) {
      debugPrint('[MoneyAI] Inference pipeline error: $e');
      if (!mounted) return;

      setState(() {
        _mode = RecognitionMode.camera;
      });

      Get.snackbar(
        'Uang Belum Terbaca',
        failureMessage,
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

  /// Default Option: Ambil foto langsung dari kamera.
  Future<void> _captureAndAnalyze() async {
    if (_mode != RecognitionMode.camera) return;

    if (!_isModelLoaded) {
      Get.snackbar(
        'Menyiapkan Kamera',
        'Pemindai uang sedang disiapkan. Tunggu sebentar, lalu coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppSpacing.md),
      );
      return;
    }

    try {
      // 1. Capture still photo from live preview
      Uint8List? photoBytes;
      try {
        photoBytes = await _yoloController.capturePhoto(withOverlays: false);
      } catch (e) {
        debugPrint('[MoneyAI] capturePhoto error: $e');
      }

      if (photoBytes == null || photoBytes.isEmpty) {
        try {
          photoBytes = await _yoloController.captureFrame();
        } catch (e) {
          debugPrint('[MoneyAI] captureFrame error: $e');
        }
      }

      if (photoBytes == null || photoBytes.isEmpty) {
        throw Exception('Gagal mengambil gambar dari kamera.');
      }

      await _analyzeImageBytes(photoBytes);
    } catch (e) {
      debugPrint('[MoneyAI] Camera capture error: $e');
      if (!mounted) return;

      Get.snackbar(
        'Gagal Mengambil Gambar',
        'Tidak dapat mengambil gambar dari kamera. Silakan coba lagi.',
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

  /// Opsi Tambahan: Ambil foto uang dari galeri perangkat untuk dideteksi.
  Future<void> _pickFromGalleryAndAnalyze() async {
    if (_mode == RecognitionMode.processing) return;

    if (!_isModelLoaded) {
      Get.snackbar(
        'Menyiapkan Pemindai',
        'Pemindai uang sedang disiapkan. Tunggu sebentar, lalu coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppSpacing.md),
      );
      return;
    }

    try {
      final picker = widget.imagePicker ?? (_imagePicker ??= ImagePicker());
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );

      if (pickedFile == null) {
        // Pengguna membatalkan pemilihan foto dari galeri
        return;
      }

      final Uint8List bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('File gambar dari galeri kosong atau tidak terbaca.');
      }

      await _analyzeImageBytes(
        bytes,
        failureMessage:
            'Uang belum dapat dikenali dari foto galeri. Pastikan gambar jelas dan terang, lalu coba lagi.',
      );
    } catch (e) {
      debugPrint('[MoneyAI] Pick gallery error: $e');
      if (!mounted) return;

      Get.snackbar(
        'Gagal Membuka Galeri',
        'Tidak dapat memuat foto dari galeri. Pastikan format gambar didukung.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppSpacing.md),
      );
    }
  }

  Future<void> _retakePhoto() async {
    _ttsService.stop();
    setState(() {
      _mode = RecognitionMode.camera;
      _capturedImageBytes = null;
      _capturedImageSize = null;
      _capturedDetections = [];
      _totalsByCurrency = {};
      _convertedGrandTotal = 0.0;
    });

    try {
      await _yoloController.resume();
    } catch (e) {
      debugPrint('[MoneyAI] Failed to resume YOLOView: $e');
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _yoloController.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      debugPrint('[MoneyAI] Torch error: $e');
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
      debugPrint('[MoneyAI] Switch camera error: $e');
    }
  }

  Future<void> _toggleVoice() async {
    final bool shouldEnableVoice = !_ttsService.isVoiceEnabled;

    setState(() {
      _ttsService.isVoiceEnabled = shouldEnableVoice;
    });

    // Muting must also silence an announcement that is already playing
    if (!shouldEnableVoice) {
      await _ttsService.stop();
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
          if (_mode == RecognitionMode.processing) _buildProcessingOverlay(),

          // 3. Error Overlay if model failed to load
          if (_modelError != null && _mode == RecognitionMode.camera)
            _buildErrorOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CAMERA VIEW & CONTROLS
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
            cameraResolution: '480p',
            streamingConfig: const YOLOStreamingConfig.custom(
              includeDetections: false,
              includeClassifications: false,
              includeProcessingTimeMs: false,
              includeFps: false,
              includeMasks: false,
              includePoses: false,
              includeOBB: false,
              includeOriginalImage: false,
              maxFPS: 1,
              skipFrames: 30,
            ),
            onModelLoad: (path, task) {
              _yoloController.setShowOverlays(false);
              if (mounted) {
                setState(() => _isModelLoaded = true);
              }
            },
            onModelError: (error, path, task) {
              if (mounted) {
                setState(
                  () => _modelError =
                      'Pemindai uang belum siap. Tekan Coba Lagi.',
                );
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
    final sarToIdr = CurrencyRateService.instance.getRate(
      CurrencyCode.sar,
      CurrencyCode.idr,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenEdgeGutter,
          topPadding + AppSpacing.md,
          AppSpacing.screenEdgeGutter,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.72),
              Colors.black.withValues(alpha: 0.26),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pindai Uang',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _showExchangeRateSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.currency_exchange_rounded,
                            size: 13,
                            color: AppColors.goldPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '1 SAR ≈ ${CurrencyFormatter.formatRupiah(sarToIdr)}',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.tune_rounded,
                            size: 12,
                            color: AppColors.goldMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            _buildRoundCameraControl(
              icon: _isTorchOn
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              label: _isTorchOn ? 'Matikan lampu' : 'Nyalakan lampu',
              onTap: _toggleTorch,
              isActive: _isTorchOn,
              size: 44,
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildRoundCameraControl(
              icon: _ttsService.isVoiceEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: _ttsService.isVoiceEnabled
                  ? 'Matikan suara'
                  : 'Aktifkan suara',
              onTap: _toggleVoice,
              isActive: _ttsService.isVoiceEnabled,
              size: 44,
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildRoundCameraControl(
              icon: Icons.close_rounded,
              label: 'Tutup pemindai uang',
              onTap: Get.back,
              size: 44,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundCameraControl({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    double size = 48,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: isActive
            ? AppColors.goldPrimary.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.38),
        shape: CircleBorder(
          side: BorderSide(
            color: isActive
                ? AppColors.goldPrimary.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              color: isActive ? AppColors.goldPrimary : Colors.white,
              size: size * 0.48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinderGuide() {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.84,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                margin: const EdgeInsets.only(bottom: 42),
                child: Stack(
                  children: [
                    _cornerMarker(Alignment.topLeft),
                    _cornerMarker(Alignment.topRight),
                    _cornerMarker(Alignment.bottomLeft),
                    _cornerMarker(Alignment.bottomRight),
                  ],
                ),
              ),
            ),
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
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final bool isCompactHeight = mediaQuery.size.height < 600;
    final double shutterSize = isCompactHeight ? 70 : 82;
    final double sideControlSize = isCompactHeight ? 48 : 54;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenEdgeGutter,
          isCompactHeight ? AppSpacing.lg : AppSpacing.xxxl,
          AppSpacing.screenEdgeGutter,
          bottomPadding + (isCompactHeight ? AppSpacing.sm : AppSpacing.lg),
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
            if (!isCompactHeight) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.center_focus_strong_rounded,
                      size: 14,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Foto langsung lewat kamera atau pilih dari galeri',
                      textAlign: TextAlign.center,
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              'PINDAI UANG',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.goldPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. OPSI: AMBIL DARI GALERI
                  _buildBottomActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    tooltip: 'Pilih foto uang dari galeri',
                    onTap: _pickFromGalleryAndAnalyze,
                    buttonSize: sideControlSize,
                  ),

                  // 2. DEFAULT: AMBIL DARI KAMERA LANGSUNG (SHUTTER BESAR)
                  _buildShutterButton(
                    size: shutterSize,
                    onTap: _captureAndAnalyze,
                  ),

                  // 3. GANTI LENSA KAMERA (DEPAN/BELAKANG)
                  _buildBottomActionButton(
                    icon: Icons.cameraswitch_rounded,
                    label: 'Putar',
                    tooltip: 'Ganti kamera depan atau belakang',
                    onTap: _switchCamera,
                    buttonSize: sideControlSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    required double buttonSize,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: tooltip,
          button: true,
          child: Material(
            color: isActive
                ? AppColors.goldPrimary.withValues(alpha: 0.24)
                : Colors.black.withValues(alpha: 0.38),
            shape: CircleBorder(
              side: BorderSide(
                color: isActive
                    ? AppColors.goldPrimary.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: buttonSize,
                child: Icon(
                  icon,
                  color: isActive ? AppColors.goldPrimary : Colors.white,
                  size: buttonSize * 0.48,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildShutterButton({
    required double size,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Ambil Foto Uang (Kamera Langsung)',
          button: true,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.2),
                color: Colors.black.withValues(alpha: 0.22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldPrimary.withValues(alpha: 0.30),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.espressoDark,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kamera',
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.goldPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
    final Color voiceControlColor = _ttsService.isVoiceEnabled
        ? AppColors.goldPrimary
        : Colors.white38;

    final double aspectRatio =
        (_capturedImageSize != null && _capturedImageSize!.height > 0)
        ? (_capturedImageSize!.width / _capturedImageSize!.height)
        : (3 / 4);

    final sarToIdr = CurrencyRateService.instance.getRate(
      CurrencyCode.sar,
      CurrencyCode.idr,
    );
    final usdToIdr = CurrencyRateService.instance.getRate(
      CurrencyCode.usd,
      CurrencyCode.idr,
    );

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
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Foto Ulang',
                  onPressed: _retakePhoto,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hasil Deteksi Uang',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Kurs: 1 SAR ≈ ${CurrencyFormatter.formatRupiah(sarToIdr)} • 1 USD ≈ ${CurrencyFormatter.formatRupiah(usdToIdr)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.goldLight.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _ttsService.isVoiceEnabled
                          ? AppColors.goldPrimary.withValues(alpha: 0.55)
                          : Colors.white24,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _ttsService.isVoiceEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: _ttsService.isVoiceEnabled
                          ? AppColors.goldPrimary
                          : Colors.white60,
                    ),
                    tooltip: _ttsService.isVoiceEnabled
                        ? 'Matikan suara'
                        : 'Aktifkan suara',
                    onPressed: _toggleVoice,
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
                          Image.memory(_capturedImageBytes!, fit: BoxFit.fill),
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
                          color: AppColors.statusPositive.withValues(
                            alpha: 0.4,
                          ),
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
                            '${_capturedDetections.length} Uang Terdeteksi',
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
                        color: AppColors.distanceWarning.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.distanceWarning.withValues(
                            alpha: 0.4,
                          ),
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
                                  'Pastikan pencahayaan cukup dan uang terlihat jelas, lalu coba foto lagi.',
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
                      final color = MoneyBoundingBoxPainter.getDetectionColor(
                        item,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.7,
                          ),
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
                                    '${item.isCoin ? "Uang Logam" : "Uang Kertas"} • ${item.currency.code} • Akurasi ${item.confidencePercentage}%',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                    item.amount,
                                    item.currency,
                                  ),
                                  style: AppTypography.titleLarge.copyWith(
                                    color: AppColors.goldPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (item.currency != _conversionTarget &&
                                    _isConversionAvailable) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '≈ ${CurrencyFormatter.format(CurrencyRateService.instance.convert(amount: item.amount, from: item.currency, to: _conversionTarget), _conversionTarget)}',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.canvasCream.withValues(
                                        alpha: 0.90,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // TOTAL CARD (Multi-Currency Aware)
                  if (hasDetections) _buildSummaryTotalCard(),

                  const SizedBox(height: AppSpacing.lg),

                  // ACTION BUTTONS (54px height for accessibility)
                  Row(
                    children: [
                      // Replay Voice Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: voiceControlColor,
                                width: 1.5,
                              ),
                              foregroundColor: voiceControlColor,
                              disabledForegroundColor: voiceControlColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                            onPressed: _ttsService.isVoiceEnabled
                                ? () {
                                    final speech = _ttsService
                                        .buildSpeechSentence(
                                          detections: _capturedDetections,
                                          totalsByCurrency: _totalsByCurrency,
                                          targetCurrency: _conversionTarget,
                                          conversionService:
                                              CurrencyRateService.instance,
                                          isConversionAvailable:
                                              _isConversionAvailable,
                                        );
                                    _ttsService.speak(speech);
                                  }
                                : null,
                            icon: Icon(
                              _ttsService.isVoiceEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              size: 22,
                            ),
                            label: Text(
                              _ttsService.isVoiceEnabled
                                  ? 'Bacakan Suara'
                                  : 'Suara Mati',
                              style: AppTypography.labelLarge.copyWith(
                                color: voiceControlColor,
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
                  const SizedBox(height: AppSpacing.sm),

                  // Option to pick another photo directly from gallery
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.goldPrimary.withValues(alpha: 0.6),
                          width: 1.4,
                        ),
                        foregroundColor: AppColors.goldLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: _pickFromGalleryAndAnalyze,
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        size: 20,
                        color: AppColors.goldPrimary,
                      ),
                      label: Text(
                        'Pilih Foto Lain dari Galeri',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the summary card: single-currency presentation or mixed-currency breakdown
  /// with target currency selector (without re-running YOLO).
  Widget _buildSummaryTotalCard() {
    final singleCurrency = MoneyAggregator.singleCurrencyOrNull(
      _capturedDetections,
    );
    final bool isSingle = singleCurrency != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.espressoDark, Color(0xFF22160E)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.goldPrimary, width: 2),
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
          if (isSingle) ...[
            // Single currency total presentation
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
                  'TOTAL NOMINAL ${singleCurrency.code}',
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
              CurrencyFormatter.format(
                _totalsByCurrency[singleCurrency] ?? 0.0,
                singleCurrency,
              ),
              style: AppTypography.displayLarge.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            // Equivalent conversions into other 2 currencies
            if (_isConversionAvailable) ...[
              Builder(
                builder: (context) {
                  final others = CurrencyCode.values
                      .where((c) => c != singleCurrency)
                      .toList();
                  final double baseAmount =
                      _totalsByCurrency[singleCurrency] ?? 0.0;
                  final eq1 = CurrencyRateService.instance.convert(
                    amount: baseAmount,
                    from: singleCurrency,
                    to: others[0],
                  );
                  final eq2 = CurrencyRateService.instance.convert(
                    amount: baseAmount,
                    from: singleCurrency,
                    to: others[1],
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.goldPrimary.withValues(alpha: 0.22),
                          AppColors.goldPrimary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.25,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.currency_exchange_rounded,
                            color: AppColors.goldLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SETARA KURS MATA UANG',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.goldLight.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '≈ ${CurrencyFormatter.format(eq1, others[0])}  •  ≈ ${CurrencyFormatter.format(eq2, others[1])}',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            Text(
              'Terbilang: ${MoneySpeechFormatter.amountToSpoken(_totalsByCurrency[singleCurrency] ?? 0.0, singleCurrency)}',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.canvasCream.withValues(alpha: 0.90),
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            // Mixed currency totals presentation
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
                  'TOTAL PER MATA UANG',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.goldPrimary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Rows for each currency present
            ...CurrencyCode.values.map((code) {
              final amount = _totalsByCurrency[code] ?? 0.0;
              if (amount <= 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      code.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(amount, code),
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            // Target Currency Selector Chips (IDR, SAR, USD) — Zero inference recompute!
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldPrimary.withValues(alpha: 0.22),
                    AppColors.goldPrimary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.goldPrimary.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL SETARA',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.goldLight.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        children: CurrencyCode.values.map((c) {
                          final isSelected = c == _conversionTarget;
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: ChoiceChip(
                              label: Text(c.code),
                              selected: isSelected,
                              selectedColor: AppColors.goldPrimary,
                              backgroundColor: AppColors.espressoDark,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.espressoDark
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _conversionTarget = c;
                                    _recalculateConversions();
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(
                      _convertedGrandTotal,
                      _conversionTarget,
                    ),
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.goldLight,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Terbilang: ${MoneySpeechFormatter.amountToSpoken(_convertedGrandTotal, _conversionTarget)}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.canvasCream.withValues(alpha: 0.90),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Exchange rate reference & adjust button
          GestureDetector(
            onTap: _showExchangeRateSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: AppColors.goldMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Kurs: 1 SAR = ${CurrencyFormatter.formatRupiah(CurrencyRateService.instance.getRate(CurrencyCode.sar, CurrencyCode.idr))}',
                    style: AppTypography.captionSmall.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '• Ubah',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
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
              'Pemindai Belum Siap',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _modelError ?? 'Pemindai uang belum siap. Tekan Coba Lagi.',
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

  // ---------------------------------------------------------------------------
  // 5. EXCHANGE RATE CUSTOMIZATION BOTTOM SHEET
  // ---------------------------------------------------------------------------

  void _showExchangeRateSheet() {
    final TextEditingController rateController = TextEditingController(
      text: _exchangeRate.round().toString(),
    );
    bool isCheckingOnline = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenEdgeGutter,
                AppSpacing.lg,
                AppSpacing.screenEdgeGutter,
                bottomInset + AppSpacing.xl,
              ),
              decoration: const BoxDecoration(
                color: AppColors.espressoDark,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.currency_exchange_rounded,
                            color: AppColors.goldPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengaturan Kurs Mata Uang',
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                CurrencyRateService.instance.lastApiUtcTime !=
                                        null
                                    ? 'Live API: ${CurrencyRateService.instance.lastApiUtcTime}'
                                    : 'SAR ↔ IDR ↔ USD (Dynamic FX)',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.goldLight.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Quick presets
                    Text(
                      'Pilihan Cepat Kurs SAR ke Rupiah:',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.canvasCream.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          <double>{
                            if (CurrencyRateService.instance.currentRate > 0)
                              CurrencyRateService.instance.currentRate,
                            4500.0,
                            4600.0,
                            4700.0,
                            4750.0,
                            4800.0,
                          }.map((preset) {
                            final currentVal = double.tryParse(
                              rateController.text,
                            );
                            final isSelected = (currentVal == preset);
                            return ChoiceChip(
                              label: Text(
                                CurrencyFormatter.formatRupiah(preset),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.espressoDark
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.goldPrimary,
                              backgroundColor: AppColors.primaryContainer,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.goldPrimary
                                    : Colors.white24,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() {
                                    rateController.text = preset
                                        .toInt()
                                        .toString();
                                  });
                                }
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Manual input
                    Text(
                      'Nominal Kurs SAR Manual (Rp):',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.canvasCream.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rp  ',
                        prefixStyle: AppTypography.titleLarge.copyWith(
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: AppColors.primaryContainer.withValues(
                          alpha: 0.8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.goldPrimary,
                            width: 2,
                          ),
                        ),
                        hintText: '4750',
                        hintStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Fetch online button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.goldPrimary.withValues(alpha: 0.6),
                        ),
                        foregroundColor: AppColors.goldPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isCheckingOnline
                          ? null
                          : () async {
                              setSheetState(() => isCheckingOnline = true);
                              final success = await CurrencyRateService.instance
                                  .fetchLatestOnlineRate();
                              setSheetState(() => isCheckingOnline = false);

                              if (success) {
                                setSheetState(() {
                                  rateController.text = CurrencyRateService
                                      .instance
                                      .currentRate
                                      .toInt()
                                      .toString();
                                });
                                Get.snackbar(
                                  'Kurs Terkini Diperbarui',
                                  '1 SAR = ${CurrencyFormatter.formatRupiah(CurrencyRateService.instance.currentRate)}',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primaryContainer,
                                  colorText: Colors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'Tidak Dapat Menghubungkan',
                                  'Periksa koneksi internet Anda atau gunakan pilihan kurs acuan.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primaryContainer,
                                  colorText: Colors.white,
                                );
                              }
                            },
                      icon: isCheckingOnline
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.goldPrimary,
                              ),
                            )
                          : const Icon(Icons.cloud_sync_rounded, size: 20),
                      label: Text(
                        isCheckingOnline
                            ? 'Memeriksa kurs terbaru...'
                            : 'Cek Kurs Real-Time (Online)',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Save & Apply button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: AppColors.espressoDark,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: () async {
                        final val = double.tryParse(
                          rateController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                        );
                        if (val != null && val > 500 && val < 20000) {
                          await CurrencyRateService.instance.setCustomRate(val);
                          if (mounted) {
                            setState(() {
                              _exchangeRate = val;
                              _recalculateConversions();
                            });
                          }
                          if (bottomSheetContext.mounted) {
                            Navigator.pop(bottomSheetContext);
                          }
                        } else {
                          Get.snackbar(
                            'Nominal Tidak Valid',
                            'Masukkan nilai kurs yang wajar (antara Rp 1.000 - Rp 15.000).',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                          );
                        }
                      },
                      child: Text(
                        'Terapkan Kurs',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.espressoDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
      final color = getDetectionColor(detection);

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

  /// Currency-aware high-contrast color palette for bounding box overlays.
  static Color getDetectionColor(MoneyDetection detection) {
    if (detection.isCoin) {
      return const Color(0xFFF59E0B); // Amber / coin
    }

    switch (detection.currency) {
      case CurrencyCode.sar:
        if (detection.amount >= 500) {
          return const Color(0xFF047857); // Deep Emerald
        }
        if (detection.amount >= 200) {
          return const Color(0xFF0D9488); // Teal
        }
        if (detection.amount >= 100) {
          return const Color(0xFF10B981); // Emerald
        }
        if (detection.amount >= 50) {
          return const Color(0xFF059669);
        }
        if (detection.amount >= 20) {
          return const Color(0xFF14B8A6);
        }
        if (detection.amount >= 10) {
          return const Color(0xFF2DD4BF);
        }
        if (detection.amount >= 5) {
          return const Color(0xFF34D399);
        }
        return const Color(0xFF6EE7B7);

      case CurrencyCode.idr:
        if (detection.amount >= 100000) {
          return const Color(0xFFE11D48); // Red
        }
        if (detection.amount >= 75000) {
          return const Color(0xFFF43F5E); // Rose
        }
        if (detection.amount >= 50000) {
          return const Color(0xFF3B82F6); // Blue
        }
        if (detection.amount >= 20000) {
          return const Color(0xFF16A34A); // Green
        }
        if (detection.amount >= 10000) {
          return const Color(0xFF9333EA); // Purple
        }
        if (detection.amount >= 5000) {
          return const Color(0xFFD97706); // Amber
        }
        if (detection.amount >= 2000) {
          return const Color(0xFF64748B); // Slate
        }
        return const Color(0xFF78716C); // Stone

      case CurrencyCode.usd:
        if (detection.amount >= 100) {
          return const Color(0xFF0284C7); // Sky/Navy
        }
        if (detection.amount >= 50) {
          return const Color(0xFF0EA5E9);
        }
        if (detection.amount >= 20) {
          return const Color(0xFF38BDF8);
        }
        if (detection.amount >= 10) {
          return const Color(0xFF06B6D4);
        }
        if (detection.amount >= 5) {
          return const Color(0xFF14B8A6);
        }
        return const Color(0xFF059669);
    }
  }

  /// Backward-compatible denomination color helper.
  static Color getDenominationColor(double amount, bool isCoin) {
    if (isCoin) {
      return const Color(0xFFF59E0B); // Amber / coin
    }
    if (amount >= 500) {
      return const Color(0xFF9333EA); // Purple (500 SAR)
    }
    if (amount >= 200) {
      return const Color(0xFF8D6E63); // Brown (200 SAR)
    }
    if (amount >= 100) {
      return const Color(0xFFE11D48); // Red (100 SAR)
    }
    if (amount >= 50) {
      return const Color(0xFF16A34A); // Green (50 SAR)
    }
    if (amount >= 20) {
      return const Color(0xFFEA580C); // Deep orange (20 SAR)
    }
    if (amount >= 10) {
      return const Color(0xFFD97706); // Amber (10 SAR)
    }
    if (amount >= 5) {
      return const Color(0xFF0D9488); // Teal (5 SAR)
    }
    return const Color(0xFF78716C); // Stone (1 & 2 SAR)
  }

  @override
  bool shouldRepaint(covariant MoneyBoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
