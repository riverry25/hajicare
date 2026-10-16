import 'package:flutter/material.dart';
import '../theme/theme_context.dart';

/// Standardized floating hero card header for HajiCare modal dialogs.
///
/// Implements the signature HajiCare floating header:
/// - Rich Espresso gradient background with calibrated gold ambient glows
/// - Circular icon container with calibrated gold border
/// - Uppercase letterspaced badge text with WCAG AAA contrast in both Light & Dark mode
/// - Optional close button
class HajiDialogHeroHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onClose;
  final double height;

  const HajiDialogHeroHeader({
    super.key,
    required this.icon,
    required this.title,
    this.onClose,
    this.height = 86,
  });

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: hc.dialogHeroGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hc.dialogHeroAccent.withValues(alpha: 0.40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: hc.brandDark.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient Background Circular Glows
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hc.dialogHeroAccent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -15,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hc.dialogHeroAccent.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Center Hero Graphic
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hc.dialogHeroAccent.withValues(alpha: 0.20),
                    border: Border.all(
                      color: hc.dialogHeroAccent.withValues(alpha: 0.50),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, color: hc.dialogHeroAccent, size: 20),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: hc.dialogHeroAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Optional close button
          if (onClose != null)
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                tooltip: 'Tutup',
                onPressed: onClose,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.close_rounded),
                color: hc.dialogHeroForeground.withValues(alpha: 0.85),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
