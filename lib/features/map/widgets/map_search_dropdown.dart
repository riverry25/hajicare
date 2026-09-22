import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/map_controller.dart';
import '../models/map_search_result.dart';

/// Floating dropdown overlay that displays search states and geocoded results.
class MapSearchDropdown extends StatelessWidget {
  final MapController mapCtrl;
  final ValueChanged<MapSearchResult> onSelect;

  const MapSearchDropdown({
    super.key,
    required this.mapCtrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = mapCtrl.searchState.value;
      if (state == MapSearchState.idle) {
        return const SizedBox.shrink();
      }

      final isDark = AppColors.isDark(context);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.98)
              : AppColors.surfaceWhite.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.goldLight.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Material(
            color: Colors.transparent,
            child: _buildContent(context, state, isDark),
          ),
        ),
      );
    });
  }

  Widget _buildContent(
    BuildContext context,
    MapSearchState state,
    bool isDark,
  ) {
    switch (state) {
      case MapSearchState.loading:
        return _buildLoadingState(isDark);
      case MapSearchState.empty:
        return _buildMessageState(
          isDark: isDark,
          icon: Icons.location_off_outlined,
          message: 'Tidak ditemukan lokasi.',
          iconColor: isDark ? Colors.white60 : AppColors.textMuted,
        );
      case MapSearchState.error:
        final msg = mapCtrl.searchErrorMessage.value.isNotEmpty
            ? mapCtrl.searchErrorMessage.value
            : 'Gagal mencari lokasi. Coba lagi.';
        return _buildMessageState(
          isDark: isDark,
          icon: Icons.error_outline_rounded,
          message: msg,
          iconColor: const Color(0xFFE53935),
        );
      case MapSearchState.results:
        return _buildResultsList(context, isDark);
      case MapSearchState.history:
        return _buildHistoryList(context, isDark);
      case MapSearchState.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Mencari lokasi...',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextHeading
                  : AppColors.espressoDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required bool isDark,
    required IconData icon,
    required String message,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.espressoDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, bool isDark) {
    final results = mapCtrl.searchResults;
    if (results.isEmpty) {
      return _buildMessageState(
        isDark: isDark,
        icon: Icons.location_off_outlined,
        message: 'Tidak ditemukan lokasi.',
        iconColor: isDark ? Colors.white60 : AppColors.textMuted,
      );
    }

    final userLoc = mapCtrl.currentUserLocation.value;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.8,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.espressoDark.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final item = results[index];

        // Compute distance label
        String? distanceLabel;
        if (userLoc != null) {
          final distM = mapCtrl.calculateDistanceMeters(
            userLoc,
            item.coordinate,
          );
          distanceLabel = MapController.formatDistance(distM);
        }

        return InkWell(
          onTap: () {
            FocusScope.of(context).unfocus();
            onSelect(item);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.goldPrimary.withValues(alpha: 0.16)
                        : AppColors.goldLight.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.goldPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextHeading
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (item.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Distance badge on the right
                if (distanceLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.goldPrimary.withValues(alpha: 0.14)
                          : AppColors.goldLight.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      distanceLabel,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.goldPrimary
                            : AppColors.espressoDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.north_west_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppColors.textMuted.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context, bool isDark) {
    final history = mapCtrl.searchHistory;
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Recent search title + Clear all button
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.goldPrimary
                        : AppColors.espressoDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pencarian Terakhir',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextHeading
                          : AppColors.espressoDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => mapCtrl.clearSearchHistory(),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    'Hapus Semua',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.goldPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.espressoDark.withValues(alpha: 0.06),
        ),
        // List of history items
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.8,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.espressoDark.withValues(alpha: 0.06),
            ),
            itemBuilder: (context, index) {
              final item = history[index];
              return InkWell(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  onSelect(item);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.canvasCream,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: isDark
                              ? Colors.white70
                              : AppColors.espressoDark.withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextHeading
                                    : AppColors.espressoDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (item.address.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.captionSmall.copyWith(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: isDark
                            ? Colors.white38
                            : AppColors.textMuted.withValues(alpha: 0.6),
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip: 'Hapus dari riwayat',
                        onPressed: () =>
                            mapCtrl.removeSearchHistoryItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
