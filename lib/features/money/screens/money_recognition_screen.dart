import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class MoneyRecognitionScreen extends StatefulWidget {
  const MoneyRecognitionScreen({super.key});

  @override
  State<MoneyRecognitionScreen> createState() => _MoneyRecognitionScreenState();
}

class _MoneyRecognitionScreenState extends State<MoneyRecognitionScreen> {
  CameraController? _cameraController;
  FlutterTts? _tts;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTts();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _cameraController =
          CameraController(cameras.first, ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts!.setLanguage('id-ID');
    await _tts!.setPitch(1.0);
  }

  void _speak() {
    _tts?.speak('Lima Puluh Riyal');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Feed
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: CircularProgressIndicator(color: AppColors.tanMedium),
                  ),
          ),

          // Foreground Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdgeGutter,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      Text(
                        'Pindai Uang Riyal',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_off, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Center Scanning Guide
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 280,
                            height: 160,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    AppColors.goldLight.withValues(alpha: 0.8),
                                width: 3,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Center(
                              child: Container(
                                width: double.infinity,
                                height: 2,
                                color: AppColors.statusPositive,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'Arahkan kamera ke uang kertas',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Result Panel (Scroll-safe)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.statusPositive,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm2),
                          Text(
                            'Terdeteksi',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.statusPositive,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '50',
                            style: AppTypography.heroNumberLarge.copyWith(
                              color: AppColors.espressoDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Riyal',
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.tanMedium,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Lima Puluh Riyal Saudi',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textBody,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Audio Feedback Button
                      ElevatedButton(
                        onPressed: _speak,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ulangi Suara',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.espressoDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
