import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

/// Modal dialog with integrated camera barcode scanner to scan HajiCare Room QR Codes.
class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  /// Shows the full-screen / large modal scanner dialog and returns the scanned room code.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const QrScannerDialog(),
    );
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasDetected = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) continue;

      // Extract room code:
      // Case 1: URL with query parameter 'code=' or 'room=' or path segment
      // Case 2: Plain uppercase alphanumeric (6-8 characters)
      String extracted = rawValue;
      final uri = Uri.tryParse(rawValue);
      if (uri != null) {
        if (uri.queryParameters.containsKey('code')) {
          extracted = uri.queryParameters['code']!;
        } else if (uri.queryParameters.containsKey('room')) {
          extracted = uri.queryParameters['room']!;
        } else if (uri.pathSegments.isNotEmpty) {
          for (final seg in uri.pathSegments.reversed) {
            final clean = seg.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
            if (clean.length >= 6 && clean.length <= 8) {
              extracted = clean;
              break;
            }
          }
        }
      }

      // Filter to uppercase alphanumeric
      extracted = extracted.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

      if (extracted.length >= 4 && extracted.length <= 12) {
        _hasDetected = true;
        Navigator.of(context).pop(extracted);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.surfaceVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan QR Code Room',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeadingColor(context),
                            ),
                          ),
                          Text(
                            'Arahkan kamera ke layar pendamping',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textBodyColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textBodyColor(context),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Camera Scanner Viewport
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off_rounded,
                                  size: 48,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Kamera Tidak Tersedia',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.textHeadingColor(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pastikan izin kamera telah diberikan atau gunakan input kode manual.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.textBodyColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Visual Scan Reticle Overlay
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor, width: 2.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Corner indicators
                          Positioned(
                            top: -2,
                            left: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                  left: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                  right: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            left: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                  left: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                  right: BorderSide(
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Controls Floating Bar (Torch & Flip)
                    Positioned(
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isTorchOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: _isTorchOn
                                    ? AppColors.accentGoldStar
                                    : Colors.white,
                              ),
                              onPressed: () async {
                                await _scannerController.toggleTorch();
                                setState(() => _isTorchOn = !_isTorchOn);
                              },
                              tooltip: 'Senter',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  _scannerController.switchCamera(),
                              tooltip: 'Ganti Kamera',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'QR code terdapat pada menu Room Pemantauan di aplikasi Pendamping atau Admin.',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textBodyColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
