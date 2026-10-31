import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../bindings/hajicare_ai_binding.dart';
import '../controllers/hajicare_ai_controller.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_server_status.dart';
import '../models/sensor_context.dart';
import 'ai_server_settings_dialog.dart';
import 'oled_smartband_preview_card.dart';
import 'sensor_context_live_card.dart';

export 'ai_server_settings_dialog.dart';
export 'oled_smartband_preview_card.dart';
export 'sensor_context_live_card.dart';

/// Halaman utama **HajiCare AI Voice Assistant (Powered by Hermes Agent)**.
///
/// Mendukung dua mode tampilan:
/// 1. Halaman penuh (`HajiCareAiAssistantPage(isBottomSheet: false)`) via rute
///    `AppRoutes.aiAssistant` atau tombol FAB **"Tanya AI"**.
/// 2. Floating Bottom Sheet (`HajiCareAiAssistantPage.showFloatingSheet(context)`).
///
/// Mengadaptasi tata letak secara otomatis menggunakan `LayoutBuilder`:
/// - Layar Compact (`< 600dp`): Susunan vertikal dengan kartu sensor collapsible.
/// - Layar Medium/Expanded (`>= 600dp`, Tablet/Foldable/Landscape): Split-view
///   2 kolom (panel kiri: Sensor Live + OLED 128x64, panel kanan: Chat + Input).
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

  @override
  State<HajiCareAiAssistantPage> createState() =>
      _HajiCareAiAssistantPageState();
}

class _HajiCareAiAssistantPageState extends State<HajiCareAiAssistantPage> {
  late final HajiCareAiController _controller;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  Worker? _messagesWorker;

  @override
  void initState() {
    super.initState();
    _controller = HajiCareAiBinding.ensureRegistered();
    _textController = TextEditingController();
    _scrollController = ScrollController();

    _messagesWorker = ever<List<AiChatMessage>>(_controller.messages, (_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messagesWorker?.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
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

              // 1. Header & Status Bar (Hermes /health + BLE Gelang + ⚙️ Settings)
              _AiAssistantHeader(
                controller: _controller,
                isBottomSheet: widget.isBottomSheet,
              ),

              // 2. Body Adaptif (Compact 1-kolom vs Tablet/Landscape 2-kolom)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 680;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 310,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.sm,
                                AppSpacing.md,
                              ),
                              child: _TelemetryAndOledPanel(
                                controller: _controller,
                              ),
                            ),
                          ),
                          VerticalDivider(width: 1, color: hc.border),
                          Expanded(
                            child: _ConversationAndInputColumn(
                              controller: _controller,
                              scrollController: _scrollController,
                              textController: _textController,
                              onSubmitText: _handleSubmitText,
                            ),
                          ),
                        ],
                      );
                    }

                    return _ConversationAndInputColumn(
                      controller: _controller,
                      scrollController: _scrollController,
                      textController: _textController,
                      onSubmitText: _handleSubmitText,
                      topPanel: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: _TelemetryAndOledPanel(controller: _controller),
                      ),
                    );
                  },
                ),
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
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: context.hc.border,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

/// Header & Status Bar:
/// - Judul asisten AI
/// - Tombol ikon Settings (⚙️) di pojok kanan atas
/// - Indikator status koneksi Server Hermes (`Online`/`Offline` via `/health`)
///   dan status koneksi BLE Gelang.
class _AiAssistantHeader extends StatelessWidget {
  const _AiAssistantHeader({
    required this.controller,
    required this.isBottomSheet,
  });

