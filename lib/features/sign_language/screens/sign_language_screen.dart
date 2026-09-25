import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/bisindo_recognition_controller.dart';
import '../models/sign_language_model.dart';
import '../models/sign_token.dart';
import '../services/bisindo_camera_landmark_service.dart';
import '../services/bisindo_inference_service.dart';
import '../services/bisindo_yolo_service.dart';
import '../services/landmark_stream_buffer.dart';

/// Realtime Sign Language (SIBI & BISINDO) Recognition Screen.
/// Best-practice dual pipeline:
/// - SIBI: Lightweight Ultralytics YOLO object detection with 15 FPS throttling,
///   candidate letter badge with circular loader, and instant suggestion pills.
/// - BISINDO: MediaPipe Holistic landmark stream + sequence GRU model with
///   TextureView-based platform view keeping camera strictly inside the frame.
class SignLanguageScreen extends StatefulWidget {
  final SignLanguageModel initialModel;

  const SignLanguageScreen({
    super.key,
    this.initialModel = SignLanguageModel.sibi,
  });

  @override
  State<SignLanguageScreen> createState() => _SignLanguageScreenState();
}

class _SignLanguageScreenState extends State<SignLanguageScreen> {
  static const String _kPreviewViewType = 'com.hajicare.bisindo/camera_preview';

  static Color _accent(BuildContext context) => AppColors.isDark(context)
      ? AppColors.darkPrimary
      : AppColors.espressoDark;

  late final BisindoRecognitionController _recognition;
  late final BisindoInferenceService _inferenceService;
  late final LandmarkStreamBuffer _streamBuffer;
  late final BisindoCameraLandmarkService _cameraService;
  late final BisindoYoloService _yoloService;

  final YOLOViewController _yoloController = YOLOViewController();

  SignLanguageModel _currentModel = SignLanguageModel.sibi;
  bool _isCameraActive = false;
  bool _isModelLoading = false;
  bool _isSwitchingModel = false;
  bool _modelReady = false;
  String? _errorMessage;

  int _modelSwitchGeneration = 0;
  DateTime _lastYoloProcessTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _currentModel = widget.initialModel;
    _recognition = Get.find<BisindoRecognitionController>();

    if (Get.isRegistered<BisindoInferenceService>()) {
      _inferenceService = Get.find<BisindoInferenceService>();
    } else {
      _inferenceService = BisindoInferenceService();
      Get.put(_inferenceService);
    }

    _yoloService = BisindoYoloService();
    unawaited(_yoloService.loadLabels());

    final initialConfig = SignLanguageModelConfig.forModel(_currentModel);

    _streamBuffer = LandmarkStreamBuffer(
      inferenceService: _inferenceService,
      windowSize: initialConfig.windowSize,
      minimumFrames: initialConfig.minimumFrames,
      inferenceStride: initialConfig.inferenceStride,
      throttleDuration: initialConfig.throttleDuration,
      onPrediction: (prediction) {
        if (!mounted || _isSwitchingModel || !_modelReady) return;
        _recognition.handlePrediction(prediction);
      },
      onBufferLengthChanged: (len) {
        if (!mounted || _isSwitchingModel) return;
        _recognition.updateBufferCount(len);
      },
      onError: (err) {
        debugPrint('[SIGN_LANGUAGE_SCREEN] Stream buffer error: $err');
      },
    );

    _cameraService = BisindoCameraLandmarkService(streamBuffer: _streamBuffer);

