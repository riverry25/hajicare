import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/bisindo_recognition_controller.dart';
import '../controllers/sign_language_controller.dart';
import '../models/sign_language_model.dart';
import '../models/sign_token.dart';
import '../services/bisindo_camera_landmark_service.dart';
import '../services/bisindo_yolo_service.dart';

/// Realtime Sign Language (SIBI & BISINDO) Recognition Screen.
/// Best-practice dual pipeline:
/// - SIBI: Lightweight Ultralytics YOLO object detection with 15 FPS throttling,
///   candidate letter badge with circular loader, and instant suggestion pills.
/// - BISINDO: MediaPipe Holistic landmark stream + automatic gesture
///   segmentation + MotionGRU classifier (hands-free, continuous).
/// Both models write into one shared, persisted "Transkripsi AI".
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
  late final SignLanguageController _isolatedController;
  late final BisindoCameraLandmarkService _cameraService;
  late final BisindoYoloService _yoloService;

  final YOLOViewController _yoloController = YOLOViewController();

  SignLanguageModel _currentModel = SignLanguageModel.sibi;
  LensFacing _currentLens = LensFacing.front;
  bool _isCameraActive = false;
  bool _isModelLoading = false;
  bool _isSwitchingModel = false;
  String? _errorMessage;

  int _modelSwitchGeneration = 0;
  DateTime _lastYoloProcessTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _currentModel = widget.initialModel;
    _recognition = Get.find<BisindoRecognitionController>();

    _yoloService = BisindoYoloService();
    unawaited(_yoloService.loadLabels());

    if (Get.isRegistered<SignLanguageController>()) {
      _isolatedController = Get.find<SignLanguageController>();
    } else {
      _isolatedController = SignLanguageController();
      Get.put(_isolatedController);
    }
    _isolatedController.onPredictionAccepted = (prediction) {
      _recognition.commitWord(prediction.label, speak: true);
    };

    // BISINDO frames go only to the MotionGRU live controller.
    _cameraService = BisindoCameraLandmarkService(
      onFrame: (frame) {
        if (_currentModel != SignLanguageModel.bisindo) return;
        _isolatedController.onIncomingLandmarkFrame(frame);
        if (frame.hasAnyHand) {
          _recognition.registerHandFrame();
        }
      },
    );

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
    });

    try {
      // BISINDO MotionGRU is initialized by SignLanguageController.onInit.
      if (_currentModel == SignLanguageModel.sibi) {
        await _yoloService.loadLabels();
      }

      if (!mounted || generation != _modelSwitchGeneration) return;

      setState(() {
        _isModelLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_SCREEN] Model initialization failed: $e');
      if (!mounted || generation != _modelSwitchGeneration) return;

      setState(() {
        _isModelLoading = false;
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

  /// Switches SIBI ⇄ BISINDO. The shared transcript is intentionally kept;
  /// only transient recognition state is reset. If the camera is running,
  /// detection continues immediately on the new model.
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
    _recognition.resetRecognitionState();

    try {
      // Isolate hardware pipelines: stop whichever is not needed
      if (previousModel == SignLanguageModel.bisindo &&
          targetModel == SignLanguageModel.sibi) {
        _isolatedController.stopContinuous();
        await _cameraService.stopCamera();
        await _yoloService.loadLabels();
      } else if (previousModel == SignLanguageModel.sibi &&
          targetModel == SignLanguageModel.bisindo) {
        if (_isCameraActive) {
          await _cameraService.setLensFacing(_currentLens == LensFacing.front);
          final started = await _cameraService.startCamera();
          if (!started) {
            throw StateError(
              _cameraService.lastError ?? 'Gagal memulai kamera.',
            );
          }
          _isolatedController.startContinuous();
        }
      }

      if (!mounted || generation != _modelSwitchGeneration) return;

      setState(() {
        _currentModel = targetModel;
        _isSwitchingModel = false;
        _isModelLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_SCREEN] Switch model failed: $e');
      if (!mounted || generation != _modelSwitchGeneration) return;

      _isolatedController.stopContinuous();
      _recognition.setCameraActive(false);
      setState(() {
        _currentModel = targetModel;
        _isCameraActive = false;
        _isSwitchingModel = false;
        _isModelLoading = false;
        _errorMessage = 'Gagal beralih ke model ${targetModel.displayName}: $e';
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_isModelLoading || _isSwitchingModel) return;

    if (_isCameraActive) {
      if (_currentModel == SignLanguageModel.bisindo) {
        _isolatedController.stopContinuous();
        await _cameraService.stopCamera();
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
      await _cameraService.setLensFacing(_currentLens == LensFacing.front);
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
      // Hands-free: detection starts right away, no extra "record" tap.
      _isolatedController.startContinuous();
      if (mounted) {
        setState(() {
          _isCameraActive = true;
          _isModelLoading = false;
        });
      }
    }
  }

  /// Switches camera between front and back lens for both SIBI and BISINDO pipelines.
  Future<void> _switchCameraLens() async {
    final nextLens = _currentLens == LensFacing.front
        ? LensFacing.back
        : LensFacing.front;

    HapticFeedback.selectionClick();

    if (_currentModel == SignLanguageModel.sibi) {
      if (_isCameraActive) {
        try {
          await _yoloController.switchCamera();
        } catch (e) {
          debugPrint('[SIBI][YOLO] switchCamera error: $e');
        }
      }
      if (mounted) {
        setState(() {
          _currentLens = nextLens;
        });
      }
    } else {
      // BISINDO mode
      try {
        if (_isCameraActive) {
          await _cameraService.switchCamera();
        } else {
          await _cameraService.setLensFacing(nextLens == LensFacing.front);
        }
      } catch (e) {
        debugPrint('[BISINDO_CAMERA] switchCamera error: $e');
      }
      if (mounted) {
        setState(() {
          _currentLens = nextLens;
        });
      }
    }
  }

  @override
  void dispose() {
    _modelSwitchGeneration++;
    _isolatedController.stopContinuous();
    _recognition.setCameraActive(false);
    unawaited(_cameraService.dispose());
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
            Expanded(
              child: Text(
                context.tr('sign.signToText'),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontWeight: FontWeight.w700,
                ),
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
              label: 'SIBI',
              icon: Icons.sort_by_alpha_rounded,
              isSelected: _currentModel == SignLanguageModel.sibi,
              isDisabled: isBusy,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModelOptionTab(
              model: SignLanguageModel.bisindo,
              label: 'BISINDO',
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            context.tr('sign.cameraNotActive'),
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            context.tr('sign.pressStartBelow'),
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
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
                  lensFacing: _currentLens,
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
                      });
                    }
                  },
                  onModelError: (error, path, task) {
                    debugPrint('[SIBI][YOLO] Error: $error');
                    if (mounted) {
                      setState(() {
                        _errorMessage = context.tr('sign.failedLoadYolo', {
                          'error': '$error',
                        });
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
                      text: context.tr(
                        _isCameraActive ? 'sign.live' : 'sign.standby',
                      ),
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
                      text: isSibi ? 'SIBI' : 'BISINDO',
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

              // 3. Top-Right Switch Camera Button [ 🔄 Depan / Belakang ]
              Positioned(
                right: 14,
                top: 11,
                child: _SwitchCameraButton(
                  isFrontCamera: _currentLens == LensFacing.front,
                  isCameraActive: _isCameraActive,
                  onTap: _switchCameraLens,
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
                          Flexible(
                            child: Text(
                              _isSwitchingModel
                                  ? context.tr('sign.loadingModel', {
                                      'model': _currentModel.displayName,
                                    })
                                  : context.tr('sign.preparingPipeline'),
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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

              // 5. BISINDO overlays: live signing pill, manual capture, result badge
              if (!isSibi)
                Obx(() {
                  final liveState = _isolatedController.state.value;
                  switch (liveState) {
                    case BisindoLiveState.manualCountdown:
                      return Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.espressoDark.withValues(
                                  alpha: 0.88,
                                ),
                                border: Border.all(
                                  color: AppColors.goldLight,
                                  width: 2.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${_isolatedController.countdownSeconds.value}',
                                  style: AppTypography.displaySmall.copyWith(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    case BisindoLiveState.manualCapturing:
                      return Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.sosEmergency,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.sosEmergency,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.tr('sign.manualRecordBisindo'),
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    context.tr('sign.framesCount', {
                                      'count':
                                          '${_isolatedController.framesCollected.value}',
                                    }),
                                    style: AppTypography.captionSmall.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      _isolatedController.captureProgress.value,
                                  minHeight: 4,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.sosEmergency,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    case BisindoLiveState.signing:
                      return Positioned(
                        left: 14,
                        bottom: 16,
                        child: _LivePill(
                          text: context.tr('sign.readingGesture'),
                          borderColor: AppColors.sosEmergency,
                          leading: const _PulsingDot(
                            color: AppColors.sosEmergency,
                          ),
                        ),
                      );
                    case BisindoLiveState.classifying:
                      return Positioned(
                        left: 14,
                        bottom: 16,
                        child: _LivePill(
                          text: context.tr('sign.processing'),
                          borderColor: AppColors.goldLight,
                          leading: const SizedBox.square(
                            dimension: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      );
                    case BisindoLiveState.recognized:
                      return Positioned(
                        right: 16,
                        bottom: 16,
                        child: _GestureCandidateLoader(
                          label: _isolatedController.detectedLabel.value,
                          progress: 1.0,
                          isConfirmed: true,
                        ),
                      );
                    case BisindoLiveState.listening:
                      return Positioned(
                        left: 14,
                        bottom: 16,
                        child: _LivePill(
                          text: context.tr('sign.readyDoSign'),
                          borderColor: AppColors.emeraldIslamic,
                          leading: const Icon(
                            Icons.front_hand_rounded,
                            size: 13,
                            color: AppColors.goldLight,
                          ),
                        ),
                      );
                    case BisindoLiveState.initializing:
                    case BisindoLiveState.stopped:
                    case BisindoLiveState.rejected:
                    case BisindoLiveState.error:
                      return const SizedBox.shrink();
                  }
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
                  context.tr('sign.aiTranscript'),
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
                  context.tr('sign.startSigningHint'),
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
                      context.tr('sign.listen'),
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

  /// Compact live status for continuous BISINDO detection + manual fallback.
  Widget _buildRecognitionStatus() {
    final isDark = AppColors.isDark(context);
    final gold = _accent(context);

    return Obx(() {
      final liveState = _isolatedController.state.value;
      final conf = _isolatedController.confidenceScore.value;
      final progress = _isolatedController.captureProgress.value;
      final frames = _isolatedController.framesCollected.value;
      final statusText = _getLocalizedStateStatusText(context, liveState);

      final isRecognized = liveState == BisindoLiveState.recognized;
      final isRejected =
          liveState == BisindoLiveState.rejected ||
          liveState == BisindoLiveState.error;
      final isSigning = liveState == BisindoLiveState.signing;
      final isClassifying = liveState == BisindoLiveState.classifying;
      final isManualCountdown = liveState == BisindoLiveState.manualCountdown;
      final isManualCapturing = liveState == BisindoLiveState.manualCapturing;
      final isRecordingVisual = isSigning || isManualCapturing;

      final canManual =
          _isCameraActive &&
          (liveState == BisindoLiveState.listening ||
              liveState == BisindoLiveState.recognized ||
              liveState == BisindoLiveState.rejected);

      final Color accentColor = isRecognized
          ? AppColors.emeraldIslamic
          : isRejected
          ? AppColors.distanceWarning
          : isRecordingVisual
          ? AppColors.sosEmergency
          : gold;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecognized || isRejected || isRecordingVisual
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.cardBorderColor(context),
            width: isRecognized || isRejected || isRecordingVisual ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isRecognized
                      ? Icons.check_circle_rounded
                      : isRejected
                      ? Icons.info_outline_rounded
                      : isRecordingVisual
                      ? Icons.fiber_manual_record_rounded
                      : Icons.front_hand_rounded,
                  size: 20,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: AppTypography.titleSmall.copyWith(
                      color: isRecognized
                          ? AppColors.emeraldIslamic
                          : AppColors.textHeadingColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isRecognized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldIslamic.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(conf * 100).toStringAsFixed(1)}%',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.emeraldIslamic,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSigning ||
                isClassifying ||
                isManualCountdown ||
                isManualCapturing) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: isClassifying || isManualCountdown ? null : progress,
                  minHeight: 6,
                  backgroundColor: gold.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isManualCountdown
                    ? context.tr('sign.preparingManualRecord')
                    : isManualCapturing
                    ? context.tr('sign.manualRecordProgress', {
                        'frames': '$frames',
                        'seconds': ((1.0 - progress) * 2.8).toStringAsFixed(1),
                      })
                    : isSigning
                    ? context.tr('sign.lowerHandHint', {'frames': '$frames'})
                    : context.tr('sign.processingModelMotionGru'),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isCameraActive
                        ? context.tr('sign.autoDetectActive')
                        : context.tr('sign.pressStartForAuto'),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                ),
                // Temporary manual fallback.
                TextButton.icon(
                  onPressed: canManual
                      ? () => _isolatedController.startCaptureSession()
                      : null,
                  icon: const Icon(
                    Icons.radio_button_checked_rounded,
                    size: 16,
                  ),
                  label: Text(
                    context.tr('sign.manualRecord'),
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: gold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. STOP / MULAI
              Expanded(
                child: _RoundControl(
                  label: _isCameraActive
                      ? context.tr('sign.stop')
                      : context.tr('sign.start'),
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
              ),
              const SizedBox(width: 8),
              // 2. SPASI
              Expanded(
                child: _RoundControl(
                  label: context.tr('sign.space'),
                  icon: Icons.space_bar_rounded,
                  bgColor: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.canvasCreamSubtle,
                  borderColor: isDark
                      ? AppColors.darkOutline
                      : AppColors.tanLight,
                  iconColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.espressoDark,
                  onTap: _recognition.insertSpace,
                ),
              ),
              const SizedBox(width: 8),
              // 3. HAPUS
              Expanded(
                child: _RoundControl(
                  label: context.tr('sign.delete'),
                  icon: Icons.backspace_rounded,
                  bgColor: isDark
                      ? AppColors.secondaryContainer.withValues(alpha: 0.25)
                      : AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderColor: AppColors.distanceWarning.withValues(alpha: 0.5),
                  iconColor: AppColors.distanceWarning,
                  onTap: _recognition.deleteLast,
                ),
              ),
              const SizedBox(width: 8),
              // 4. RESET
              Expanded(
                child: _RoundControl(
                  label: context.tr('sign.reset'),
                  icon: Icons.restart_alt_rounded,
                  bgColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  borderColor: AppColors.outlineVariant,
                  iconColor: AppColors.textMuted,
                  onTap: _recognition.resetTranscript,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _currentModel == SignLanguageModel.sibi
                ? context.tr('sign.holdPositionHint')
                : context.tr('sign.signWordHint'),
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.goldLight : AppColors.espressoMedium,
              fontWeight: FontWeight.w600,
            ),
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
                  ? context.tr('sign.readingAloud')
                  : raw.isEmpty
                  ? context.tr('sign.speakEmpty')
                  : context.tr('sign.speakResult'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            ? context.tr('sign.sibiInstructions')
            : context.tr('sign.bisindoInstructions'),
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
              context.tr('sign.retry'),
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedStateStatusText(
    BuildContext context,
    BisindoLiveState liveState,
  ) {
    switch (liveState) {
      case BisindoLiveState.initializing:
        return context.tr('sign.stateInitializing');
      case BisindoLiveState.stopped:
        return context.tr('sign.stateStopped');
      case BisindoLiveState.listening:
        return context.tr('sign.stateListening');
      case BisindoLiveState.signing:
        return context.tr('sign.stateSigning');
      case BisindoLiveState.classifying:
        return context.tr('sign.stateClassifying');
      case BisindoLiveState.recognized:
        return context.tr('sign.stateRecognized', {
          'label': _isolatedController.detectedLabel.value.toUpperCase(),
        });
      case BisindoLiveState.rejected:
        return _isolatedController.guidanceMessage.value.isNotEmpty
            ? _isolatedController.guidanceMessage.value
            : context.tr('sign.stateRejected');
      case BisindoLiveState.manualCountdown:
        return context.tr('sign.stateManualCountdown', {
          'seconds': '${_isolatedController.countdownSeconds.value}',
        });
      case BisindoLiveState.manualCapturing:
        return context.tr('sign.stateManualCapturing');
      case BisindoLiveState.error:
        return _isolatedController.guidanceMessage.value.isNotEmpty
            ? _isolatedController.guidanceMessage.value
            : context.tr('sign.stateError');
    }
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

    final trimmed = label.trim();
    final isSingleChar = trimmed.length <= 1;
    final display = trimmed.toUpperCase();

    final double fontSize = isSingleChar
        ? 22.0
        : display.length <= 4
        ? 16.0
        : display.length <= 7
        ? 14.0
        : 12.0;

    return CustomPaint(
      foregroundPainter: _CapsuleProgressPainter(
        progress: progress.clamp(0.0, 1.0),
        progressColor: isConfirmed
            ? AppColors.accentGoldStar
            : AppColors.goldLight,
        trackColor: Colors.white.withValues(alpha: 0.25),
        strokeWidth: 3.5,
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        child: AnimatedScale(
          scale: isConfirmed ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
            padding: EdgeInsets.symmetric(
              horizontal: isSingleChar ? 10 : 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.espressoDark,
              borderRadius: BorderRadius.circular(23),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  display,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dynamic stadium/capsule progress ring starting at 12 o'clock
class _CapsuleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _CapsuleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final insetRect = rect.deflate(strokeWidth / 2);
    final radius = (insetRect.height / 2).clamp(0.0, insetRect.width / 2);

    final path = Path();
    final topCenter = Offset(
      insetRect.left + insetRect.width / 2,
      insetRect.top,
    );
    path.moveTo(topCenter.dx, topCenter.dy);

    // 1. Top edge: center to top-right
    path.lineTo(insetRect.right - radius, insetRect.top);
    // 2. Top-right arc
    path.arcToPoint(
      Offset(insetRect.right, insetRect.top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 3. Right edge
    path.lineTo(insetRect.right, insetRect.bottom - radius);
    // 4. Bottom-right arc
    path.arcToPoint(
      Offset(insetRect.right - radius, insetRect.bottom),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 5. Bottom edge
    path.lineTo(insetRect.left + radius, insetRect.bottom);
    // 6. Bottom-left arc
    path.arcToPoint(
      Offset(insetRect.left, insetRect.bottom - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 7. Left edge
    path.lineTo(insetRect.left, insetRect.top + radius);
    // 8. Top-left arc
    path.arcToPoint(
      Offset(insetRect.left + radius, insetRect.top),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 9. Back to top center
    path.lineTo(topCenter.dx, topCenter.dy);

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, trackPaint);

    if (progress <= 0.001) return;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractLength = metric.length * progress.clamp(0.0, 1.0);
    final extractPath = metric.extractPath(0, extractLength);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CapsuleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
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
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.captionSmall.copyWith(
            color: iconColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Floating Switch Camera Button positioned on the camera preview panel.
class _SwitchCameraButton extends StatelessWidget {
  final bool isFrontCamera;
  final bool isCameraActive;
  final VoidCallback onTap;

  const _SwitchCameraButton({
    required this.isFrontCamera,
    required this.isCameraActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortLabel = isFrontCamera
        ? context.tr('sign.frontCamera')
        : context.tr('sign.backCamera');

    return Semantics(
      button: true,
      label: context.tr(
        isFrontCamera ? 'sign.switchToBack' : 'sign.switchToFront',
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isCameraActive
                    ? AppColors.goldPrimary.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cameraswitch_rounded,
                  size: 15,
                  color: isCameraActive ? AppColors.goldPrimary : Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  shortLabel,
                  style: AppTypography.captionSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small translucent status pill on the camera preview (BISINDO live mode).
class _LivePill extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Widget leading;

  const _LivePill({
    required this.text,
    required this.borderColor,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTypography.captionSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing recording dot used while a BISINDO gesture is being read.
class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
