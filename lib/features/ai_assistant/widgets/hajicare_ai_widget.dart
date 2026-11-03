import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/app_settings_controller.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../bindings/hajicare_ai_binding.dart';
import '../controllers/hajicare_ai_controller.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_voice_phase.dart';
import 'oled_smartband_preview_card.dart';
import 'sensor_context_live_card.dart';

export 'oled_smartband_preview_card.dart';
export 'sensor_context_live_card.dart';

/// Halaman utama **HajiCare AI Voice Assistant (Powered by Hermes Agent)**.
///
/// Dirancang minimalis, bersih, dan ramah lansia mengikuti pola AI Chat modern:
/// - **Mode Chat Bersih:** Fokus pada percakapan dengan animasi kata demi kata
///   (*word-by-word streaming*), toolbar ikon ringkas (`Salin`, `Suara 🔊`, `OLED ⌚`,
///   `Ulangi ↻`), dan input kapsul tunggal.
/// - **Mode Suara Penuh (*Voice Orb Mode*):** Tampilan bola gelombang suara
///   interaktif dengan teks besar terpusat untuk jamaah lansia.
/// - **Panel Smartband & OLED 128x64 Ringkas:** Bar 1-baris di bagian atas yang
///   dapat diketuk kapan saja untuk membuka pratinjau penuh layar OLED 128x64
///   dan simulator sensor tanpa memenuhi ruang chat.
class HajiCareAiAssistantPage extends StatefulWidget {
  const HajiCareAiAssistantPage({
    super.key,
    this.isBottomSheet = false,
  });

  final bool isBottomSheet;

  /// Buka asisten AI sebagai Floating Bottom Sheet modern.
  static Future<void> showFloatingSheet(BuildContext context) async {
    HajiCareAiBinding.ensureRegistered();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          child: HajiCareAiAssistantPage(isBottomSheet: true),
        ),
      ),
    );
  }

  /// Buka sheet detail Sensor Gelang & Layar OLED 128x64.
  static Future<void> showSmartbandOledSheet(
    BuildContext context,
    HajiCareAiController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SmartbandAndOledModalSheet(controller: controller),
    );
  }

  /// Buka sheet daftar Pertanyaan Cepat (Quick Prompts) untuk jamaah.
  static Future<void> showQuickPromptsSheet(
    BuildContext context,
    HajiCareAiController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickPromptsModalSheet(controller: controller),
    );
  }

  @override
  State<HajiCareAiAssistantPage> createState() =>
      _HajiCareAiAssistantPageState();
}

class _HajiCareAiAssistantPageState extends State<HajiCareAiAssistantPage> {
  late final HajiCareAiController _controller;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  final ValueNotifier<bool> _hasTypedText = ValueNotifier<bool>(false);
  Worker? _messagesWorker;
  int _lastMessageCount = 0;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = HajiCareAiBinding.ensureRegistered();
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
    _scrollController = ScrollController();
    _lastMessageCount = _controller.messages.length;

