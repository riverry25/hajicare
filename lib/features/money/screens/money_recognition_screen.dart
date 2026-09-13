
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isProcessing = false;
  
  String _detectedNumber = '';
  String _detectedCurrency = '';
  String _detectedSpoken = '';
  double _confidence = 0.0;
  bool _hasResult = false;

  final Map<String, Map<String, String>> _labelInfo = {
    'fifty halalas': {'number': '50', 'currency': 'Halala', 'spoken': 'Lima Puluh Halala'},
    'fifty riyal': {'number': '50', 'currency': 'Riyal', 'spoken': 'Lima Puluh Riyal'},
    'five halalas': {'number': '5', 'currency': 'Halala', 'spoken': 'Lima Halala'},
    'five hundred riyal': {'number': '500', 'currency': 'Riyal', 'spoken': 'Lima Ratus Riyal'},
    'five riyal': {'number': '5', 'currency': 'Riyal', 'spoken': 'Lima Riyal'},
    'one halalas': {'number': '1', 'currency': 'Halala', 'spoken': 'Satu Halala'},
    'one hundred riyal': {'number': '100', 'currency': 'Riyal', 'spoken': 'Seratus Riyal'},
    'one riyal': {'number': '1', 'currency': 'Riyal', 'spoken': 'Satu Riyal'},
    'ten halalas': {'number': '10', 'currency': 'Halala', 'spoken': 'Sepuluh Halala'},
    'ten riyal': {'number': '10', 'currency': 'Riyal', 'spoken': 'Sepuluh Riyal'},
    'twenty five halalas': {'number': '25', 'currency': 'Halala', 'spoken': 'Dua Puluh Lima Halala'},
    'twenty riyal': {'number': '20', 'currency': 'Riyal', 'spoken': 'Dua Puluh Riyal'},
    'two hundred riyal': {'number': '200', 'currency': 'Riyal', 'spoken': 'Dua Ratus Riyal'},
    'two riyal': {'number': '2', 'currency': 'Riyal', 'spoken': 'Dua Riyal'},
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTts();
    _initModel();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _cameraController = CameraController(
        cameras.first, 
        ResolutionPreset.medium,
        enableAudio: false,
      );
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

  Future<void> _initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/best_float16.tflite');
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((label) => label.isNotEmpty)
          .toList();
      debugPrint('Model loaded successfully');
      debugPrint('Labels: $_labels');
    } catch (e) {
      debugPrint('Model init error: $e');
      if (mounted) {
        Get.snackbar(
          'Error', 
          'Gagal memuat model deteksi',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _scanImage() async {
    debugPrint('BUTTON PRESSED - starting detection');
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing) return;
    if (_interpreter == null) {
      Get.snackbar('Error', 'Model belum siap', colorText: Colors.white);
      return;
    }

    setState(() {
      _isProcessing = true;
      _hasResult = false;
    });

    try {
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Gagal decode gambar');
      
      debugPrint('IMAGE CAPTURED - size: ${image.width}x${image.height}');

      // Resize ke 640x640
      final resizedImage = img.copyResize(image, width: 640, height: 640);

      // Siapkan input tensor [1, 640, 640, 3]
      var input = List.generate(
        1,
        (i) => List.generate(
          640,
          (y) => List.generate(
            640,
            (x) => List.filled(3, 0.0),
          ),
        ),
      );

      // Normalisasi nilai pixel ke 0.0 - 1.0
      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }

      // Siapkan output tensor [1, 300, 6]
      var output = List.generate(
        1,
        (i) => List.generate(
          300,
          (j) => List.filled(6, 0.0),
        ),
      );

      // Jalankan inference
      debugPrint('Menjalankan inference...');
      _interpreter!.run(input, output);
      debugPrint('Inference selesai');
      
      debugPrint('RAW OUTPUT TENSOR: $output');

      // Parsing output tensor (Cari confidence score tertinggi)
      double maxScore = 0.0;
      int bestClassIndex = -1;

      for (int i = 0; i < 300; i++) {
        final detection = output[0][i];
        final score = detection[4]; // index 4 biasanya confidence
        final classIndex = detection[5].toInt(); // index 5 class index

        if (score > maxScore) {
          maxScore = score;
          bestClassIndex = classIndex;
        }
      }

      debugPrint('DETECTED CLASS INDEX: $bestClassIndex, CONFIDENCE: $maxScore');

      // Post-processing hasil
      if (maxScore >= 0.5 && bestClassIndex >= 0 && bestClassIndex < _labels.length) {
        final label = _labels[bestClassIndex];
        final info = _labelInfo[label];
        
        setState(() {
          if (info != null) {
            _detectedNumber = info['number'] ?? '';
            _detectedCurrency = info['currency'] ?? '';
            _detectedSpoken = info['spoken'] ?? label;
          } else {
            _detectedNumber = '';
            _detectedCurrency = label;
            _detectedSpoken = label;
          }
          _confidence = maxScore;
          _hasResult = true;
        });
        
        _speak(_detectedSpoken);
      } else {
        setState(() {
          _hasResult = false;
        });
        _tts?.speak('Uang tidak terdeteksi, coba scan ulang');
        Get.snackbar(
          'Tidak Terdeteksi', 
          'Uang tidak terdeteksi, silakan coba lagi.',
          colorText: Colors.white,
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      debugPrint('Inference error: $e');
      Get.snackbar(
        'Error', 
        'Gagal memproses gambar',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _speak(String text) {
    if (text.isNotEmpty) {
      _tts?.speak(text);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tts?.stop();
    _interpreter?.close();
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
                                color: AppColors.goldLight.withValues(alpha: 0.8),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Center(
                              child: _isProcessing 
                                ? const CircularProgressIndicator(color: AppColors.goldLight)
                                : Container(
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
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'Arahkan kamera ke uang kertas',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Tombol Scan yang ditambahkan
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _scanImage,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(_isProcessing ? 'Memproses...' : 'Pindai Sekarang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Result Panel (Scroll-safe)
                if (_hasResult)
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
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                              'Terdeteksi (${(_confidence * 100).toStringAsFixed(0)}%)',
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
                              _detectedNumber,
                              style: AppTypography.heroNumberLarge.copyWith(
                                color: AppColors.espressoDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _detectedCurrency,
                              style: AppTypography.displayMedium.copyWith(
                                color: AppColors.tanMedium,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _detectedSpoken,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Audio Feedback Button
                        ElevatedButton(
                          onPressed: () => _speak(_detectedSpoken),
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
