import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/hajj_dua_repository.dart';
import '../../models/hajj_dua_category.dart';
import '../../services/hajj_dua_service.dart';
import '../hajj_dua_typography.dart';
import '../widgets/dua_card.dart';

class HajjDuaCategoryScreen extends StatefulWidget {
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
  State<HajjDuaCategoryScreen> createState() => _HajjDuaCategoryScreenState();
}

class _HajjDuaCategoryScreenState extends State<HajjDuaCategoryScreen> {
  String? _selectedActivity;
  int _selectedCircuit = 1; // 1 to 7 for Tawaf and Sa'i
  late final HajjDuaService _service;

  @override
  void initState() {
    super.initState();
    _service = HajjDuaService.instance;
  }

  bool get _isTawafStage =>
      widget.category.stage == HajjDuaStage.tawaf ||
      widget.category.stage == HajjDuaStage.tawafIfadah ||
      widget.category.stage == HajjDuaStage.tawafWada;

  bool get _isSaiStage => widget.category.stage == HajjDuaStage.sai;
  bool get _isArafahStage => widget.category.stage == HajjDuaStage.arafah;

  String? _getContextualLabel(BuildContext context) {
    if (widget.category.stage == HajjDuaStage.tawafIfadah) {
      return context.tr('hajjDuaContextualType', {
        'type': 'Ifadah (Rukun Haji)',
      });
    }
    if (widget.category.stage == HajjDuaStage.tawafWada) {
      return context.tr('hajjDuaContextualType', {
        'type': 'Wada\' (Perpisahan)',
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = AppColors.scaffoldColor(context);
    final allDuas = widget.repository.getDuasForStage(widget.category.stage);
    final activities = widget.repository.getActivitiesForStage(
      widget.category.stage,
    );

    final filteredDuas = _selectedActivity == null
        ? allDuas
        : allDuas
              .where((d) => d.activity?.trim() == _selectedActivity?.trim())
              .toList();

    final contextualLabel = _getContextualLabel(context);

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
          context.tr(widget.category.titleKey),
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
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              key: Key('category_screen_${widget.category.stage.name}'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              children: [
                _CategoryIntroduction(
                  category: widget.category,
                  contextualLabel: contextualLabel,
                ),
                if (_isTawafStage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _TawafCircuitGuide(
                    selectedCircuit: _selectedCircuit,
                    onCircuitSelected: (circuit) {
                      setState(() => _selectedCircuit = circuit);
                    },
                  ),
                ],
                if (_isSaiStage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SaiLapGuide(
                    selectedLap: _selectedCircuit,
                    onLapSelected: (lap) {
                      setState(() => _selectedCircuit = lap);
                    },
                  ),
                ],
                if (_isArafahStage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _ArafahGuidanceCard(),
                ],
                if (activities.isNotEmpty &&
                    !_isTawafStage &&
                    !_isSaiStage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ActivityFilterChips(
                    activities: activities,
                    selectedActivity: _selectedActivity,
                    onActivitySelected: (act) {
                      setState(() => _selectedActivity = act);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (filteredDuas.isEmpty)
                  _EmptyCategoryState(category: widget.category)
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('hajjDuaCount', {
                          'count': filteredDuas.length,
                        }),
                        style: HajjDuaTypography.caption.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                      ),
                      Text(
                        'Kementerian Agama RI',
                        style: HajjDuaTypography.metadataLabel.copyWith(
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...filteredDuas.map(
                    (dua) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DuaCard(
                        key: Key('dua_card_${dua.id}'),
                        dua: dua,
                        initiallyExpanded:
                            dua.id == widget.initiallyExpandedDuaId,
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
  final String? contextualLabel;

  const _CategoryIntroduction({required this.category, this.contextualLabel});

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
          if (contextualLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                contextualLabel!,
                style: HajjDuaTypography.metadataLabel.copyWith(
                  color: AppColors.goldPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          Text(
            context.tr(category.titleKey),
            style: HajjDuaTypography.screenTitle.copyWith(
              color: AppColors.textHeadingColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(category.descriptionKey),
            style: HajjDuaTypography.body.copyWith(
              color: AppColors.textBodyColor(context),
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
                  context.tr('hajjDuaGuidanceWarning'),
                  style: HajjDuaTypography.caption.copyWith(
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

class _TawafCircuitGuide extends StatelessWidget {
  final int selectedCircuit;
  final ValueChanged<int> onCircuitSelected;

  const _TawafCircuitGuide({
    required this.selectedCircuit,
    required this.onCircuitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sync_rounded,
                color: AppColors.goldPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Panduan Putaran Thawaf (1 - 7)',
                style: HajjDuaTypography.cardTitle.copyWith(
                  color: AppColors.textHeadingColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final circuitNum = index + 1;
                final isSelected = selectedCircuit == circuitNum;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      'Putaran $circuitNum',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textHeadingColor(context),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.goldPrimary,
                    onSelected: (_) => onCircuitSelected(circuitNum),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(
                alpha: isDark ? 0.12 : 0.08,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.goldPrimary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ketentuan Doa Putaran ke-$selectedCircuit',
                        style: HajjDuaTypography.metadataLabel.copyWith(
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.goldDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('hajjDuaNoRoundDuaNote'),
                        style: HajjDuaTypography.caption.copyWith(
                          color: AppColors.textBodyColor(context),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaiLapGuide extends StatelessWidget {
  final int selectedLap;
  final ValueChanged<int> onLapSelected;

  const _SaiLapGuide({required this.selectedLap, required this.onLapSelected});

  String _getLapRoute(int lap) {
    if (lap.isOdd) {
      return 'Bukit Shafa → Bukit Marwah';
    } else {
      return 'Bukit Marwah → Bukit Shafa';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: AppColors.goldPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Perjalanan Sa\'i (1 - 7)',
                style: HajjDuaTypography.cardTitle.copyWith(
                  color: AppColors.textHeadingColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final lapNum = index + 1;
                final isSelected = selectedLap == lapNum;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      'Trip $lapNum/7',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textHeadingColor(context),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.goldPrimary,
                    onSelected: (_) => onLapSelected(lapNum),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(
                alpha: isDark ? 0.12 : 0.08,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      color: AppColors.goldPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Perjalanan $selectedLap dari 7: ${_getLapRoute(selectedLap)}',
                      style: HajjDuaTypography.metadataLabel.copyWith(
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('hajjDuaNoRoundDuaNote'),
                  style: HajjDuaTypography.caption.copyWith(
                    color: AppColors.textBodyColor(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArafahGuidanceCard extends StatelessWidget {
  const _ArafahGuidanceCard();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.goldPrimary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.wb_sunny_rounded,
            color: AppColors.goldPrimary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Wukuf di Arafah',
                  style: HajjDuaTypography.cardTitle.copyWith(
                    color: AppColors.textHeadingColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('hajjDuaArafahGuidanceNote'),
                  style: HajjDuaTypography.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textBodyColor(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFilterChips extends StatelessWidget {
  final List<String> activities;
  final String? selectedActivity;
  final ValueChanged<String?> onActivitySelected;

  const _ActivityFilterChips({
    required this.activities,
    required this.selectedActivity,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(context.tr('hajjDuaActivityAll')),
            selected: selectedActivity == null,
            onSelected: (_) => onActivitySelected(null),
          ),
          const SizedBox(width: 8),
          ...activities.map((act) {
            final isSelected = selectedActivity == act;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(act),
                selected: isSelected,
                onSelected: (_) => onActivitySelected(isSelected ? null : act),
              ),
            );
          }),
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
            context.tr('hajjDuaVerifyingTitle'),
            textAlign: TextAlign.center,
            style: HajjDuaTypography.cardTitle.copyWith(
              color: AppColors.textHeadingColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('hajjDuaVerifyingMessage'),
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
