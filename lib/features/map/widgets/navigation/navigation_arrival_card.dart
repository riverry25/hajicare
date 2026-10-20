import 'package:flutter/material.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../controllers/map_controller.dart';

/// Celebratory arrival card displayed when user reaches the destination (< 20m).
class NavigationArrivalCard extends StatelessWidget {
  final MapController mapCtrl;

  const NavigationArrivalCard({super.key, required this.mapCtrl});

  @override
  Widget build(BuildContext context) {
    final destTitle = mapCtrl.destinationTitle.value.isNotEmpty
        ? mapCtrl.destinationTitle.value
        : context.tr('maps.yourDestination');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxSheetWidth,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: context.hc.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.hc.success.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.hc.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebratory Sage Checkmark Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      context.hc.success,
                      context.hc.success.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.hc.success.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 42,
                  color: context.hc.onPrimary,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                context.tr('maps.alhamdulillah'),
                style: context.text.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.hc.success,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('maps.arrivedNotice'),
                style: context.text.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.hc.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Destination Name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.hc.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.hc.border, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: context.hc.danger,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        destTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.hc.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Selesai Button
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      mapCtrl.exitNavigation();
                      mapCtrl.clearRoute();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.hc.success,
                      foregroundColor: context.hc.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 2,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.tr('maps.finish'),
                        style: context.text.labelLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.hc.onPrimary,
                        ),
                      ),
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
}
