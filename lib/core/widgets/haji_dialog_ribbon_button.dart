import 'package:flutter/material.dart';
import '../theme/theme_context.dart';
import 'ribbon_fold_painter.dart';

/// Standardized protruding ribbon action button for HajiCare modal dialogs.
///
/// Features the signature folded ribbon 3D corner flap and calibrated
/// high-contrast brand styling across both Light and Dark modes.
class HajiDialogRibbonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const HajiDialogRibbonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final isDark = hc.isDark;
    final buttonBg = isDark ? hc.accent : hc.primary;
    final buttonTextColor = isDark ? hc.onPrimary : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ribbon fold triangle at the top-right corner
        Positioned(
          top: -10,
          right: 0,
          child: CustomPaint(
            size: const Size(10, 10),
            painter: RibbonFoldPainter(
              color: isDark ? const Color(0xFF140D08) : const Color(0xFF1B110B),
            ),
          ),
        ),

        // Main Pill Submit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(5),
            ),
            child: Ink(
              decoration: BoxDecoration(
                color: buttonBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(5),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 13.5,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: buttonTextColor,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: buttonTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.8,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