  final HajiCareAiController controller;
  final bool isBottomSheet;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: hc.surface,
        border: Border(bottom: BorderSide(color: hc.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  isBottomSheet
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.arrow_back_rounded,
                  color: hc.textPrimary,
                ),
                tooltip: 'Kembali',
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [hc.primary, hc.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HajiCare AI Assistant',
                      style: context.text.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: hc.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Powered by Hermes Agent • Suara & Smartband OLED',
                      style: context.text.labelSmall.copyWith(
                        color: hc.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.clearConversation,
                tooltip: 'Bersihkan Percakapan',
                icon: Icon(
                  Icons.refresh_rounded,
                  color: hc.textSecondary,
                  size: 21,
                ),
              ),
              // Tombol ikon Settings (⚙️) di pojok kanan atas
              IconButton(
                key: const Key('ai_settings_gear_button'),
                onPressed: () => AiServerSettingsDialog.show(context),
                tooltip: 'Pengaturan Server AI (⚙️)',
                icon: Icon(
                  Icons.settings_rounded,
                  color: hc.primary,
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Baris Indikator Status Server Hermes & BLE Gelang
          Obx(() {
            final srv = controller.serverStatus.value;
            final ble = controller.bleLinkStatus.value;
            final sim = controller.isSimulationMode.value;

            final Color srvColor = switch (srv.health) {
              AiServerHealth.online => hc.success,
              AiServerHealth.checking => hc.info,
              AiServerHealth.notConfigured => hc.warning,
              AiServerHealth.unauthorized => hc.danger,
              AiServerHealth.offline => hc.danger,
              AiServerHealth.unknown => hc.textSecondary,
            };

            final bool bleConnected = ble == SmartbandLinkStatus.connected;
            final Color bleColor = bleConnected
                ? hc.success
                : (sim ? hc.info : hc.warning);
            final String bleLabel = bleConnected
                ? 'BLE Gelang: Terhubung'
                : (sim ? 'Gelang: Simulasi Aktif' : 'BLE Gelang: Terputus');

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 6,
              children: [
                _StatusPillChip(
                  dotColor: srvColor,
                  isLoading: srv.isChecking,
                  label: 'Hermes: ${srv.label}',
                  onTap: () => AiServerSettingsDialog.show(context),
                ),
                _StatusPillChip(
                  dotColor: bleColor,
                  icon: bleConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.watch_rounded,
                  label: bleLabel,
                  onTap: bleConnected
                      ? null
                      : () => controller.connectSmartbandBle(),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StatusPillChip extends StatelessWidget {
  const _StatusPillChip({
    required this.dotColor,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onTap,
  });

  final Color dotColor;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: dotColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: dotColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: dotColor,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 13, color: dotColor)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
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
    );
  }
}

class _TelemetryAndOledPanel extends StatelessWidget {
  const _TelemetryAndOledPanel({required this.controller});

  final HajiCareAiController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sensor = controller.sensorContext.value;
      final isExpanded = controller.isSensorCardExpanded.value;
      final isSim = controller.isSimulationMode.value;
      final oled = controller.oledState.value;
      final ledActive = controller.isOledLedActive.value;
      final ble = controller.bleLinkStatus.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SensorContextLiveCard(
            sensor: sensor,
            isExpanded: isExpanded,
            isSimulationMode: isSim,
            onToggleExpand: controller.toggleSensorCardExpanded,
            onToggleSimulation: controller.toggleSimulationMode,
            onToggleFallSimulation: controller.toggleSimulatedFall,
            onRefreshTap: controller.refreshSensorsNow,
          ),
          const SizedBox(height: AppSpacing.xs),
          OledSmartbandPreviewCard(
            oledState: oled,
            isLedActive: ledActive,
            bleStatus: ble,
            heartRateBpm: sensor.heartRateBpm,
          ),
        ],
      );
    });
  }
}

class _ConversationAndInputColumn extends StatelessWidget {
  const _ConversationAndInputColumn({
    required this.controller,
    required this.scrollController,
    required this.textController,
    required this.onSubmitText,
    this.topPanel,
  });

