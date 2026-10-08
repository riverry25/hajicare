import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../presentation/dashboard_typography.dart';
import '../services/hajj_guide_service.dart';

/// Model representing a Hajj stage milestone in the journey path.
class HajjStageItem {
  final String id;
  final String day;
  final String shortDay;
  final String title;
  final String location;
  final IconData icon;
  final Color color;
  final String desc;
  final List<String> deeds;
  final String tips;

  const HajjStageItem({
    required this.id,
    required this.day,
    required this.shortDay,
    required this.title,
    required this.location,
    required this.icon,
    required this.color,
    required this.desc,
    required this.deeds,
    required this.tips,
  });
}

/// Attractive, gamified & elder-friendly Hajj Journey Stepper Sheet.
/// Inspired by modern habit/journey trackers (Image 2) and serpentine milestone paths (Image 3),
/// adapted harmoniously to HajiCare's design tokens and real manasik workflow.
class HajjScheduleGuideSheet extends StatefulWidget {
  const HajjScheduleGuideSheet({super.key});

  @override
  State<HajjScheduleGuideSheet> createState() => _HajjScheduleGuideSheetState();
}

class _HajjScheduleGuideSheetState extends State<HajjScheduleGuideSheet> {
  final ScrollController _scrollController = ScrollController();
  late final HajjGuideService _guideService;
  int _selectedStageIndex = 0;

  @override
  void initState() {
    super.initState();
    _guideService = HajjGuideService.instance;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<HajjStageItem> _getStages(BuildContext context) {
    return [
      HajjStageItem(
        id: 'tarwiyah',
        day: context.tr('dashboard.stageTarwiyahDay'),
        shortDay: '8 Dzul',
        title: context.tr('dashboard.stageTarwiyahTitle'),
        location: 'Mina',
        icon: Icons.location_city_rounded,
        color: AppColors.emeraldIslamic,
        desc: context.tr('dashboard.stageTarwiyahDesc'),
        deeds: const [
          'Niat Ihram & Talbiyah',
          'Menuju Mina',
          'Salat Qashar 5 Waktu',
          'Mabit di Mina',
        ],
        tips:
            'Kenakan pakaian ihram dari hotel/maktab. Berniat haji sebelum berangkat dan perbanyak melafalkan kalimat talbiyah selama perjalanan.',
      ),
      HajjStageItem(
        id: 'arafah',
        day: context.tr('dashboard.stageArafahDay'),
        shortDay: '9 Dzul',
        title: context.tr('dashboard.stageArafahTitle'),
        location: 'Padang Arafah',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFE65100),
        desc: context.tr('dashboard.stageArafahDesc'),
        deeds: const [
          'Menuju Arafah Ba\'da Subuh',
          'Khutbah Wukuf',
          'Salat Jamak Taqdim',
          'Puncak Doa & Dzikir',
        ],
        tips:
            'Pastikan tetap berada di dalam batas resmi Arafah. Manfaatkan waktu ba\'da zawal hingga terbenam matahari untuk berdoa dan istighfar.',
      ),
      HajjStageItem(
        id: 'muzdalifah',
        day: context.tr('dashboard.stageMuzdalifahDay'),
        shortDay: 'Mlm 10',
        title: context.tr('dashboard.stageMuzdalifahTitle'),
        location: 'Muzdalifah',
        icon: Icons.nights_stay_rounded,
        color: const Color(0xFF3949AB),
        desc: context.tr('dashboard.stageMuzdalifahDesc'),
        deeds: const [
          'Bertolak Ba\'da Maghrib',
          'Salat Jamak Ta\'khir',
          'Mabit Hingga Tengah Malam',
          'Kumpulkan Kerikil',
        ],
        tips:
            'Kumpulkan kerikil seukuran kacang tanah (min. 49 butir untuk Nafar Awal, 70 butir untuk Nafar Tsani). Beristirahat secukupnya sebelum fajar.',
      ),
      HajjStageItem(
        id: 'nahar',
        day: context.tr('dashboard.stageNaharDay'),
        shortDay: '10 Dzul',
        title: context.tr('dashboard.stageNaharTitle'),
        location: 'Jamarat & Makkah',
        icon: Icons.flag_rounded,
        color: const Color(0xFFC2185B),
        desc: context.tr('dashboard.stageNaharDesc'),
        deeds: const [
          'Lempar Jumrah Aqabah',
          'Penyembelihan Dam/Hadyu',
          'Tahallul Awal (Cukur)',
          'Tawaf Ifadhah & Sa\'i',
        ],
        tips:
            'Lontar 7 kerikil di Jumrah Aqabah satu per satu sambil bertakbir. Setelah tahallul awal, larangan ihram gugur kecuali hubungan suami istri.',
      ),
      HajjStageItem(
        id: 'tasyrik',
        day: context.tr('dashboard.stageTasyrikDay'),
        shortDay: '11-13 Dzul',
        title: context.tr('dashboard.stageTasyrikTitle'),
        location: 'Mina & Jamarat',
        icon: Icons.alt_route_rounded,
        color: const Color(0xFF00897B),
        desc: context.tr('dashboard.stageTasyrikDesc'),
        deeds: const [
          'Mabit di Mina',
          'Lontar 3 Jumrah Tiap Hari',
          'Zikir Hari Tasyrik',
          'Pilihan Nafar Awal/Tsani',
        ],
        tips:
            'Melontar jumrah dilakukan setelah waktu zawal (masuk dzuhur). Ikuti jadwal regu dan kloter demi keamanan dan kenyamanan bersama.',
      ),
      HajjStageItem(
        id: 'wada',
        day: context.tr('dashboard.stageWadaDay'),
        shortDay: 'Wada\'',
        title: context.tr('dashboard.stageWadaTitle'),
        location: 'Masjidil Haram',
        icon: Icons.mosque_rounded,
        color: const Color(0xFFB78103),
        desc: context.tr('dashboard.stageWadaDesc'),
        deeds: const [
          'Tawaf 7 Putaran',
          'Salat Sunnah Tawaf',
          'Doa Multazam & Zamzam',
          'Persiapan Kepulangan',
        ],
        tips:
            'Dilakukan sebagai amalan penutup sebelum meninggalkan tanah suci Makkah. Tidak ada Sa\'i dalam Tawaf Wada\'. Jamaah wanita haid mendapat rukhshah.',
      ),
    ];
  }