    _messagesWorker = ever<List<AiChatMessage>>(_controller.messages, (msgs) {
      final isNewMessageAdded = msgs.length != _lastMessageCount;
      _lastMessageCount = msgs.length;
      final isStreamingTick =
          !isNewMessageAdded && msgs.isNotEmpty && msgs.last.isStreaming;
      _scrollToBottom(immediate: isStreamingTick);
    });
  }

  void _onTextChanged() {
    final nonEmpty = _textController.text.trim().isNotEmpty;
    if (_hasTypedText.value != nonEmpty) {
      _hasTypedText.value = nonEmpty;
    }
  }

  @override
  void dispose() {
    _messagesWorker?.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _hasTypedText.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      if ((maxExtent - currentOffset).abs() < 2.0) return;

      if (immediate) {
        // Saat streaming kata demi kata aktif, gunakan jumpTo agar tidak memicu
        // puluhan animasi bertabrakan per detik (mencegah lag/jank pada frame budget <16ms).
        _scrollController.jumpTo(maxExtent);
      } else {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSubmitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    _controller.sendQuestion(text, autoSpeak: true);
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Scaffold(
      backgroundColor: hc.canvas,
      body: SafeArea(
        top: !widget.isBottomSheet,
        child: ResponsiveCenter(
          maxWidth: AppBreakpoints.maxTabletContentWidth,
          child: Column(
            children: [
              if (widget.isBottomSheet) const _SheetDragHandle(),

              // 1. Minimalist Top Header (seperti referensi desain)
              _MinimalAiHeader(
                controller: _controller,
                isBottomSheet: widget.isBottomSheet,
              ),

              // 2. Body: Beralih mulus antara Mode Suara Penuh vs Ruang Chat Bersih
              Expanded(
                child: Obx(() {
                  if (_controller.isVoiceModeOpen.value) {
                    return _ImmersiveVoiceModeView(controller: _controller);
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isTabletWide = constraints.maxWidth >= 720;
                      if (isTabletWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 300,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: _SidePanelTelemetryAndOled(
                                  controller: _controller,
                                ),
                              ),
                            ),
                            VerticalDivider(width: 1, color: hc.border),
                            Expanded(
                              child: _CleanChatView(
                                controller: _controller,
                                scrollController: _scrollController,
                                textController: _textController,
                                hasTypedText: _hasTypedText,
                                onSubmitText: _handleSubmitText,
                                showCompactStrip: false,
                              ),
                            ),
                          ],
                        );
                      }

                      return _CleanChatView(
                        controller: _controller,
                        scrollController: _scrollController,
                        textController: _textController,
                        hasTypedText: _hasTypedText,
                        onSubmitText: _handleSubmitText,
                        showCompactStrip: true,
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.hc.border,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

/// Header minimalis terinspirasi referensi desain:
/// `<` • Avatar Bintang AI • `HajiCare AI Assistant` + subtitel sensor ringkas • `⌚` • `⚙️` • `⋮`
class _MinimalAiHeader extends StatelessWidget {
  const _MinimalAiHeader({
    required this.controller,
    required this.isBottomSheet,
  });

  final HajiCareAiController controller;
  final bool isBottomSheet;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: hc.canvas,
        border: Border(
          bottom: BorderSide(color: hc.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (controller.isVoiceModeOpen.value) {
                controller.closeVoiceMode();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            icon: Icon(
              isBottomSheet
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.chevron_left_rounded,
              color: hc.textPrimary,
              size: 28,
            ),
            tooltip: context.tr('ai.backTooltip'),
          ),
          const _AiSparkleAvatar(size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => HajiCareAiAssistantPage.showSmartbandOledSheet(
                context,
                controller,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ai.title'),
                      style: context.text.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: hc.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Obx(() {
                      if (Get.isRegistered<AppSettingsController>()) {
                        Get.find<AppSettingsController>().rxLocale.value;
                      }
                      final s = controller.sensorContext.value;
                      final srv = controller.serverStatus.value;
                      final srvDot = srv.isOnline
                          ? AppTranslations.tr('ai.statusOnline')
                          : AppTranslations.tr('ai.statusReady');
                      final bandOrAppStr = s.isSmartbandConnected
                          ? (s.heartRateBpm > 0
                                ? '${s.heartRateBpm} BPM • ${s.temperatureLabel}°C'
                                : AppTranslations.tr('ai.bandBleActive'))
                          : (s.distanceToCompanionMeters != null
                                ? AppTranslations.tr(
                                    'ai.distanceMetersShort',
                                    {
                                      'meters':
                                          '${s.distanceToCompanionMeters!.round()}',
                                    },
                                  )
                                : (s.locationCityName ??
                                      AppTranslations.tr(
                                        'ai.appAndGpsActive',
                                      )));
                      return Text(
                        '$srvDot • $bandOrAppStr',
                        style: context.text.labelSmall.copyWith(
                          color: (s.isSmartbandConnected && s.isFallDetected)
                              ? hc.danger
                              : hc.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Tombol Mode Suara Penuh (Voice Orb)
          Obx(() {
            if (Get.isRegistered<AppSettingsController>()) {
              Get.find<AppSettingsController>().rxLocale.value;
            }
            final voiceOpen = controller.isVoiceModeOpen.value;
            return IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                if (voiceOpen) {
                  controller.closeVoiceMode();
                } else {
                  controller.openVoiceMode(autoStartListening: false);
                }
              },
              tooltip: voiceOpen
                  ? AppTranslations.tr('ai.textChatModeTooltip')
                  : AppTranslations.tr('ai.fullVoiceModeTooltip'),
              icon: Icon(
                voiceOpen
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.graphic_eq_rounded,
                color: voiceOpen ? hc.accent : hc.textPrimary,
                size: 22,
              ),
            );
          }),



          // Menu Opsi Lainnya (⋮) seperti referensi foto ke-4
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: hc.textPrimary,
              size: 22,
            ),
            tooltip: context.tr('ai.moreMenuTooltip'),
            onSelected: (value) {
              if (value == 'oled') {
                HajiCareAiAssistantPage.showSmartbandOledSheet(
                  context,
                  controller,
                );

              } else if (value == 'clear') {
                controller.clearConversation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'oled',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.watch_rounded),
                  title: Text(context.tr('ai.menuOledAndSensor')),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(context.tr('ai.menuNewChat')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar ikon bintang/sparkle khas AI modern (seperti referensi Foto 4).
class _AiSparkleAvatar extends StatelessWidget {
  const _AiSparkleAvatar({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1813),
        shape: BoxShape.circle,
        border: Border.all(
          color: hc.accent.withValues(alpha: 0.65),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: hc.accent.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: hc.accent,
        size: size * 0.52,
      ),
    );
  }
}

/// Bar status 1-baris yang sangat ringkas di atas ruang chat ponsel.
/// Menampilkan status sensor & layar OLED tanpa memenuhi ruang percakapan.
class _CompactSmartbandOledStrip extends StatelessWidget {
  const _CompactSmartbandOledStrip({required this.controller});

  final HajiCareAiController controller;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Obx(() {
      final sensor = controller.sensorContext.value;
      final oled = controller.oledState.value;
      final ledOn = controller.isOledLedActive.value;
      final bandConnected = sensor.isSmartbandConnected;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          4,
        ),
        child: Row(
          children: [
            // Pill Kiri: Status Nyata Gelang BLE
            Expanded(
              child: InkWell(
                key: const Key('compact_smartband_oled_strip'),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => HajiCareAiAssistantPage.showSmartbandOledSheet(
                  context,
                  controller,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: hc.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: (bandConnected && sensor.isFallDetected)
                          ? hc.danger
                          : hc.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bandConnected
                            ? Icons.favorite_rounded
                            : Icons.bluetooth_disabled_rounded,
                        size: 14,
                        color: bandConnected
                            ? (sensor.isFallDetected
                                  ? hc.danger
                                  : const Color(0xFFE11D48))
                            : hc.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bandConnected
                              ? '${AppTranslations.tr('ai.sensorContextTitle')} • ${sensor.heartRateBpm > 0 ? "${sensor.heartRateBpm} BPM" : AppTranslations.tr('ai.bandBleActive')}'
                              : AppTranslations.tr('ai.bandDisconnectedCompact'),
                          style: context.text.labelSmall.copyWith(
                            color: hc.textPrimary,
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
            ),
            const SizedBox(width: AppSpacing.xs),

            // Pill Kanan: Layar Gelang OLED 0.96" (128x64) + Indikator LED Hijau
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => HajiCareAiAssistantPage.showSmartbandOledSheet(
                  context,
                  controller,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: ledOn
                          ? const Color(0xFF22C55E)
                          : hc.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ledOn
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (ledOn)
                              const BoxShadow(
                                color: Color(0xFF22C55E),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'OLED: ${oled.text}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFFF8FAFC),
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
            ),
          ],
        ),
      );
    });
  }
}

class _SidePanelTelemetryAndOled extends StatelessWidget {
  const _SidePanelTelemetryAndOled({required this.controller});

  final HajiCareAiController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sensor = controller.sensorContext.value;
      final oled = controller.oledState.value;
      final ledActive = controller.isOledLedActive.value;
      final ble = controller.bleLinkStatus.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OledSmartbandPreviewCard(
            oledState: oled,
            isLedActive: ledActive,
            bleStatus: ble,
            heartRateBpm: sensor.heartRateBpm,
          ),
          const SizedBox(height: AppSpacing.sm),
          SensorContextLiveCard(
            sensor: sensor,
            isExpanded: true,
            onToggleExpand: controller.toggleSensorCardExpanded,
            onRefreshTap: controller.refreshSensorsNow,
            onConnectSmartbandTap: controller.connectSmartbandBle,
          ),
        ],
      );
    });
  }
}

/// Ruang Chat Bersih mengikuti referensi foto ke-4.
class _CleanChatView extends StatelessWidget {
  const _CleanChatView({
    required this.controller,
    required this.scrollController,
    required this.textController,
    required this.hasTypedText,
    required this.onSubmitText,
    required this.showCompactStrip,
  });

  final HajiCareAiController controller;
  final ScrollController scrollController;
  final TextEditingController textController;
  final ValueNotifier<bool> hasTypedText;
  final VoidCallback onSubmitText;
  final bool showCompactStrip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showCompactStrip)
          _CompactSmartbandOledStrip(controller: controller),

        // Area Percakapan Utama
        Expanded(
          child: Obx(() {
            final msgs = controller.messages;
            final speakingId = controller.activeSpeakingMessageId.value;
            final isSpeaking = controller.isSpeaking.value;
            final showWelcomeCards = msgs.length <= 1;

            return CustomScrollView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  sliver: SliverList.separated(
                    itemCount: msgs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final message = msgs[index];
                      final isMsgSpeaking =
                          isSpeaking && speakingId == message.id;
                      return RepaintBoundary(
                        child: _ModernAiChatBubble(
                          message: message,
                          isCurrentlySpeaking: isMsgSpeaking,
                          onTapStreamingBubble:
                              controller.completeActiveStreamImmediately,
                          onSpeakTap: () => controller.speakMessage(message),
                          onSendToOledTap: () {
                            controller.resendOledFromMessage(message);
                            HajiCareAiAssistantPage.showSmartbandOledSheet(
                              context,
                              controller,
                            );
                          },
                          onShareWhatsAppTap: () async {
                            final res = await controller.shareMessageToWhatsApp(message);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.message),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          onRegenerateTap: () =>
                              controller.regenerateMessage(message),
                        ),
                      );
                    },
                  ),
                ),

                // Kartu Topik Bantuan Jamaah pada tampilan awal (seperti layar kiri Foto 4)
                if (showWelcomeCards)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _WelcomeTopicGrid(
                        onSelectPrompt: (p) =>
                            controller.sendQuestion(p, autoSpeak: true),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),

        // Deretan Quick Prompt Chips yang ramping dan rapi
        _SlimQuickPromptsRow(
          onSelectPrompt: (prompt) =>
              controller.sendQuestion(prompt, autoSpeak: true),
        ),

        // Kontrol Input Kapsul Minimalis (seperti layar tengah Foto 4)
        _MinimalPillInputBar(
          controller: controller,
          textController: textController,
          hasTypedText: hasTypedText,
          onSubmitText: onSubmitText,
        ),
      ],
    );
  }
}

/// Grid 2x2 Kartu Topik Bantuan Jamaah bergaya modern seperti layar pertama Foto 4.
class _WelcomeTopicGrid extends StatelessWidget {
  const _WelcomeTopicGrid({required this.onSelectPrompt});

  final ValueChanged<String> onSelectPrompt;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final topics = HajiCareAiController.localizedFeaturedTopics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
          child: Text(
            context.tr('ai.welcomeTopicsHeader'),
            style: context.text.labelMedium.copyWith(
              color: hc.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final item = topics[index];
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () {
                HapticFeedback.selectionClick();
                onSelectPrompt(item.prompt);
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: hc.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: hc.border),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: context.text.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: hc.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: context.text.labelSmall.copyWith(
                            color: hc.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.north_east_rounded,
                        size: 16,
                        color: hc.accent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Gelembung Chat Modern mengikuti referensi Foto 4:
/// - Gelembung Pengguna (kanan): Gradien hangat kontras tinggi + avatar kecil di kanan bawah.
/// - Gelembung AI (kiri): Kartu bersih, teks kata demi kata (*streaming*), aksi kontekstual
///   jamaah, serta deretan ikon `[📋 Salin, 🔊 Suara, ⌚ OLED, ↻ Ulangi]` di bawah.
class _ModernAiChatBubble extends StatelessWidget {
  const _ModernAiChatBubble({
    required this.message,
    required this.isCurrentlySpeaking,
    required this.onTapStreamingBubble,
    required this.onSpeakTap,
    required this.onSendToOledTap,
    required this.onShareWhatsAppTap,
    required this.onRegenerateTap,
  });

  final AiChatMessage message;
  final bool isCurrentlySpeaking;
  final VoidCallback onTapStreamingBubble;
  final VoidCallback onSpeakTap;
  final VoidCallback onSendToOledTap;
  final VoidCallback onShareWhatsAppTap;
  final VoidCallback onRegenerateTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    // State Menunggu Balasan: Avatar AI + titik-titik •••• seperti referensi Foto 4
    if (message.isPending) {
      return const _AiTypingDotsRow();
    }

    if (message.isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C723C), Color(0xFF6E4B23)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: context.text.bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: hc.surfaceSubtle,
              shape: BoxShape.circle,
              border: Border.all(color: hc.accent, width: 1.2),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 15,
              color: hc.textPrimary,
            ),
          ),
        ],
      );
    }

    // Gelembung Balasan Hermes AI (Kiri)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _AiSparkleAvatar(size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: GestureDetector(
              onTap: message.isStreaming ? onTapStreamingBubble : null,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  10,
                ),
                decoration: BoxDecoration(
                  color: hc.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: hc.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teks Jawaban (Streaming Kata Demi Kata)
                    Text(
                      message.isStreaming
                          ? '${message.text} ▍'
                          : message.text,
                      style: context.text.bodyMedium.copyWith(
                        color: hc.textPrimary,
                        fontSize: 15.2,
                        height: 1.5,
                      ),
                    ),

                    // Saat streaming berlangsung, sembunyikan tombol aksi agar pembacaan tetap bersih
                    if (!message.isStreaming) ...[
                      if (message.whatsAppStatusText != null &&
                          message.whatsAppStatusText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: const Color(0xFF25D366).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  message.whatsAppStatusText!,
                                  style: context.text.labelSmall.copyWith(
                                    color: const Color(0xFF16A34A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Tombol Aksi Kontekstual Pintar untuk Membantu Jamaah
                      if (message.contextualActions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _ContextualActionRow(
                          actions: message.contextualActions,
                          onOpenOledTap: onSendToOledTap,
                          onShareWhatsAppTap: onShareWhatsAppTap,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.sm),
                      Divider(
                        height: 1,
                        color: hc.border.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 6),

                      // Baris Ikon Aksi Bawah Gelembung AI (seperti referensi Foto 4)
                      Row(
                        children: [
                          // 1. Copy Text
                          _BubbleIconAction(
                            icon: Icons.content_copy_rounded,
                            tooltip: context.tr('ai.copyReplyTooltip'),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final copiedMsg = context.tr('ai.replyCopied');
                              await Clipboard.setData(
                                ClipboardData(text: message.effectiveFullText),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(copiedMsg),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 4),

                          // 2. Speak / Stop TTS (🔊)
                          _BubbleIconAction(
                            icon: isCurrentlySpeaking
                                ? Icons.stop_circle_rounded
                                : Icons.volume_up_rounded,
                            tooltip: isCurrentlySpeaking
                                ? context.tr('ai.stopTtsButton')
                                : context.tr('ai.speakReplyTooltip'),
                            isActive: isCurrentlySpeaking,
                            activeColor: hc.danger,
                            label: isCurrentlySpeaking
                                ? context.tr('ai.stopLabel')
                                : context.tr('ai.voiceLabel'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSpeakTap();
                            },
                          ),
                          const SizedBox(width: 4),

                          // 3. Tampilkan / Kirim ke OLED Gelang (⌚)
                          _BubbleIconAction(
                            icon: Icons.watch_rounded,
                            tooltip: context.tr('ai.viewOnOledTooltip'),
                            label: 'OLED',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSendToOledTap();
                            },
                          ),
                          const SizedBox(width: 4),

                          // 4. Kirim Laporan & Lokasi ke WhatsApp (💬)
                          _BubbleIconAction(
                            icon: Icons.chat_rounded,
                            tooltip: 'Kirim Laporan & Lokasi ke WhatsApp',
                            label: 'WA',
                            isActive: true,
                            activeColor: const Color(0xFF16A34A),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onShareWhatsAppTap();
                            },
                          ),

                          const Spacer(),

                          // 4. Regenerate / Ulangi Jawaban (↻)
                          _BubbleIconAction(
                            icon: Icons.refresh_rounded,
                            tooltip: context.tr('ai.regenerateTooltip'),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onRegenerateTap();
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleIconAction extends StatelessWidget {
  const _BubbleIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
    this.isActive = false,
    this.activeColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? label;
  final bool isActive;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final color = isActive ? (activeColor ?? hc.accent) : hc.textSecondary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15.5, color: color),
              if (label != null) ...[
                const SizedBox(width: 3),
                Text(
                  label!,
                  style: context.text.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Deretan tombol aksi cepat kontekstual untuk membantu jamaah langsung dari chat.
class _ContextualActionRow extends StatelessWidget {
  const _ContextualActionRow({
    required this.actions,
    required this.onOpenOledTap,
    required this.onShareWhatsAppTap,
  });

  final List<AiContextualAction> actions;
  final VoidCallback onOpenOledTap;
  final VoidCallback onShareWhatsAppTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final action in actions)
          _buildActionChip(context, hc, action),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context,
    HajiColors hc,
    AiContextualAction action,
  ) {
    final (IconData icon, String label, Color color, VoidCallback onTap) =
        switch (action) {
          AiContextualAction.openSos => (
            Icons.emergency_rounded,
            context.tr('ai.action.sos'),
            hc.danger,
            () => Get.toNamed(AppRoutes.modalSos),
          ),
          AiContextualAction.openMap => (
            Icons.map_rounded,
            context.tr('ai.action.map'),
            hc.info,
            () => Get.toNamed(AppRoutes.interactiveMap),
          ),
          AiContextualAction.openDua => (
            Icons.menu_book_rounded,
            context.tr('ai.action.dua'),
            hc.accent,
            () => Get.toNamed(AppRoutes.hajjDua),
          ),
          AiContextualAction.openPrayer => (
            Icons.mosque_rounded,
            context.tr('ai.action.prayer'),
            hc.success,
            () => Get.toNamed(AppRoutes.prayerTimes),
          ),
          AiContextualAction.openSmartbandSheet => (
            Icons.watch_rounded,
            context.tr('ai.action.oled'),
            hc.accent,
            onOpenOledTap,
          ),
          AiContextualAction.sendWhatsApp => (
            Icons.chat_rounded,
            'Kirim ke WhatsApp',
            const Color(0xFF16A34A),
            onShareWhatsAppTap,
          ),
        };

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: context.text.labelSmall.copyWith(
                color: hc.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indikator berpikir & mengetik AI (Avatar + Pill "Sedang berpikir..." + Titik Halus Berdenyut).
class _AiTypingDotsRow extends StatefulWidget {
  const _AiTypingDotsRow();

  @override
  State<_AiTypingDotsRow> createState() => _AiTypingDotsRowState();
}

class _AiTypingDotsRowState extends State<_AiTypingDotsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _AiSparkleAvatar(size: 28),
        const SizedBox(width: 10),
        RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: hc.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: hc.border.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titik-titik halus berdenyut
                AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final phase = (_animCtrl.value - (index * 0.2)) % 1.0;
                        final opacity = (0.3 + 0.7 * (1.0 - (phase - 0.5).abs() * 2)).clamp(0.2, 1.0);
                        return Padding(
                          padding: EdgeInsets.only(right: index < 2 ? 4.0 : 0.0),
                          child: Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: BoxDecoration(
                              color: hc.accent.withValues(alpha: opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('ai.thinkingStatus'),
                  style: context.text.bodySmall.copyWith(
                    color: hc.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Deretan tombol cepat (Quick Prompts) sekali sentuh yang ramping.
class _SlimQuickPromptsRow extends StatelessWidget {
  const _SlimQuickPromptsRow({required this.onSelectPrompt});

  final ValueChanged<String> onSelectPrompt;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final prompts = HajiCareAiController.localizedQuickPrompts;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        physics: const BouncingScrollPhysics(),
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return Center(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelectPrompt(prompt);
              },
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hc.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: hc.border),
                ),
                child: Text(
                  prompt,
                  style: context.text.labelSmall.copyWith(
                    color: hc.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Input Bar Kapsul Minimalis mengikuti layar tengah Foto 4:
/// `[ Send message...                        🎙️  ⊕ / ➤ ]`
class _MinimalPillInputBar extends StatelessWidget {
  const _MinimalPillInputBar({
    required this.controller,
    required this.textController,
    required this.hasTypedText,
    required this.onSubmitText,
  });

  final HajiCareAiController controller;
  final TextEditingController textController;
  final ValueNotifier<bool> hasTypedText;
  final VoidCallback onSubmitText;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        6,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Hentikan Suara (Stop TTS) saat AI sedang berbicara
          Obx(() {
            if (!controller.isSpeaking.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  key: const Key('stop_tts_button'),
                  onPressed: controller.stopSpeaking,
                  icon: const Icon(Icons.stop_circle_rounded, size: 18),
                  label: Text(
                    context.tr('ai.stopTtsButton'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hc.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Banner transkripsi suara jika sedang mendikte di ruang chat
          Obx(() {
            final listening = controller.isListening.value;
            final partial = controller.recognizedText.value;
            if (!listening && partial.isEmpty) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: hc.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: hc.accent),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, size: 16, color: hc.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partial.isNotEmpty
                          ? '"$partial"'
                          : controller.voiceStatusMessage.value,
                      style: context.text.labelMedium.copyWith(
                        color: hc.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: controller.stopListeningAndSendIfAny,
                    child: Text(
                      context.tr('ai.sendButton'),
                      style: context.text.labelMedium.copyWith(
                        color: hc.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Kapsul Tunggal Input Pesan seperti Referensi Foto 4 (Seragam Tanpa Belang)
          Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.only(left: 18, right: 6),
            decoration: BoxDecoration(
              color: hc.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: hc.borderStrong, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      cursorColor: hc.accent,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmitText(),
                      minLines: 1,
                      maxLines: 3,
                      style: context.text.bodyMedium.copyWith(
                        color: hc.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('ai.inputHint'),
                        hintStyle: context.text.bodyMedium.copyWith(
                          color: hc.textSecondary,
                        ),
                        filled: false,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Tombol Mikrofon (Ketuk: rekam suara, Tekan lama: buka Mode Suara Penuh)
                  Obx(() {
                    final listening = controller.isListening.value;
                    return IconButton(
                      key: const Key('voice_orb_mode_button'),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        controller.openVoiceMode(autoStartListening: true);
                      },
                      tooltip: context.tr('ai.speakWithVoiceTooltip'),
                      icon: Icon(
                        listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: listening ? hc.danger : hc.textPrimary,
                        size: 23,
                      ),
                    );
                  }),

                  // Tombol Kirim (➤) atau Tombol Pertanyaan Cepat (+) seperti Foto 4
                  ValueListenableBuilder<bool>(
                    valueListenable: hasTypedText,
                    builder: (context, hasText, _) {
                      return Obx(() {
                        final busy = controller.isSending.value;
                        if (busy) {
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: hc.accent,
                              ),
                            ),
                          );
                        }

                        if (hasText) {
                          return IconButton(
                            key: const Key('send_ai_question_button'),
                            onPressed: onSubmitText,
                            tooltip: context.tr('ai.sendMessageTooltip'),
                            icon: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF9C723C),
                                    Color(0xFF6E4B23),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        }

                        return IconButton(
                          key: const Key('send_ai_question_button'),
                          onPressed: () =>
                              HajiCareAiAssistantPage.showQuickPromptsSheet(
                                context,
                                controller,
                              ),
                          tooltip: context.tr('ai.quickPromptsTooltip'),
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: hc.textPrimary,
                            size: 24,
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Mode Suara Penuh (*Immersive Voice Mode*)** mengikuti layar kanan Foto 4:
/// - Visualisasi bola gelombang bercahaya (*Glowing Particle/Wave Orb*) di tengah.
/// - Teks transkripsi besar terpusat dengan penyorotan kata aktif & kata berikutnya.
/// - 3 tombol bundar ergonomis di bawah: `↺` (Ulangi), `🎙️` (Mikrofon Besar), `✕` (Tutup).
class _ImmersiveVoiceModeView extends StatelessWidget {
  const _ImmersiveVoiceModeView({required this.controller});

  final HajiCareAiController controller;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Obx(() {
      final phase = controller.voicePhase.value;
      final isMuted = controller.isMuted.value;
      final recognized = controller.recognizedText.value.trim();
      final currentQuestion = controller.currentTurnQuestion.value.trim();
      final currentReply = controller.currentTurnReply.value.trim();
      final lastReply = controller.lastSpokenOrReplyText.value.trim();

      final isListening = phase == AiVoicePhase.listening;
      final isThinking = phase == AiVoicePhase.thinking;
      final isAnswering = phase == AiVoicePhase.answering;

      // Tentukan teks tampilan berdasarkan fase aktif
      final String displayText;
      if (isListening) {
        displayText = recognized.isNotEmpty
            ? recognized
            : context.tr('ai.voiceListeningPrompt');
      } else if (isThinking) {
        displayText = currentQuestion.isNotEmpty
            ? currentQuestion
            : context.tr('ai.voiceThinkingStatus');
      } else if (isAnswering) {
        displayText = currentReply.isNotEmpty
            ? currentReply
            : lastReply;
      } else {
        displayText = lastReply.isNotEmpty
            ? lastReply
            : context.tr('ai.voiceTapMicPrompt');
      }

      final String statusText;
      if (isListening) {
        statusText = context.tr('ai.voiceListeningStatus');
      } else if (isThinking) {
        statusText = context.tr('ai.voiceThinkingStatus');
      } else if (isAnswering) {
        statusText = isMuted
            ? context.tr('ai.voiceMutedStatus')
            : context.tr('ai.voiceAnsweringStatus');
      } else {
        statusText = isMuted
            ? context.tr('ai.voiceMutedStatus')
            : context.tr('ai.voiceTapToAskStatus');
      }

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            // Top Bar: Session Title Chip + Mute Toggle Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hc.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: hc.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isListening
                              ? hc.danger
                              : (isThinking
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF22C55E)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'HajiCare Voice',
                        style: context.text.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hc.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol Mute Sesi (Suara Nyala / Mute)
                _VoiceCircleActionButton(
                  key: const Key('voice_mute_button'),
                  icon: isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  tooltip: isMuted
                      ? context.tr('ai.voiceUnmuteTooltip')
                      : context.tr('ai.voiceMuteTooltip'),
                  size: 42,
                  iconSize: 20,
                  activeColor: isMuted ? hc.danger : hc.textPrimary,
                  backgroundColor: isMuted
                      ? hc.danger.withValues(alpha: 0.15)
                      : hc.surface,
                  borderColor: isMuted ? hc.danger : hc.border,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    controller.toggleMute();
                  },
                ),
              ],
            ),

            const Spacer(),

            // Glowing Animated Wave Orb
            RepaintBoundary(
              child: _GlowingVoiceOrb(
                isActive: isListening || isAnswering,
                isListening: isListening,
                isThinking: isThinking,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Teks Transkripsi Besar Terpusat
            _HighlightedVoiceTranscript(
              text: displayText,
              isListening: isListening,
              isThinking: isThinking,
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              statusText,
              style: context.text.labelMedium.copyWith(
                color: isThinking
                    ? hc.accent
                    : (isMuted ? hc.warning : hc.textSecondary),
                fontWeight: isThinking ? FontWeight.w600 : FontWeight.normal,
              ),
            ),

            const Spacer(),

            // 3 Tombol Bundar Bawah: [ ↺ Ulangi ]  [ 🎙️ / ⏹️ Mic/Stop ]  [ ✕ Tutup ]
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Kiri: Ulangi Suara Terakhir (↺)
                _VoiceCircleActionButton(
                  icon: Icons.replay_rounded,
                  tooltip: context.tr('ai.voiceReplayTooltip'),
                  activeColor: (isThinking || isListening)
                      ? hc.textSecondary.withValues(alpha: 0.35)
                      : hc.textPrimary,
                  onTap: () {
                    if (isThinking || isListening) return;
                    HapticFeedback.selectionClick();
                    controller.replayLastAssistantReply();
                  },
                ),

                // Tengah: Tombol Mikrofon / Berhenti Bercahaya Besar
                GestureDetector(
                  key: const Key('voice_orb_mic_button'),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (isThinking || isAnswering) {
                      controller.cancelCurrentTurn();
                    } else {
                      controller.toggleVoiceRecording();
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: (isThinking || isAnswering)
                            ? [hc.danger, const Color(0xFF991B1B)]
                            : (isListening
                                ? [hc.danger, const Color(0xFF991B1B)]
                                : [
                                    const Color(0xFFC89B57),
                                    const Color(0xFF785124),
                                  ]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ((isThinking || isAnswering || isListening)
                                  ? hc.danger
                                  : const Color(0xFFC89B57))
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      (isThinking || isAnswering)
                          ? Icons.stop_rounded
                          : (isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                // Kanan: Tutup Mode Suara (✕)
                _VoiceCircleActionButton(
                  key: const Key('voice_orb_close_button'),
                  icon: Icons.close_rounded,
                  tooltip: context.tr('ai.voiceCloseTooltip'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.closeVoiceMode();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    });
  }
}

class _VoiceCircleActionButton extends StatelessWidget {
  const _VoiceCircleActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 50,
    this.iconSize = 22,
    this.activeColor,
    this.backgroundColor,
    this.borderColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? activeColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? hc.surface,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor ?? hc.border),
          ),
          child: Icon(
            icon,
            color: activeColor ?? hc.textPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

/// Teks transkripsi besar dengan penyorotan kata aktif (putih/terang) dan
/// kelanjutan kalimat (redup) persis seperti layar kanan Foto 4.
class _HighlightedVoiceTranscript extends StatelessWidget {
  const _HighlightedVoiceTranscript({
    required this.text,
    required this.isListening,
    this.isThinking = false,
  });

  final String text;
  final bool isListening;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    if (isThinking) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: context.text.titleLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: hc.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(hc.accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('ai.voiceThinkingStatus'),
                    style: context.text.bodyMedium.copyWith(
                      color: hc.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final clipped = words.length > 26 ? words.take(26).toList() : words;
    final splitIndex = (clipped.length * 0.65).ceil();

    final highlightedPart = clipped.take(splitIndex).join(' ');
    final trailingPart = clipped.skip(splitIndex).join(' ');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: SingleChildScrollView(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: context.text.titleLarge.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.38,
            ),
            children: [
              TextSpan(
                text: highlightedPart,
                style: TextStyle(color: hc.textPrimary),
              ),
              if (isListening)
                TextSpan(
                  text: ' | ',
                  style: TextStyle(color: hc.accent),
                ),
              if (trailingPart.isNotEmpty)
                TextSpan(
                  text: isListening ? trailingPart : ' $trailingPart',
                  style: TextStyle(
                    color: hc.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visualisasi Bola Gelombang Suara Bercahaya (*Glowing 3D Wave Orb*) seperti Foto 4.
class _GlowingVoiceOrb extends StatefulWidget {
  const _GlowingVoiceOrb({
    required this.isActive,
    required this.isListening,
    this.isThinking = false,
  });

  final bool isActive;
  final bool isListening;
  final bool isThinking;

  @override
  State<_GlowingVoiceOrb> createState() => _GlowingVoiceOrbState();
}

class _GlowingVoiceOrbState extends State<_GlowingVoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.isActive || widget.isThinking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _GlowingVoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = widget.isActive || widget.isThinking;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _VoiceOrbPainter(
            phase: _controller.value * 2 * math.pi,
            isActive: widget.isActive,
            isListening: widget.isListening,
            isThinking: widget.isThinking,
          ),
        );
      },
    );
  }
}

class _VoiceOrbPainter extends CustomPainter {
  const _VoiceOrbPainter({
    required this.phase,
    required this.isActive,
    required this.isListening,
    this.isThinking = false,
  });

  final double phase;
  final bool isActive;
  final bool isListening;
  final bool isThinking;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.34;

    final primaryGlow = isListening
        ? const Color(0xFFE11D48)
        : (isThinking
            ? const Color(0xFF38BDF8)
            : const Color(0xFFD4AF37));
    final secondaryGlow = isThinking
        ? const Color(0xFF0369A1)
        : const Color(0xFF8B5E34);

    // 1. Ambient Outer Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryGlow.withValues(alpha: (isActive || isThinking) ? 0.35 : 0.18),
          secondaryGlow.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawCircle(center, size.width * 0.5, glowPaint);

    // 2. Layered Organic Wave Rings (seperti jaring gelombang 3D pada Foto 4)
    for (var ring = 0; ring < 5; ring++) {
      final path = Path();
      final ringFactor = 1.0 - (ring * 0.09);
      const steps = 64;
      for (var i = 0; i <= steps; i++) {
        final angle = (i / steps) * 2 * math.pi;
        final waveAmp = isListening
            ? 9.0
            : (isThinking
                ? 4.5
                : (isActive ? 7.5 : 3.5));
        final offset =
            waveAmp *
            math.sin(angle * 3 + phase + ring * 0.7) *
            math.cos(angle * 2 - phase * 0.8);
        final r = (baseRadius * ringFactor) + offset;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(
          primaryGlow,
          Colors.white,
          ring * 0.18,
        )!.withValues(alpha: 0.75 - (ring * 0.1));
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceOrbPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isListening != isListening ||
        oldDelegate.isThinking != isThinking;
  }
}

/// Bottom Sheet untuk menampilkan **Layar OLED 0.96" (128x64)** & **Simulator Sensor Gelang**.
class _SmartbandAndOledModalSheet extends StatelessWidget {
  const _SmartbandAndOledModalSheet({required this.controller});

  final HajiCareAiController controller;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return ResponsiveCenter(
      maxWidth: AppBreakpoints.maxSheetWidth,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: hc.canvas,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          border: Border.all(color: hc.border),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Obx(() {
            final sensor = controller.sensorContext.value;
            final oled = controller.oledState.value;
            final ledActive = controller.isOledLedActive.value;
            final ble = controller.bleLinkStatus.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetDragHandle(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('ai.sheetOledTitle'),
                        style: context.text.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: hc.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: hc.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                OledSmartbandPreviewCard(
                  oledState: oled,
                  isLedActive: ledActive,
                  bleStatus: ble,
                  heartRateBpm: sensor.heartRateBpm,
                ),
                const SizedBox(height: AppSpacing.md),
                SensorContextLiveCard(
                  sensor: sensor,
                  isExpanded: true,
                  onToggleExpand: () {},
                  onRefreshTap: controller.refreshSensorsNow,
                  onConnectSmartbandTap: controller.connectSmartbandBle,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Bottom Sheet daftar Pertanyaan Cepat (Quick Prompts) untuk Jamaah.
class _QuickPromptsModalSheet extends StatelessWidget {
  const _QuickPromptsModalSheet({required this.controller});

  final HajiCareAiController controller;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return ResponsiveCenter(
      maxWidth: AppBreakpoints.maxSheetWidth,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: hc.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          border: Border.all(color: hc.border),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetDragHandle(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('ai.sheetQuickPromptsTitle'),
              style: context.text.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: hc.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final prompt in HajiCareAiController.localizedQuickPrompts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    controller.sendQuestion(prompt, autoSpeak: true);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: hc.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: hc.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: hc.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prompt,
                            style: context.text.bodyMedium.copyWith(
                              color: hc.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: hc.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// **Overlay Tombol Floating AI yang Dapat Digeser, Menempel di Tepi Kiri/Kanan,
/// & Mengecil Otomatis Saat Digeser ke Sudut Layar (`HajiCareDraggableAiOverlay`)**.
///
/// Dirancang sesuai preferensi pengguna:
/// - **Bulat Kompak (48dp):** Tidak memakan ruang layar dan mudah digeser ke mana saja.
/// - **Auto-Snap Kiri / Kanan:** Saat dilepas, otomatis menempel rapi ke tepi kiri atau kanan layar.
/// - **Auto-Shrink di Sudut / Tepi:** Jika digeser ke sudut atas/bawah layar atau merapat ke tepi,
///   otomatis mengecil menjadi tab tipis setengah-tersembunyi agar tidak pernah mengganggu pengguna.
/// - **Sekali Ketuk (`onTap`):** Langsung membuka `HajiCareAiAssistantPage`.
class HajiCareDraggableAiOverlay extends StatefulWidget {
  const HajiCareDraggableAiOverlay({
    super.key,
    this.bottomClearance = 114.0,
    this.openAsBottomSheet = false,
  });

  final double bottomClearance;
  final bool openAsBottomSheet;

  @override
  State<HajiCareDraggableAiOverlay> createState() =>
      _HajiCareDraggableAiOverlayState();
}

class _HajiCareDraggableAiOverlayState
    extends State<HajiCareDraggableAiOverlay> {
  static const double _expandedWidth = 140.0;
  static const double _expandedHeight = 44.0;
  static const double _miniWidth = 40.0;
  static const double _miniHeight = 42.0;
  static const double _edgePadding = 12.0;

  late final HajiCareAiController _controller;
  final ValueNotifier<Offset?> _dragPosNotifier = ValueNotifier<Offset?>(null);

  @override
  void initState() {
    super.initState();
    _controller = HajiCareAiBinding.ensureRegistered();
  }

  @override
  void dispose() {
    _dragPosNotifier.dispose();
    super.dispose();
  }

  void _openAiPage(BuildContext context) {
    HapticFeedback.lightImpact();
    if (widget.openAsBottomSheet) {
      HajiCareAiAssistantPage.showFloatingSheet(context);
    } else {
      Get.toNamed(AppRoutes.aiAssistant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top + 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final minY = topSafe;
        final maxY = math.max(
          minY + 40.0,
          maxH - widget.bottomClearance - _expandedHeight,
        );
        final usableHeight = math.max(1.0, maxY - minY);

        return Obx(() {
          if (Get.isRegistered<AppSettingsController>()) {
            Get.find<AppSettingsController>().rxLocale.value;
          }
          final dockedRight = _controller.fabDockedRight.value;
          final vFrac = _controller.fabVerticalFraction.value.clamp(0.0, 1.0);
          final cornerMinimized = _controller.fabCornerMinimized.value;

          return ValueListenableBuilder<Offset?>(
            valueListenable: _dragPosNotifier,
            builder: (context, dragPos, _) {
              final isDragging = dragPos != null;
              // Di awal (!cornerMinimized) tampil kapsul "✨ AI Assistant".
              // Ketika sudah di-snap ke samping (cornerMinimized == true), tulisan hilang dan menyisakan ikon ✨.
              final isMinimized = !isDragging && cornerMinimized;
              final showLabel = !isMinimized && !cornerMinimized;

              final btnW = showLabel ? _expandedWidth : _miniWidth;
              final btnH = showLabel ? _expandedHeight : _miniHeight;

              final double targetX;
              final double targetY;

              if (dragPos != null) {
                targetX = dragPos.dx.clamp(0.0, math.max(0.0, maxW - btnW));
                targetY = dragPos.dy.clamp(minY, maxY);
              } else {
                targetY = minY + (vFrac * usableHeight);
                if (isMinimized) {
                  targetX = dockedRight ? (maxW - btnW) : 0.0;
                } else {
                  targetX = dockedRight
                      ? (maxW - btnW - _edgePadding)
                      : _edgePadding;
                }
              }

              final BorderRadius borderRadius;
              if (isMinimized) {
                borderRadius = dockedRight
                    ? const BorderRadius.horizontal(left: Radius.circular(22))
                    : const BorderRadius.horizontal(right: Radius.circular(22));
              } else {
                borderRadius = BorderRadius.circular(AppRadius.pill);
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: targetX,
                    top: targetY,
                    width: btnW,
                    height: btnH,
                    child: RepaintBoundary(
                      child: GestureDetector(
                        key: const Key('tanya_ai_fab_button'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openAiPage(context),
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          HajiCareAiAssistantPage.showFloatingSheet(context);
                        },
                        onPanStart: (_) {
                          _dragPosNotifier.value = Offset(targetX, targetY);
                        },
                        onPanUpdate: (details) {
                          final cur =
                              _dragPosNotifier.value ?? Offset(targetX, targetY);
                          _dragPosNotifier.value = Offset(
                            (cur.dx + details.delta.dx).clamp(
                              0.0,
                              math.max(0.0, maxW - btnW),
                            ),
                            (cur.dy + details.delta.dy).clamp(minY, maxY),
                          );
                        },
                        onPanEnd: (_) {
                          final finalPos =
                              _dragPosNotifier.value ?? Offset(targetX, targetY);
                          final centerX = finalPos.dx + (btnW / 2);
                          final nextDockedRight = centerX >= (maxW / 2);
                          final nextVFrac = ((finalPos.dy - minY) / usableHeight)
                              .clamp(0.0, 1.0);

                          // Begitu pengguna menggeser dan men-snap tombol ke samping kiri/kanan,
                          // tulisan "AI Assistant" otomatis hilang (cornerMinimized: true)
                          // agar ringkas dan tidak menghalangi layar.
                          const nextMinimized = true;

                          HapticFeedback.selectionClick();
                          _dragPosNotifier.value = null;
                          _controller.updateFloatingButtonPosition(
                            dockedRight: nextDockedRight,
                            verticalFraction: nextVFrac,
                            cornerMinimized: nextMinimized,
                          );
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isMinimized ? 0.88 : 1.0,
                          child: Tooltip(
                            message: context.tr('ai.fabTooltip'),
                            child: Container(
                              padding: showLabel
                                  ? const EdgeInsets.symmetric(horizontal: 14)
                                  : EdgeInsets.zero,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2B1E16), Color(0xFF1A120D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: borderRadius,
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: isMinimized ? 1.2 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isMinimized ? 0.25 : 0.42,
                                    ),
                                    blurRadius: isMinimized ? 6 : 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: showLabel
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Color(0xFFD4AF37),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 7),
                                          Flexible(
                                            child: Text(
                                              context.tr('ai.fabLabel'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFFF5E6C8),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFFD4AF37),
                                        size: 19,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }
}

/// Komponen tombol kapsul kompak **AI Assistant** untuk kompatibilitas langsung jika dipakai di luar Stack.
class HajiCareAiFabButton extends StatelessWidget {
  const HajiCareAiFabButton({
    super.key,
    this.heroTag = 'hajicare_ai_assistant_fab',
    this.openAsBottomSheet = false,
  });

  final Object heroTag;
  final bool openAsBottomSheet;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: context.tr('ai.fabTooltip'),
        child: Tooltip(
          message: context.tr('ai.fabTooltip'),
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              key: const Key('tanya_ai_fab_button'),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () {
                HapticFeedback.lightImpact();
                if (openAsBottomSheet) {
                  HajiCareAiAssistantPage.showFloatingSheet(context);
                } else {
                  Get.toNamed(AppRoutes.aiAssistant);
                }
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                HajiCareAiAssistantPage.showFloatingSheet(context);
              },
              child: Ink(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2B1E16), Color(0xFF1A120D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFD4AF37),
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.tr('ai.fabLabel'),
                      style: const TextStyle(
                        color: Color(0xFFF5E6C8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