    _applyModelThresholds(_currentModel);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            unawaited(_initPipeline());
          }
        });
      }
    });
  }

  void _applyModelThresholds(SignLanguageModel model) {
    if (model == SignLanguageModel.sibi) {
      _recognition.setModelThresholds(
        confidenceThreshold: 0.30,
        stablePredictionsRequired: 4,
      );
    } else {
      _recognition.setModelThresholds(
        confidenceThreshold: 0.75,
        stablePredictionsRequired: 3,
      );
    }
  }

  Future<void> _initPipeline() async {
    final generation = ++_modelSwitchGeneration;
    setState(() {
      _isModelLoading = true;
      _errorMessage = null;
      _modelReady = false;
    });

    try {
      if (_currentModel == SignLanguageModel.bisindo) {
        final config = SignLanguageModelConfig.forModel(_currentModel);
        await _inferenceService.loadModel(config);

        if (!mounted || generation != _modelSwitchGeneration) return;

        _streamBuffer.updateConfig(
          windowSize: config.windowSize,
          minimumFrames: config.minimumFrames,
          inferenceStride: config.inferenceStride,
          throttleDuration: config.throttleDuration,
        );
      } else {
        await _yoloService.loadLabels();
      }

      if (!mounted || generation != _modelSwitchGeneration) return;

      setState(() {
        _isModelLoading = false;
        _modelReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_SCREEN] Model initialization failed: $e');
      if (!mounted || generation != _modelSwitchGeneration) return;

      setState(() {
        _isModelLoading = false;
        _modelReady = false;
        _errorMessage = 'Gagal memuat model ${_currentModel.displayName}: $e';
      });
    }
  }

  void _handleYoloDetections(List<YOLOResult> detections) {
    if (!mounted || !_isCameraActive) return;

    // Software throttling to prevent UI stutter: max 15 FPS
    final now = DateTime.now();
    if (now.difference(_lastYoloProcessTime).inMilliseconds < 65) return;
    _lastYoloProcessTime = now;

    if (detections.isEmpty) {
      _recognition.handleNoHand();
      return;
    }

    final prediction = _yoloService.processDetections(
      detections,
      confidenceThreshold: 0.30,
      alphabetOnly: true,
    );

    if (prediction.isRecognized) {
      _recognition.handlePrediction(prediction);
    } else {
      _recognition.handleNoHand();
    }
  }

  Future<void> _switchModel(SignLanguageModel targetModel) async {
    if (_isSwitchingModel || _currentModel == targetModel) return;

    final generation = ++_modelSwitchGeneration;
    final previousModel = _currentModel;

    setState(() {
      _isSwitchingModel = true;
      _isModelLoading = true;
      _errorMessage = null;
    });

    _applyModelThresholds(targetModel);
    _recognition.resetTranscript();

    // Isolate hardware pipelines: stop whichever is not needed
    if (previousModel == SignLanguageModel.bisindo &&
        targetModel == SignLanguageModel.sibi) {
      await _cameraService.stopCamera();
      _streamBuffer.pause();
      _streamBuffer.clear();
    } else if (previousModel == SignLanguageModel.sibi &&
        targetModel == SignLanguageModel.bisindo) {
      if (_isCameraActive) {
        await _cameraService.startCamera();
        _streamBuffer.resume();
      }
    }

    try {
      if (targetModel == SignLanguageModel.bisindo) {
        final targetConfig = SignLanguageModelConfig.forModel(targetModel);
        await _inferenceService.loadModel(targetConfig);

        if (!mounted || generation != _modelSwitchGeneration) return;

        _streamBuffer.updateConfig(
          windowSize: targetConfig.windowSize,
          minimumFrames: targetConfig.minimumFrames,
          inferenceStride: targetConfig.inferenceStride,
          throttleDuration: targetConfig.throttleDuration,
        );
      } else {
        await _yoloService.loadLabels();
      }

      if (!mounted || generation != _modelSwitchGeneration) return;

      setState(() {
        _currentModel = targetModel;
        _isSwitchingModel = false;
        _isModelLoading = false;
        _modelReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_SCREEN] Switch model failed: $e');
      if (!mounted || generation != _modelSwitchGeneration) return;

      setState(() {
        _isSwitchingModel = false;
        _isModelLoading = false;
        _modelReady = true;
        _errorMessage = 'Gagal beralih ke model ${targetModel.displayName}: $e';
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_isModelLoading || _isSwitchingModel) return;

    if (_isCameraActive) {
      if (_currentModel == SignLanguageModel.bisindo) {
        await _cameraService.stopCamera();
        _streamBuffer.clear();
      }
      _recognition.setCameraActive(false);
      if (mounted) setState(() => _isCameraActive = false);
    } else {
      setState(() {
        _isModelLoading = true;
        _errorMessage = null;
      });

      final perm = await _cameraService.checkPermission();
      if (perm != 'granted') {
        final req = await _cameraService.requestPermission();
        if (req != 'granted') {
          if (mounted) {
            setState(() {
              _isModelLoading = false;
              _errorMessage =
                  'Izin kamera ditolak. Silakan berikan izin di pengaturan.';
            });
          }
          return;
        }
      }

      // In SIBI mode: YOLOView manages the camera directly
      if (_currentModel == SignLanguageModel.sibi) {
        _recognition.setCameraActive(true);
        if (mounted) {
          setState(() {
            _isCameraActive = true;
            _isModelLoading = false;
          });
        }
        return;
      }

      // In BISINDO mode: Native CameraX + MediaPipe manages the camera
      final started = await _cameraService.startCamera();
      if (!started) {
        if (mounted) {
          setState(() {
            _isModelLoading = false;
            _errorMessage = _cameraService.lastError ?? 'Gagal memulai kamera.';
          });
        }
        return;
      }

      _recognition.setCameraActive(true);
      if (mounted) {
        setState(() {
          _isCameraActive = true;
          _isModelLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _modelSwitchGeneration++;
    _streamBuffer.pause();
    _recognition.setCameraActive(false);
    unawaited(_cameraService.dispose());
    _streamBuffer.dispose();
    _yoloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.canvasCreamSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.tanLight.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.sign_language_rounded,
                color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Isyarat ke Teks',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textHeadingColor(context),
                fontWeight: FontWeight.w700,
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
            _buildModelSwitcher(),
            _buildCameraPanel(),
            if (_errorMessage != null) _buildErrorCard(),
            const SizedBox(height: 14),
            _buildUnifiedResultCard(),
            if (_currentModel == SignLanguageModel.bisindo) ...[
              const SizedBox(height: 14),
              _buildRecognitionStatus(),
            ],
            const SizedBox(height: 18),
            _buildControls(),
            const SizedBox(height: 14),
            _buildSpeakButton(),
            const SizedBox(height: 14),
            _buildInstructionHint(),
          ],
        ),
      ),
    );
  }

  /// Modern 2-Tab Segmented Model Switcher [ SIBI | BISINDO ]
  Widget _buildModelSwitcher() {
    final isDark = AppColors.isDark(context);
    final isBusy = _isSwitchingModel || _isModelLoading;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCreamSubtle,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorderColor(context), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModelOptionTab(
              model: SignLanguageModel.sibi,
              label: 'SIBI (Alfabet)',
              icon: Icons.sort_by_alpha_rounded,
              isSelected: _currentModel == SignLanguageModel.sibi,
              isDisabled: isBusy,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModelOptionTab(
              model: SignLanguageModel.bisindo,
              label: 'BISINDO (Kata)',
              icon: Icons.handshake_rounded,
              isSelected: _currentModel == SignLanguageModel.bisindo,
              isDisabled: isBusy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOptionTab({
    required SignLanguageModel model,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDisabled,
  }) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isDisabled || isSelected) ? null : () => _switchModel(model),
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.espressoDark)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:
                          (isDark ? AppColors.espressoDark : AppColors.primary)
                              .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? AppColors.goldLight : Colors.white)
                    : AppColors.textSecondaryColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isSelected
                      ? (isDark ? AppColors.goldLight : Colors.white)
                      : AppColors.textSecondaryColor(context),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Self-contained Camera Frame with rounded corners, proper margins, and overlays.
  Widget _buildCameraPanel() {
    final isDark = AppColors.isDark(context);
    final isSibi = _currentModel == SignLanguageModel.sibi;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorderColor(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 330,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Live Feed / Placeholder
              if (!_isCameraActive)
                ColoredBox(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.espressoDark,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sign_language_rounded,
                          color: AppColors.goldLight.withValues(alpha: 0.85),
                          size: 54,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Kamera belum aktif',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekan tombol MULAI di bawah',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isSibi)
                YOLOView(
                  key: const ValueKey('yolo_camera_sibi'),
                  modelPath: SignLanguageModelConfig.sibi.modelAsset,
                  task: YOLOTask.detect,
                  controller: _yoloController,
                  lensFacing: LensFacing.front,
                  confidenceThreshold: 0.30,
                  cameraResolution: '480p',
                  streamingConfig: YOLOStreamingConfig.throttled(
                    maxFPS: 15,
                    skipFrames: 1,
                    includeMasks: false,
                    includePoses: false,
                    includeOBB: false,
                    includeOriginalImage: false,
                  ),
                  onModelLoad: (path, task) {
                    _yoloController.setShowOverlays(false);
                    if (mounted) {
                      setState(() {
                        _isModelLoading = false;
                        _modelReady = true;
                      });
                    }
                  },
                  onModelError: (error, path, task) {
                    debugPrint('[SIBI][YOLO] Error: $error');
                    if (mounted) {
                      setState(() {
                        _errorMessage = 'Gagal memuat YOLO SIBI: $error';
                        _isModelLoading = false;
                      });
                    }
                  },
                  onResult: _handleYoloDetections,
                )
              else
                const AndroidView(
                  viewType: _kPreviewViewType,
                  creationParamsCodec: StandardMessageCodec(),
                ),

              // 2. Top-Left Status Badges [ LIVE | SIBI - 1M / BISINDO ]
              Positioned(
                left: 14,
                top: 13,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CameraBadge(
                      text: _isCameraActive ? 'LIVE' : 'STANDBY',
                      isLive: _isCameraActive,
                      color: _isCameraActive
                          ? AppColors.emeraldIslamic.withValues(alpha: 0.9)
                          : (isDark
                                ? AppColors.darkSurfaceContainerHigh
                                : AppColors.espressoDark.withValues(
                                    alpha: 0.85,
                                  )),
                    ),
                    const SizedBox(width: 8),
                    _CameraBadge(
                      text: isSibi ? 'SIBI - ALFABET' : 'BISINDO - KATA',
                      isLive: false,
                      color: isDark
                          ? AppColors.darkPrimaryContainer.withValues(
                              alpha: 0.95,
                            )
                          : AppColors.primaryContainer.withValues(alpha: 0.95),
                    ),
                  ],
                ),
              ),

              // 3. Loading Overlay
              if (_isModelLoading || _isSwitchingModel)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.espressoDark.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentGoldStar.withValues(
                            alpha: 0.4,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.accentGoldStar,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isSwitchingModel
                                ? 'Memuat model ${_currentModel.displayName}...'
                                : 'Menyiapkan pipeline...',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Bottom-Right Gesture Candidate Loader for SIBI
              if (isSibi)
                Obx(() {
                  final candidate = _recognition.currentCandidate.value;
                  final detected = _recognition.detectedLabel.value;
                  final isRecognized =
                      _recognition.recognitionState.value ==
                      SignRecognitionState.recognized;
                  final label = isRecognized ? detected : (candidate ?? '');
                  final progress = _recognition.holdProgress.value;

                  if (label.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    right: 16,
                    bottom: 16,
                    child: _GestureCandidateLoader(
                      label: label,
                      progress: progress,
                      isConfirmed: isRecognized,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  /// AI Transcription Card ("TRANSKRIPSI AI")
  Widget _buildUnifiedResultCard() {
    return Obx(() {
      final isDark = AppColors.isDark(context);
      final items = _recognition.tokens;
      final raw = _recognition.rawTranscript.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorderColor(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.accentGoldStar
                        : AppColors.espressoDark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TRANSKRIPSI AI',
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (raw.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Mulai isyarat untuk melihat terjemahan...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else ...[
              if (items.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: items.map(_buildGestureBox).toList()),
                ),
              const SizedBox(height: 12),
              Divider(
                color: AppColors.outlineColor(context).withValues(alpha: 0.25),
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
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
                    ),
                    label: Text(
                      'Dengarkan',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.espressoDark,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
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
              ? AppColors.darkSurfaceContainerHigh
              : AppColors.canvasCreamSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.cardBorderColor(context),
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

    final text = token.value;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkPrimaryContainer.withValues(alpha: 0.6)
            : AppColors.canvasCreamSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.accentGoldStar.withValues(alpha: 0.4)
              : AppColors.tanLight,
          width: 1.3,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.goldLight
                : AppColors.textHeadingColor(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// Status & Progress indicator for BISINDO sequence model
  Widget _buildRecognitionStatus() {
    return Obx(() {
      final state = _recognition.recognitionState.value;
      final streak = _recognition.stabilityStreak.value;
      final maxStreak = _recognition.config.stablePredictionsRequired;
      final buffer = _recognition.bufferCount.value;
      final isHand = _recognition.isHandDetected.value;
      final gold = _accent(context);

      double progress = 0.0;
      const minBufferRequired = 24;

      if (!isHand) {
        progress = 0.0;
      } else if (buffer < minBufferRequired) {
        progress = buffer / minBufferRequired;
      } else if (state == SignRecognitionState.recognized) {
        progress = 1.0;
      } else {
        progress = _recognition.holdProgress.value;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state == SignRecognitionState.reading ||
                    (state == SignRecognitionState.analyzing && streak == 0))
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
                      color: state == SignRecognitionState.recognized
                          ? AppColors.emeraldIslamic
                          : streak > 0
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
                minHeight: 8,
                backgroundColor: gold.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  state == SignRecognitionState.recognized
                      ? AppColors.emeraldIslamic
                      : AppColors.goldPrimary,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              buffer < minBufferRequired
                  ? 'Menyiapkan buffer ($buffer/$minBufferRequired frame)'
                  : streak > 0
                  ? 'Tahan gerakan: $streak/$maxStreak konfirmasi stabil'
                  : 'Arahkan & tahan isyarat di depan kamera',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Action Buttons (STOP/MULAI, SPASI, HAPUS, RESET) and Hold Hint
  Widget _buildControls() {
    final isDark = AppColors.isDark(context);
    final isBusy = _isModelLoading || _isSwitchingModel;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. STOP / MULAI
            _RoundControl(
              label: _isCameraActive ? 'STOP' : 'MULAI',
              icon: isBusy
                  ? Icons.hourglass_top_rounded
                  : _isCameraActive
                  ? Icons.stop_rounded
                  : Icons.videocam_rounded,
              bgColor: _isCameraActive
                  ? (isDark
                        ? AppColors.errorContainer.withValues(alpha: 0.3)
                        : AppColors.errorContainer.withValues(alpha: 0.6))
                  : (isDark
                        ? AppColors.emeraldDark.withValues(alpha: 0.4)
                        : AppColors.emeraldLight),
              borderColor: _isCameraActive
                  ? AppColors.sosEmergency.withValues(alpha: 0.5)
                  : AppColors.emeraldIslamic.withValues(alpha: 0.5),
              iconColor: _isCameraActive
                  ? AppColors.sosEmergency
                  : AppColors.emeraldIslamic,
              onTap: !isBusy ? _toggleCamera : null,
            ),
            const SizedBox(width: 14),
            // 2. SPASI
            _RoundControl(
              label: 'SPASI',
              icon: Icons.space_bar_rounded,
              bgColor: isDark
                  ? AppColors.darkSurfaceContainerHigh
                  : AppColors.canvasCreamSubtle,
              borderColor: isDark ? AppColors.darkOutline : AppColors.tanLight,
              iconColor: isDark
                  ? AppColors.darkPrimary
                  : AppColors.espressoDark,
              onTap: _recognition.insertSpace,
            ),
            const SizedBox(width: 14),
            // 3. HAPUS
            _RoundControl(
              label: 'HAPUS',
              icon: Icons.backspace_rounded,
              bgColor: isDark
                  ? AppColors.secondaryContainer.withValues(alpha: 0.25)
                  : AppColors.secondaryContainer.withValues(alpha: 0.4),
              borderColor: AppColors.distanceWarning.withValues(alpha: 0.5),
              iconColor: AppColors.distanceWarning,
              onTap: _recognition.deleteLast,
            ),
            const SizedBox(width: 14),
            // 4. RESET
            _RoundControl(
              label: 'RESET',
              icon: Icons.restart_alt_rounded,
              bgColor: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.canvasCream,
              borderColor: AppColors.outlineVariant,
              iconColor: AppColors.textMuted,
              onTap: _recognition.resetTranscript,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Tahan posisi... lihat progress di kamera',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.goldLight : AppColors.espressoMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakButton() {
    return Obx(() {
      final isDark = AppColors.isDark(context);
      final raw = _recognition.rawTranscript.value.trim();
      final isSpeaking = _recognition.isSpeaking.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 52,
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
              style: AppTypography.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.espressoDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  (isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.espressoDark)
                      .withValues(alpha: 0.3),
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

  Widget _buildInstructionHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        _currentModel == SignLanguageModel.sibi
            ? 'Model SIBI aktif: Arahkan dan tahan gestur huruf alfabet di depan kamera.'
            : 'Model BISINDO aktif: Arahkan tangan ke kamera untuk mendeteksi kosakata BISINDO secara realtime.',
        textAlign: TextAlign.center,
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.textSecondaryColor(context),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => _switchModel(_currentModel),
            child: Text(
              'Coba Lagi',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Candidate gesture badge with circular loader (Hajicare Gold & Espresso palette)
class _GestureCandidateLoader extends StatelessWidget {
  final String label;
  final double progress;
  final bool isConfirmed;

  const _GestureCandidateLoader({
    required this.label,
    required this.progress,
    this.isConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    final display = label.length > 3 ? label.substring(0, 3) : label;

    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Progress Indicator around the badge
          SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 3.5,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                isConfirmed ? AppColors.accentGoldStar : AppColors.goldLight,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Inner rounded card with Mecca Gold / Espresso aesthetic
          AnimatedScale(
            scale: isConfirmed ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.espressoDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isConfirmed
                      ? AppColors.accentGoldStar
                      : AppColors.goldLight.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                display.toUpperCase(),
                style: AppTypography.heading(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
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
                color: Color(0xFF48C774),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: AppTypography.captionSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _RoundControl({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null ? bgColor.withValues(alpha: 0.4) : bgColor,
              border: Border.all(
                color: onTap == null
                    ? borderColor.withValues(alpha: 0.3)
                    : borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: onTap == null
                  ? iconColor.withValues(alpha: 0.4)
                  : iconColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: iconColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
