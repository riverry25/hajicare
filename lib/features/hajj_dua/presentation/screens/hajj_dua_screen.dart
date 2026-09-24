import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/hajj_dua_repository.dart';
import '../../models/hajj_dua.dart';
import '../../models/hajj_dua_category.dart';
import '../../services/hajj_dua_service.dart';
import '../hajj_dua_typography.dart';
import '../widgets/dua_card.dart';
import '../widgets/dua_category_card.dart';
import 'hajj_dua_category_screen.dart';

class HajjDuaScreen extends StatefulWidget {
  final HajjDuaRepository repository;

  const HajjDuaScreen({super.key, this.repository = const HajjDuaRepository()});

  @override
  State<HajjDuaScreen> createState() => _HajjDuaScreenState();
}

class _HajjDuaScreenState extends State<HajjDuaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late final HajjDuaService _service;

  @override
  void initState() {
    super.initState();
    _service = HajjDuaService.instance;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateQuery(String value) {
    setState(() => _query = value.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    _updateQuery('');
  }

  void _openCategory(
    HajjDuaCategory category, {
    String? initiallyExpandedDuaId,
  }) {
    Get.to(
      () => HajjDuaCategoryScreen(
        category: category,
        repository: widget.repository,
        initiallyExpandedDuaId: initiallyExpandedDuaId,
      ),
    );
  }

  void _openDuaDirectly(HajjDua dua) {
    final category = widget.repository.categoryFor(dua.stage);
    if (category != null) {
      _openCategory(category, initiallyExpandedDuaId: dua.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = AppColors.scaffoldColor(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = _query.isEmpty
        ? widget.repository.getAvailableCategories()
        : widget.repository.searchCategories(
            _query,
            languageCode: languageCode,
          );
    final matchingDuas = widget.repository.searchDuas(
      _query,
      languageCode: languageCode,
    );

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: context.tr('hajjDuaBack'),
        ),
        title: Text(
          context.tr('hajjDuaTitle'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HajjDuaTypography.appBarTitle.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _service.cycleTextScale,
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'Ukuran Teks',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              key: const Key('hajj_dua_screen'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              children: [
                const _GuideHeader(),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('hajj_dua_search_field'),
                  controller: _searchController,
                  onChanged: _updateQuery,
                  textInputAction: TextInputAction.search,
                  style: HajjDuaTypography.body.copyWith(
                    color: AppColors.textHeadingColor(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari doa, tahap, arti, atau transliterasi...',
                    hintStyle: HajjDuaTypography.body.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('clear_hajj_dua_search'),
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                            tooltip: context.tr('hajjDuaClearSearch'),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_query.isEmpty) ...[
                  // Recently Viewed Section
                  _RecentlyOpenedSection(
                    service: _service,
                    repository: widget.repository,
                    onDuaTap: _openDuaDirectly,
                  ),
                  // Bookmarked Duas Section
                  _SavedDuasSection(
                    service: _service,
                    repository: widget.repository,
                    onDuaTap: _openDuaDirectly,
                  ),
                  _CategorySection(
                    categories: categories,
                    repository: widget.repository,
                    onCategoryTap: _openCategory,
                  ),
                ] else
                  _SearchResults(
                    query: _query,
                    categories: categories,
                    duas: matchingDuas,
                    repository: widget.repository,
                    onCategoryTap: _openCategory,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [AppColors.espressoDark, AppColors.primary]
              : const [AppColors.primary, AppColors.espressoMedium],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.goldLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('hajjDuaGuideTitle'),
                      style: HajjDuaTypography.screenTitle.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('hajjDuaSubtitle'),
                      style: HajjDuaTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('hajjDuaGuideDescription'),
            style: HajjDuaTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyOpenedSection extends StatelessWidget {
  final HajjDuaService service;
  final HajjDuaRepository repository;
  final ValueChanged<HajjDua> onDuaTap;

  const _RecentlyOpenedSection({
    required this.service,
    required this.repository,
    required this.onDuaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final recentIds = service.recentDuaIds;
      if (recentIds.isEmpty) return const SizedBox.shrink();

      final recentDuas = repository.getDuasByIds(recentIds);
      if (recentDuas.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.goldPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('hajjDuaRecentTitle'),
                style: HajjDuaTypography.sectionTitle.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: recentDuas.map((dua) {
                final title = dua.title ?? context.tr(dua.titleKey);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(title),
                    onPressed: () => onDuaTap(dua),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    });
  }
}

class _SavedDuasSection extends StatelessWidget {
  final HajjDuaService service;
  final HajjDuaRepository repository;
  final ValueChanged<HajjDua> onDuaTap;

  const _SavedDuasSection({
    required this.service,
    required this.repository,
    required this.onDuaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final savedIds = service.bookmarkedIds;
      if (savedIds.isEmpty) return const SizedBox.shrink();

      final savedDuas = repository.getDuasByIds(savedIds);
      if (savedDuas.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: AppColors.goldPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('hajjDuaSavedTitle'),
                style: HajjDuaTypography.sectionTitle.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: savedDuas.map((dua) {
                final title = dua.title ?? context.tr(dua.titleKey);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.goldPrimary,
                    ),
                    label: Text(title),
                    onPressed: () => onDuaTap(dua),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    });
  }
}

class _CategorySection extends StatelessWidget {
  final List<HajjDuaCategory> categories;
  final HajjDuaRepository repository;
  final ValueChanged<HajjDuaCategory> onCategoryTap;

  const _CategorySection({
    required this.categories,
    required this.repository,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          titleKey: 'hajjDuaStagesTitle',
          subtitleKey: 'hajjDuaStagesSubtitle',
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth >= 700;
            final cardWidth = useTwoColumns
                ? (constraints.maxWidth - AppSpacing.md) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: categories
                  .map(
                    (category) => SizedBox(
                      width: cardWidth,
                      child: DuaCategoryCard(
                        key: Key('category_${category.stage.name}'),
                        category: category,
                        duaCount: repository.countForStage(category.stage),
                        onTap: () => onCategoryTap(category),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final String query;
  final List<HajjDuaCategory> categories;
  final List<HajjDua> duas;
  final HajjDuaRepository repository;
  final ValueChanged<HajjDuaCategory> onCategoryTap;

  const _SearchResults({
    required this.query,
    required this.categories,
    required this.duas,
    required this.repository,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && duas.isEmpty) {
      return _EmptySearchState(query: query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          titleKey: 'hajjDuaSearchResults',
          subtitleKey: 'hajjDuaSearchSummary',
          subtitleParams: {
            'categories': categories.length,
            'duas': duas.length,
          },
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SubsectionTitle(label: context.tr('hajjDuaCategorySection')),
          const SizedBox(height: AppSpacing.sm),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DuaCategoryCard(
                key: Key('search_category_${category.stage.name}'),
                category: category,
                duaCount: repository.countForStage(category.stage),
                onTap: () => onCategoryTap(category),
              ),
            ),
          ),
        ],
        if (duas.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SubsectionTitle(label: context.tr('hajjDuaPrayerSection')),
          const SizedBox(height: AppSpacing.sm),
          ...duas.map(
            (dua) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DuaCard(key: Key('search_dua_${dua.id}'), dua: dua),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final Map<String, dynamic>? subtitleParams;

  const _SectionTitle({
    required this.titleKey,
    required this.subtitleKey,
    this.subtitleParams,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(titleKey),
          style: HajjDuaTypography.sectionTitle.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.tr(subtitleKey, subtitleParams),
          style: HajjDuaTypography.caption.copyWith(
            color: AppColors.textBodyColor(context),
          ),
        ),
      ],
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  final String label;

  const _SubsectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: HajjDuaTypography.cardTitle.copyWith(
        color: AppColors.textHeadingColor(context),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String query;

  const _EmptySearchState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('hajj_dua_empty_search'),
      width: double.infinity,
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
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.textSecondaryColor(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum menemukan bacaan',
            textAlign: TextAlign.center,
            style: HajjDuaTypography.cardTitle.copyWith(
              color: AppColors.textHeadingColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Coba gunakan kata kunci lain seperti: thawaf, sa\'i, wukuf, zamzam, atau talbiyah.',
            textAlign: TextAlign.center,
            style: HajjDuaTypography.body.copyWith(
              color: AppColors.textBodyColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