  void _toggleStageCompletion(String id, {List<String>? deeds}) {
    HapticFeedback.lightImpact();
    _guideService.toggleStage(id, stageDeeds: deeds);
    setState(() {});
  }

  void _toggleDeedCompletion(
    String stageId,
    String deed, {
    List<String>? allDeeds,
  }) {
    HapticFeedback.selectionClick();
    _guideService.toggleDeed(stageId, deed, allStageDeeds: allDeeds);
    setState(() {});
  }

  void _toggleStageExpansion(String id) {
    HapticFeedback.selectionClick();
    _guideService.toggleExpansion(id);
    setState(() {});
  }

  void _scrollToStage(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedStageIndex = index;
    });

    if (!_scrollController.hasClients) return;
    // Approximate offset per stage card (~240px)
    final targetOffset = (index * 230.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final stages = _getStages(context);
    final completedCount = _guideService.completedStageIds.length;
    final totalCount = stages.length;
    final progressFraction = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Drag Handle ──────────────────────────────────────────
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Header Title & Close Button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.goldPrimary.withValues(alpha: 0.25),
                                AppColors.tanMedium.withValues(alpha: 0.15),
                              ]
                            : [
                                AppColors.tanMedium.withValues(alpha: 0.20),
                                AppColors.canvasCream,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(
                          alpha: isDark ? 0.35 : 0.25,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: AppColors.espressoDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('dashboard.hajjStagesTitle'),
                          style: DashboardTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          context.tr('dashboard.hajjStagesSub'),
                          style: DashboardTypography.captionSmall.copyWith(
                            color: bodyColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: bodyColor),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: context.tr('common.close'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Gamified Journey Banner (Image 2 & 3 Concept) ─────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
              ),
              child: _buildJourneyProgressBanner(
                context: context,
                isDark: isDark,
                completedCount: completedCount,
                totalCount: totalCount,
                progressFraction: progressFraction,
                headingColor: headingColor,
                bodyColor: bodyColor,
              ),
            ),
            const SizedBox(height: 14),

            // ── Horizontal Day Capsule Selector (From Image 2) ────────────
            _buildHorizontalDaySelector(
              context: context,
              stages: stages,
              isDark: isDark,
              headingColor: headingColor,
              bodyColor: bodyColor,
            ),
            const SizedBox(height: 12),

            const Divider(height: 1, thickness: 0.6),

            // ── Connected Vertical Stepper / Path Timeline (Image 2 & 3) ──
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenEdgeGutter,
                  16,
                  AppSpacing.screenEdgeGutter,
                  24,
                ),
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  final isFirst = index == 0;
                  final isLast = index == stages.length - 1;
                  final isCompleted = _guideService.isStageCompleted(stage.id);
                  final isSelected = _selectedStageIndex == index;
                  final isExpanded = _guideService.isStageExpanded(stage.id);

                  return _buildTimelineStageRow(
                    context: context,
                    stage: stage,
                    index: index,
                    isFirst: isFirst,
                    isLast: isLast,
                    isCompleted: isCompleted,
                    isSelected: isSelected,
                    isExpanded: isExpanded,
                    isDark: isDark,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive Journey Progress Banner inspired by Image 2 & 3.
  Widget _buildJourneyProgressBanner({
    required BuildContext context,
    required bool isDark,
    required int completedCount,
    required int totalCount,
    required double progressFraction,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark
              ? AppColors.goldPrimary.withValues(alpha: 0.25)
              : AppColors.goldPrimary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(
                      alpha: isDark ? 0.25 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.accentGoldStar
                            : AppColors.goldDark,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Perjalanan Ibadah Haji',
                          style: DashboardTypography.captionSmall.copyWith(
                            color: isDark
                                ? AppColors.accentGoldStar
                                : AppColors.goldDark,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$completedCount dari $totalCount Tahap Selesai',
                  style: DashboardTypography.captionSmall.copyWith(
                    color: AppColors.emeraldIslamic,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Animated Track Progress Bar (Image 2 style)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 7,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.espressoDark.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.emeraldIslamic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal Day Capsule Selector Strip (Directly inspired by Image 2's top day pills).
  Widget _buildHorizontalDaySelector({
    required BuildContext context,
    required List<HajjStageItem> stages,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final selectorHeight = (74.0 * textScale.clamp(1.0, 1.5)).clamp(
      74.0,
      115.0,
    );

    return SizedBox(
      height: selectorHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int index = 0; index < stages.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              _buildHorizontalDayCapsule(
                stage: stages[index],
                index: index,
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDayCapsule({
    required HajjStageItem stage,
    required int index,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    final isCompleted = _guideService.isStageCompleted(stage.id);
    final isSelected = _selectedStageIndex == index;

    return InkWell(
      onTap: () => _scrollToStage(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? stage.color.withValues(alpha: 0.25)
                    : stage.color.withValues(alpha: 0.12))
              : (isDark
                    ? AppColors.darkSurfaceContainerHighest
                    : AppColors.canvasCream.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? stage.color
                : (isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                      : AppColors.outlineVariant.withValues(alpha: 0.5)),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon / Check badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompleted)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: AppColors.emeraldIslamic,
                  )
                else if (isSelected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stage.color,
                    ),
                  )
                else
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: bodyColor.withValues(alpha: 0.6),
                    ),
                  ),
                const SizedBox(width: 4),
                Text(
                  stage.shortDay,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? headingColor : bodyColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              stage.location,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? stage.color
                    : bodyColor.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Connected Vertical Timeline Step Row (Combining Image 2 Stepper + Image 3 Path).
  Widget _buildTimelineStageRow({
    required BuildContext context,
    required HajjStageItem stage,
    required int index,
    required bool isFirst,
    required bool isLast,
    required bool isCompleted,
    required bool isSelected,
    required bool isExpanded,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    final stageColor = stage.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left Timeline Rail (Connecting Lines & Circular Milestone Node) ──
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Top Connecting Line
                if (!isFirst)
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2.5,
                      color: isCompleted
                          ? AppColors.emeraldIslamic
                          : (isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.outlineVariant),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                // Milestone Node Icon (Image 3 circular avatar style)
                InkWell(
                  onTap: () => _toggleStageCompletion(stage.id),
                  customBorder: const CircleBorder(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.emeraldIslamic.withValues(alpha: 0.15)
                              : (isDark
                                    ? AppColors.darkSurfaceContainer
                                    : Colors.white),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.emeraldIslamic
                                : (isSelected
                                      ? stageColor
                                      : stageColor.withValues(alpha: 0.45)),
                            width: isSelected || isCompleted ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: stageColor.withValues(
                                alpha: isSelected ? 0.35 : 0.12,
                              ),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            stage.icon,
                            size: 19,
                            color: isCompleted
                                ? AppColors.emeraldIslamic
                                : (isSelected ? stageColor : headingColor),
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.emeraldIslamic,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom Connecting Line
                if (!isLast)
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: 2.5,
                      color: isCompleted
                          ? AppColors.emeraldIslamic.withValues(alpha: 0.8)
                          : (isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.outlineVariant),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Right Rich Stage Card (Image 2 style with tasks & progress) ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : (isSelected
                            ? AppColors.canvasCream
                            : AppColors.canvasCream.withValues(alpha: 0.65)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? stageColor.withValues(alpha: 0.75)
                        : (isDark
                              ? AppColors.darkOutlineVariant.withValues(
                                  alpha: 0.4,
                                )
                              : AppColors.outlineVariant.withValues(
                                  alpha: 0.3,
                                )),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.03,
                      ),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Row with Wrap for responsive overflow-safe layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Day Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: stageColor.withValues(
                                    alpha: isDark ? 0.25 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  stage.day,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: stageColor,
                                  ),
                                ),
                              ),

                              // Location Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: bodyColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.place_rounded,
                                      size: 11,
                                      color: bodyColor.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        stage.location,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: bodyColor.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Interactive Checkbox / Mark Done Pill (Image 2 style)
                        InkWell(
                          onTap: () => _toggleStageCompletion(stage.id),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.emeraldIslamic
                                  : (isDark
                                        ? AppColors.darkSurfaceContainerHighest
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.emeraldIslamic
                                    : (isDark
                                          ? AppColors.darkOutlineVariant
                                          : AppColors.outlineVariant),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 13,
                                  color: isCompleted
                                      ? Colors.white
                                      : bodyColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCompleted ? 'Selesai' : 'Tandai',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? Colors.white
                                        : headingColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Stage Title
                    Text(
                      stage.title,
                      style: DashboardTypography.labelLarge.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Stage Description
                    Text(
                      stage.desc,
                      style: DashboardTypography.bodySmall.copyWith(
                        color: bodyColor.withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sub-deeds Micro-tags (Interactive per-deed checkboxes)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: stage.deeds.map((deed) {
                        final isDeedDone = _guideService.isDeedCompleted(
                          stage.id,
                          deed,
                        );
                        return InkWell(
                          onTap: () => _toggleDeedCompletion(
                            stage.id,
                            deed,
                            allDeeds: stage.deeds,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDeedDone
                                  ? AppColors.emeraldIslamic.withValues(
                                      alpha: isDark ? 0.2 : 0.12,
                                    )
                                  : (isDark
                                        ? AppColors.darkSurfaceContainerHighest
                                              .withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.85)),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: isDeedDone
                                    ? AppColors.emeraldIslamic.withValues(
                                        alpha: 0.5,
                                      )
                                    : (isDark
                                          ? AppColors.darkOutlineVariant
                                                .withValues(alpha: 0.3)
                                          : AppColors.outlineVariant.withValues(
                                              alpha: 0.4,
                                            )),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDeedDone
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 12,
                                  color: isDeedDone
                                      ? AppColors.emeraldIslamic
                                      : stageColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    deed,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDeedDone
                                          ? AppColors.emeraldIslamic
                                          : headingColor.withValues(
                                              alpha: 0.85,
                                            ),
                                      decoration: isDeedDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AppColors.emeraldIslamic
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Expandable "Tips & Catatan Petugas" Accordion
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _toggleStageExpansion(stage.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 15,
                              color: AppColors.goldDark,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Panduan & Catatan Penting',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 17,
                              color: bodyColor.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isExpanded) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withValues(
                            alpha: isDark ? 0.12 : 0.07,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.goldDark,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                stage.tips,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.45,
                                  color: headingColor.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
