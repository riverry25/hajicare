import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';

/// Bagian unduh paket offline bahasa isyarat per kategori secara dinamis dan responsif.
class SignOfflinePackagesSection extends StatelessWidget {
  final TextToSignController controller;

  const SignOfflinePackagesSection({super.key, required this.controller});

  String _getLocalizedPackageTitle(
    BuildContext context,
    String category,
    String fallback,
  ) {
    switch (category.toLowerCase().trim()) {
      case 'health':
        return context.tr('sign.pkgHealth');
      case 'hajj':
        return context.tr('sign.pkgHajj');
      case 'emergency':
        return context.tr('sign.pkgEmergency');
      case 'alphabet':
        return context.tr('sign.pkgAlphabet');
      case 'question':
        return context.tr('sign.pkgQuestion');
      case 'pronoun':
        return context.tr('sign.pkgPronoun');
      case 'movement':
        return context.tr('sign.pkgMovement');
      case 'activity':
        return context.tr('sign.pkgActivity');
      case 'greeting':
        return context.tr('sign.pkgGreeting');
      case 'general':
        return context.tr('sign.pkgGeneral');
      default:
        return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(Icons.downloading_rounded, size: 20, color: colors.accent),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.tr('sign.offlinePackagesTitle'),
              style: textTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('sign.offlinePackagesSub'),
          style: textTheme.labelSmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Responsive Cards (Horizontal carousel on phones, Grid on wide screens)
        Obx(() {
          final packages = controller.dynamicPackageCategories;
          if (packages.isEmpty) {
            return const SizedBox.shrink();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisExtent: 220,
                  ),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    return _buildPackageCard(context, packages[index]);
                  },
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: packages.map((pkg) {
                    return Container(
                      width: 224,
                      constraints: const BoxConstraints(minHeight: 215),
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _buildPackageCard(context, pkg),
                    );
                  }).toList(),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildPackageCard(BuildContext context, CategoryPackageInfo package) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(() {
      final isDownloading =
          controller.categoryDownloading[package.category] == true;
      final progress =
          controller.categoryDownloadProgress[package.category] ?? 0.0;
      final isFullyDownloaded = package.isFullyDownloaded;

      return Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDownloading ? colors.accent : colors.border,
            width: isDownloading ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Icon + Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceSand,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(package.icon, size: 20, color: colors.primary),
                ),
                if (isDownloading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  )
                else if (isFullyDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: colors.success,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          context.tr('sign.statusOffline'),
                          style: textTheme.labelSmall.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      context.tr('sign.cloudCount', {
                        'count': '${package.remoteCount}',
                      }),
                      style: textTheme.labelSmall.copyWith(
                        color: colors.accentText,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Package Title
            Text(
              _getLocalizedPackageTitle(
                context,
                package.category,
                package.title,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),

            // Subtitle / Preview of Items
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Text(
                package.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Bottom CTA / Progress
            if (isDownloading)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress > 0 ? progress : null,
                            minHeight: 4,
                            backgroundColor: colors.surfaceSand,
                            valueColor: AlwaysStoppedAnimation(colors.accent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('sign.downloadingPercent', {
                            'percent': '${(progress * 100).toInt()}',
                          }),
                          style: textTheme.labelSmall.copyWith(
                            fontSize: 10,
                            color: colors.accentText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.cancelCategoryPackageDownload(
                        package.category,
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: colors.danger.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: colors.danger,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            context.tr('sign.cancelDownload'),
                            style: textTheme.labelSmall.copyWith(
                              color: colors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (isFullyDownloaded)
              Container(
                width: double.infinity,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: colors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: colors.success,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        context.tr('sign.savedComplete'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.downloadCategoryPackage(package.category);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    context.tr('sign.downloadPackage', {
                      'count': '${package.remoteCount}',
                    }),
                    style: textTheme.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