  final HajiCareAiController controller;
  final ScrollController scrollController;
  final TextEditingController textController;
  final VoidCallback onSubmitText;
  final Widget? topPanel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Area Scrollable: Top Panel (pada layar ponsel) + Daftar Gelembung Chat
        Expanded(
          child: Obx(() {
            final msgs = controller.messages;
            final speakingId = controller.activeSpeakingMessageId.value;
            final isSpeaking = controller.isSpeaking.value;
            final bannerMsg = controller.statusBannerMessage.value;

            return CustomScrollView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (topPanel != null) SliverToBoxAdapter(child: topPanel),
                if (bannerMsg != null && bannerMsg.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _OfflineNoticeBanner(
                      message: bannerMsg,
                      onOpenSettings: () => AiServerSettingsDialog.show(context),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverList.separated(
                    itemCount: msgs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final message = msgs[index];
                      final isMsgSpeaking =
                          isSpeaking && speakingId == message.id;
                      return _AiChatBubble(
                        message: message,
                        isCurrentlySpeaking: isMsgSpeaking,
                        onSpeakTap: () => controller.speakMessage(message),
                        onSendToOledTap: () =>
                            controller.resendOledFromMessage(message),
                        onRetryTap: message.retryPrompt != null
                            ? () => controller.sendQuestion(
                                message.retryPrompt!,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),

        // Deretan Tombol Cepat (Quick Prompts) Sekali Sentuh
        _QuickPromptChipsBar(
          onSelectPrompt: (prompt) =>
              controller.sendQuestion(prompt, autoSpeak: true),
        ),

        // Kontrol Input Bawah (Banner Stop TTS + Push-to-Talk Mic + Text Input)
        _BottomVoiceAndTextBar(
          controller: controller,
          textController: textController,
          onSubmitText: onSubmitText,
        ),
      ],
    );
  }
}

class _OfflineNoticeBanner extends StatelessWidget {
  const _OfflineNoticeBanner({
    required this.message,
    required this.onOpenSettings,
  });

  final String message;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: hc.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: hc.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 17, color: hc.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.text.labelSmall.copyWith(
                  color: hc.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onOpenSettings,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Atur URL'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatBubble extends StatelessWidget {
  const _AiChatBubble({
    required this.message,
    required this.isCurrentlySpeaking,
    required this.onSpeakTap,
    required this.onSendToOledTap,
    this.onRetryTap,
  });

  final AiChatMessage message;
  final bool isCurrentlySpeaking;
  final VoidCallback onSpeakTap;
  final VoidCallback onSendToOledTap;
  final VoidCallback? onRetryTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final isUser = message.isUser;

    if (message.isPending) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: hc.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: hc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: hc.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Hermes sedang menganalisis sensor & menyiapkan jawaban...',
                  style: context.text.bodySmall.copyWith(
                    color: hc.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isUser ? hc.primary : hc.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.card),
              topRight: const Radius.circular(AppRadius.card),
              bottomLeft: Radius.circular(isUser ? AppRadius.card : 4),
              bottomRight: Radius.circular(isUser ? 4 : AppRadius.card),
            ),
            border: isUser ? null : Border.all(color: hc.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: hc.accent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          message.isOfflineFallback
                              ? 'Hermes AI (Asisten Sensor Lokal)'
                              : 'Hermes AI Assistant',
                          style: context.text.labelSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: hc.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Isi kalimat penjelasan ramah
              Text(
                message.text,
                style: context.text.bodyMedium.copyWith(
                  color: isUser ? hc.onPrimary : hc.textPrimary,
                  height: 1.45,
                  fontSize: 15,
                ),
              ),

              // Ringkasan OLED + Tombol 🔊 Speak pada balasan AI
              if (!isUser && message.isSpeakable) ...[
                if (message.oledText != null &&
                    message.oledText!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1116),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.watch_outlined,
                          size: 14,
                          color: Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'AI:${message.oledText}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 6,
                  children: [
                    // Tombol 🔊 Speak / Hentikan
                    InkWell(
                      onTap: onSpeakTap,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentlySpeaking
                              ? hc.danger.withValues(alpha: 0.12)
                              : hc.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isCurrentlySpeaking
                                ? hc.danger.withValues(alpha: 0.4)
                                : hc.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrentlySpeaking
                                  ? Icons.stop_circle_rounded
                                  : Icons.volume_up_rounded,
                              size: 16,
                              color: isCurrentlySpeaking
                                  ? hc.danger
                                  : hc.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCurrentlySpeaking
                                  ? 'Hentikan Suara'
                                  : '🔊 Dengarkan Suara',
                              style: context.text.labelSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isCurrentlySpeaking
                                    ? hc.danger
                                    : hc.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tombol Kirim Ulang ke OLED Gelang
                    InkWell(
                      onTap: onSendToOledTap,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hc.surfaceSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: hc.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send_to_mobile_rounded,
                              size: 14,
                              color: hc.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Kirim ke OLED',
                              style: context.text.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: hc.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (message.isError && onRetryTap != null) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: onRetryTap,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Deretan tombol cepat (Quick Prompts) sekali sentuh untuk demo cepat.
class _QuickPromptChipsBar extends StatelessWidget {
  const _QuickPromptChipsBar({required this.onSelectPrompt});

  final ValueChanged<String> onSelectPrompt;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: hc.surface,
        border: Border(top: BorderSide(color: hc.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final prompt in HajiCareAiController.quickPrompts)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ActionChip(
                  avatar: Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: hc.primary,
                  ),
                  label: Text(
                    prompt,
                    style: context.text.labelMedium.copyWith(
                      color: hc.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: hc.surfaceSubtle,
                  side: BorderSide(color: hc.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onSelectPrompt(prompt);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kontrol Input Bawah:
/// - Banner & tombol hentikan suara (`flutter_tts.stop()`) saat AI sedang berbicara
/// - Pratinjau transkripsi suara langsung saat mikrofon merekam
/// - Tombol mikrofon besar beranimasi pulse (`speech_to_text` bahasa `id_ID`)
/// - Kolom ketik teks manual dan tombol kirim
class _BottomVoiceAndTextBar extends StatelessWidget {
  const _BottomVoiceAndTextBar({
    required this.controller,
    required this.textController,
    required this.onSubmitText,
  });

  final HajiCareAiController controller;
  final TextEditingController textController;
  final VoidCallback onSubmitText;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: hc.surface,
        border: Border(top: BorderSide(color: hc.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Hentikan Suara (flutter_tts.stop()) saat AI sedang berbicara
          Obx(() {
            if (!controller.isSpeaking.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  key: const Key('stop_tts_button'),
                  onPressed: controller.stopSpeaking,
                  icon: const Icon(Icons.stop_circle_rounded, size: 20),
                  label: const Text(
                    'Hentikan Suara Asisten (Stop TTS)',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

          // Banner transkripsi suara aktif saat mikrofon merekam
          Obx(() {
            final listening = controller.isListening.value;
            final partial = controller.recognizedText.value;
            final statusMsg = controller.voiceStatusMessage.value;
            if (!listening && partial.isEmpty) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: hc.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: hc.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    color: hc.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      partial.isNotEmpty ? '"$partial"' : statusMsg,
                      style: context.text.bodySmall.copyWith(
                        color: hc.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (listening)
                    TextButton(
                      onPressed: controller.stopListeningAndSendIfAny,
                      child: const Text('Selesai'),
                    ),
                ],
              ),
            );
          }),

          // Baris Input: Tombol Mikrofon Pulse Besar + TextField + Tombol Kirim
          Row(
            children: [
              Obx(() {
                final listening = controller.isListening.value;
                return _PulsingMicButton(
                  isListening: listening,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.toggleVoiceRecording();
                  },
                );
              }),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmitText(),
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ketik atau tekan 🎙️ untuk bicara...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: hc.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide(color: hc.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide(color: hc.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Obx(() {
                final busy = controller.isSending.value;
                return SizedBox(
                  width: AppSizes.touchTargetMin,
                  height: AppSizes.touchTargetMin,
                  child: IconButton.filled(
                    key: const Key('send_ai_question_button'),
                    onPressed: busy ? null : onSubmitText,
                    style: IconButton.styleFrom(
                      backgroundColor: hc.primary,
                      foregroundColor: hc.onPrimary,
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    tooltip: 'Kirim Pertanyaan',
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol mikrofon besar beranimasi pulse saat merekam suara (`RepaintBoundary`).
class _PulsingMicButton extends StatefulWidget {
  const _PulsingMicButton({
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback onTap;

  @override
  State<_PulsingMicButton> createState() => _PulsingMicButtonState();
}

class _PulsingMicButtonState extends State<_PulsingMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final activeColor = widget.isListening ? hc.danger : hc.primary;

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: widget.isListening
            ? 'Hentikan rekaman mikrofon'
            : 'Rekam pertanyaan suara Bahasa Indonesia',
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.14);
              return Transform.scale(
                scale: widget.isListening ? scale : 1.0,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isListening ? Colors.white : hc.accent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: widget.isListening ? 0.45 : 0.22,
                        ),
                        blurRadius: widget.isListening ? 16 : 8,
                        spreadRadius: widget.isListening ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// **Floating Action Button (FAB) "Tanya AI"** yang ramah lansia dan mudah
/// diakses dari dashboard utama aplikasi `hajicare`.
///
/// - Ketuk sekali: Membuka halaman penuh `HajiCareAiAssistantPage`.
/// - Tekan lama: Membuka `HajiCareAiAssistantPage` sebagai Floating Bottom Sheet.
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
    final hc = context.hc;

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: 'Tanya AI HajiCare Assistant',
        child: Tooltip(
          message: 'Tanya AI HajiCare (Hermes Voice Assistant)',
          child: Material(
            color: Colors.transparent,
            elevation: 6,
            shadowColor: hc.shadow,
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
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [hc.primary, const Color(0xFF5A3E28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: hc.accent, width: 1.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: hc.accent.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: hc.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tanya AI',
                      style: context.text.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
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

