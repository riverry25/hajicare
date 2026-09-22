import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/hajj_dua_repository.dart';
import '../../models/hajj_dua_category.dart';
import '../widgets/dua_card.dart';

class HajjDuaCategoryScreen extends StatelessWidget {
  final HajjDuaCategory category;
  final HajjDuaRepository repository;
  final String? initiallyExpandedDuaId;

  const HajjDuaCategoryScreen({
    super.key,
    required this.category,
    this.repository = const HajjDuaRepository(),
    this.initiallyExpandedDuaId,
  });

  @override
  Widget build(BuildContext context) {
    final duas = repository.getDuasForStage(category.stage);
    final scaffoldColor = AppColors.scaffoldColor(context);

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Kembali',
        ),
        title: Text(
          category.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              key: Key('category_screen_${category.stage.name}'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              children: [
                _CategoryIntroduction(category: category),
                const SizedBox(height: AppSpacing.lg),
                if (duas.isEmpty)
                  _EmptyCategoryState(category: category)
                else ...[
                  Text(
                    '${duas.length} bacaan',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...duas.map(
                    (dua) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DuaCard(
                        key: Key('dua_card_${dua.id}'),
                        dua: dua,
                        initiallyExpanded: dua.id == initiallyExpandedDuaId,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIntroduction extends StatelessWidget {
  final HajjDuaCategory category;

  const _CategoryIntroduction({required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.title,
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.textHeadingColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textBodyColor(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.goldPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Bacaan di bagian ini adalah panduan. Jangan menganggap setiap bacaan sebagai doa wajib atau bacaan tetap untuk setiap tahapan.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textBodyColor(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  final HajjDuaCategory category;

  const _EmptyCategoryState({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('empty_category_${category.stage.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineColor(context)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fact_check_outlined,
            color: AppColors.distanceWarning,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Konten sedang diverifikasi',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textHeadingColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada teks bacaan bersumber yang dapat ditampilkan untuk kategori ini. Struktur kategori tetap tersedia agar konten dapat ditambahkan setelah ditelaah.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textBodyColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
