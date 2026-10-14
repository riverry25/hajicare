import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/haji_transparent_dialog.dart';

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

class _QrScannerDialogState extends State<QrScannerDialog>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late final AnimationController _scanAnimationController;
  late final Animation<double> _scanAnimation;

  bool _hasDetected = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scanAnimation = CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
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
            final clean = seg.trim().toUpperCase().replaceAll(
              RegExp(r'[^A-Z0-9]'),
              '',
            );
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
    final hc = context.hc;
    final cardBg = hc.surface;
    final primaryColor = hc.brand;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;

    return HajiTransparentDialog(
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
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: hc.surfaceSand,
                  border: Border(bottom: BorderSide(color: hc.borderSubtle)),
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
                            style: context.text.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Arahkan kamera ke layar pendamping',
                            style: context.text.bodySmall.copyWith(
                              color: bodyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: headingColor,
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Camera Scanner Viewport
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scanSize = math.min(
                      math.min(
                        constraints.maxWidth * 0.72,
                        constraints.maxHeight * 0.65,
                      ),
                      230.0,
                    );
                    final scanRect = Rect.fromCenter(
                      center: Offset(
                        constraints.maxWidth / 2,
                        constraints.maxHeight / 2 - 10,
                      ),
                      width: scanSize,
                      height: scanSize,
                    );

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: _onDetect,
                            errorBuilder: (context, error) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.videocam_off_rounded,
                                        size: 48,
                                        color: hc.danger,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Kamera Tidak Tersedia',
                                        style: context.text.titleSmall.copyWith(
                                          color: headingColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pastikan izin kamera telah diberikan atau gunakan input kode manual.',
                                        textAlign: TextAlign.center,
                                        style: context.text.bodySmall.copyWith(
                                          color: bodyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Scrim Cutout + Single Smooth Corner Reticle (no double lines)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _QrScannerOverlayPainter(
                              scanWindow: scanRect,
                              borderRadius: 20,
                              cornerColor: primaryColor,
                              scrimColor: Colors.black.withValues(alpha: 0.42),
                              cornerLength: 28,
                              cornerStrokeWidth: 3.5,
                            ),
                          ),
                        ),

                        // Animated Laser Scan Bar
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, _) {
                            final laserTop =
                                scanRect.top +
                                12 +
                                (scanRect.height - 24) * _scanAnimation.value;
                            return Positioned(
                              left: scanRect.left + 12,
                              top: laserTop,
                              width: scanRect.width - 24,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withValues(alpha: 0.0),
                                      primaryColor,
                                      primaryColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(
                                        alpha: 0.65,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Guidance Hint Pill Above Reticle
                        Positioned(
                          top: scanRect.top - 38,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Posisikan QR di dalam bingkai',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                        // Controls Floating Bar (Torch & Flip)
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
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
                                        ? hc.accent
                                        : Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    await _scannerController.toggleTorch();
                                    setState(() => _isTorchOn = !_isTorchOn);
                                  },
                                  tooltip: 'Senter',
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.flip_camera_ios_rounded,
                                    color: Colors.white,
                                    size: 22,
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
                    );
                  },
                ),
              ),

              // Footer Note
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: hc.surfaceSand,
                  border: Border(top: BorderSide(color: hc.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QR code terdapat pada menu Room Pemantauan di aplikasi Pendamping atau Admin.',
                        style: context.text.bodySmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
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

/// Custom painter that creates a camera scrim with a rounded rectangular cutout,
/// a subtle guideline frame, and four seamless curved corner brackets.
class _QrScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;
  final Color cornerColor;
  final Color scrimColor;
  final double cornerLength;
  final double cornerStrokeWidth;

  const _QrScannerOverlayPainter({
    required this.scanWindow,
    this.borderRadius = 20.0,
    required this.cornerColor,
    required this.scrimColor,
    this.cornerLength = 28.0,
    this.cornerStrokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutoutRRect = RRect.fromRectAndRadius(
      scanWindow,
      Radius.circular(borderRadius),
    );

    // 1. Semi-transparent scrim mask
    final screenPath = Path()..addRect(screenRect);
    final cutoutPath = Path()..addRRect(cutoutRRect);
    final scrimPath = Path.combine(
      PathOperation.difference,
      screenPath,
      cutoutPath,
    );

    final scrimPaint = Paint()
      ..color = scrimColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(scrimPath, scrimPaint);

    // 2. Subtle guideline frame along the cutout
    final framePaint = Paint()
      ..color = cornerColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(cutoutRRect, framePaint);

    // 3. Four smooth curved corner brackets (perfectly aligned with cutout)
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = scanWindow.left;
    final top = scanWindow.top;
    final right = scanWindow.right;
    final bottom = scanWindow.bottom;
    final r = borderRadius;
    final cl = cornerLength;

    final cornerPath = Path();

    // Top-Left corner
    cornerPath.moveTo(left, top + cl);
    cornerPath.lineTo(left, top + r);
    cornerPath.arcToPoint(Offset(left + r, top), radius: Radius.circular(r));
    cornerPath.lineTo(left + cl, top);

    // Top-Right corner
    cornerPath.moveTo(right - cl, top);
    cornerPath.lineTo(right - r, top);
    cornerPath.arcToPoint(Offset(right, top + r), radius: Radius.circular(r));
    cornerPath.lineTo(right, top + cl);

    // Bottom-Right corner
    cornerPath.moveTo(right, bottom - cl);
    cornerPath.lineTo(right, bottom - r);
    cornerPath.arcToPoint(
      Offset(right - r, bottom),
      radius: Radius.circular(r),
    );
    cornerPath.lineTo(right - cl, bottom);

    // Bottom-Left corner
    cornerPath.moveTo(left + cl, bottom);
    cornerPath.lineTo(left + r, bottom);
    cornerPath.arcToPoint(Offset(left, bottom - r), radius: Radius.circular(r));
    cornerPath.lineTo(left, bottom - cl);

    canvas.drawPath(cornerPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _QrScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.cornerColor != cornerColor ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
