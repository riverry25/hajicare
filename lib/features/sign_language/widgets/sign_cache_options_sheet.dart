import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';

/// Bottom sheet dialog untuk manajemen unduhan katalog video cloud dan cache lokal.
class SignCacheOptionsSheet extends StatelessWidget {
  final TextToSignController controller;

  const SignCacheOptionsSheet({super.key, required this.controller});

  static void show(BuildContext context, TextToSignController controller) {
    HapticFeedback.lightImpact();
    Get.bottomSheet(
      SignCacheOptionsSheet(controller: controller),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title & Description
          Text(
            context.tr('sign.downloadSettingsTitle'),
            style: textTheme.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('sign.downloadSettingsDesc'),
            style: textTheme.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action 1: Refresh Cloud Catalog
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sync_rounded, color: colors.accent, size: 22),
            ),
            title: Text(
              context.tr('sign.refreshCloudCatalog'),
              style: textTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            subtitle: Text(
              context.tr('sign.syncCatalogSubtitle'),
              style: textTheme.labelSmall.copyWith(color: colors.textSecondary),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Get.back();
              controller.loadAvailableVideos(forceRefresh: true);
            },
          ),
          Divider(color: colors.border),

          // Action 2: Delete Downloaded Videos
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: colors.danger,
                size: 22,
              ),
            ),
            title: Text(
              context.tr('sign.deleteDownloadedVideos'),
              style: textTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.danger,
              ),
            ),
            subtitle: Text(
              context.tr('sign.clearStorageSubtitle'),
              style: textTheme.labelSmall.copyWith(color: colors.textSecondary),
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              Get.back();
              controller.clearDownloadedVideos();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
