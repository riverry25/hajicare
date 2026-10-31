import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../bindings/hajicare_ai_binding.dart';
import '../controllers/hajicare_ai_controller.dart';
import '../models/ai_server_config.dart';
import '../models/ai_server_status.dart';

/// Modal / BottomSheet **"Pengaturan Server AI"** untuk mengubah Base URL Ngrok / IP Server,
/// API Key Bearer, dan Nama Model secara dinamis (`SharedPreferences`) tanpa rebuild APK.
class AiServerSettingsDialog extends StatefulWidget {
  const AiServerSettingsDialog({super.key, required this.controller});

  final HajiCareAiController controller;

  /// Tampilkan modal pengaturan server AI yang bersih dan responsif.
  static Future<void> show(BuildContext context) async {
    final ctrl = HajiCareAiBinding.ensureRegistered();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiServerSettingsDialog(controller: ctrl),
    );
  }

  @override
  State<AiServerSettingsDialog> createState() => _AiServerSettingsDialogState();
}

class _AiServerSettingsDialogState extends State<AiServerSettingsDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;

  bool _obscureApiKey = true;
  bool _showAdvanced = true;
  bool _isSaving = false;
  String? _urlValidationError;
  String? _apiKeyValidationError;

  @override
  void initState() {
    super.initState();
    final cfg = widget.controller.serverConfig.value;
    _urlController = TextEditingController(
      text: cfg.isPlaceholder ? '' : cfg.baseUrl,
    );
    _apiKeyController = TextEditingController(text: cfg.apiKey);
    _modelController = TextEditingController(text: cfg.model);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _urlValidationError = AppTranslations.tr('ai.settingsUrlEmptyError');
      });
      return false;
    }
    final urlErr = AiServerConfig.validateBaseUrl(rawUrl);
    final keyErr = AiServerConfig.validateApiKey(_apiKeyController.text);
    setState(() {
      _urlValidationError = urlErr;
      _apiKeyValidationError = keyErr;
      if (keyErr != null) _showAdvanced = true;
    });
    return urlErr == null && keyErr == null;
  }

  Future<void> _handleTestConnection() async {
    if (!_validateInputs()) return;
    HapticFeedback.selectionClick();
    final tempConfig = AiServerConfig(
      baseUrl: AiServerConfig.normalizeBaseUrl(_urlController.text),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? AiServerConfig.defaultModel
          : _modelController.text.trim(),
    );
    await widget.controller.checkServerHealth(tempConfig);
  }

  Future<void> _handleSave() async {
    if (!_validateInputs()) return;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);
    try {
      final status = await widget.controller.saveServerConfiguration(
        baseUrl: _urlController.text,
        apiKey: _apiKeyController.text,
        model: _modelController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: status.isOnline
              ? context.hc.success
              : context.hc.surface,
          content: Text(
            status.isOnline
                ? 'Terhubung ke Hermes Server (${status.latency?.inMilliseconds ?? 0} ms)'
                : 'URL disimpan (${status.label})',
            style: TextStyle(
              color: status.isOnline
                  ? Colors.white
                  : context.hc.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleResetDefault() async {
    HapticFeedback.selectionClick();
    await widget.controller.resetServerConfiguration();
    final cfg = widget.controller.serverConfig.value;
    if (!mounted) return;
    setState(() {
      _urlController.text = cfg.baseUrl;
      _apiKeyController.text = cfg.apiKey;
      _modelController.text = cfg.model;
      _urlValidationError = null;
      _apiKeyValidationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return ResponsiveCenter(
      maxWidth: AppBreakpoints.maxSheetWidth,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: hc.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            border: Border.all(color: hc.border),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: hc.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hc.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.dns_rounded,
                        color: hc.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('ai.settingsTitle'),
                            style: context.text.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: hc.textPrimary,
                            ),
                          ),
                          Text(
                            context.tr('ai.settingsSubtitle'),
                            style: context.text.bodySmall.copyWith(
                              color: hc.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: hc.textSecondary),
                      tooltip: context.tr('btn.close'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Live Server Health Banner
                Obx(() {
                  final status = widget.controller.serverStatus.value;
                  return _ServerHealthBanner(
                    status: status,
                    onTestTap: _handleTestConnection,
                  );
                }),
                const SizedBox(height: AppSpacing.lg),

                // Base URL Input
                Text(
                  context.tr('ai.settingsServerUrlLabel'),
                  style: context.text.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hc.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: context.text.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'https://unbalance-compile-chariot.ngrok-free.dev',
                    errorText: _urlValidationError,
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: context.tr('ai.settingsPasteUrlTooltip'),
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            size: 19,
                          ),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            final pasted = data?.text?.trim();
                            if (pasted != null && pasted.isNotEmpty) {
                              _urlController.text =
                                  AiServerConfig.normalizeBaseUrl(pasted);
                              setState(() => _urlValidationError = null);
                            }
                          },
                        ),
                        if (_urlController.text.isNotEmpty)
                          IconButton(
                            tooltip: context.tr('ai.settingsClearTooltip'),
                            icon: const Icon(Icons.clear_rounded, size: 19),
                            onPressed: () {
                              _urlController.clear();
                              setState(() => _urlValidationError = null);
                            },
                          ),
                      ],
                    ),
                    filled: true,
                    fillColor: hc.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onChanged: (_) {
                    if (_urlValidationError != null) {
                      setState(() => _urlValidationError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Opsi Lanjutan (API Key & Model) - Collapsible agar tidak memenuhi layar
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: hc.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('ai.settingsAdvancedLabel'),
                            style: context.text.labelMedium.copyWith(
                              color: hc.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          _showAdvanced
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: hc.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAdvanced) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr('ai.settingsApiKeyLabel'),
                    style: context.text.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: hc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: AiServerConfig.defaultApiKey,
                      errorText: _apiKeyValidationError,
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 19,
                        ),
                        onPressed: () =>
                            setState(() => _obscureApiKey = !_obscureApiKey),
                      ),
                      filled: true,
                      fillColor: hc.surfaceSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr('ai.settingsModelLabel'),
                    style: context.text.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: hc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _modelController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'ngoding-combo',
                      prefixIcon: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: hc.surfaceSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Tombol Aksi (Kontras Tinggi WCAG AA pada Light & Dark Mode)
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : _handleResetDefault,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(88, 50),
                        side: BorderSide(color: hc.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(
                        context.tr('ai.settingsResetBtn'),
                        style: context.text.labelLarge.copyWith(
                          color: hc.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: hc.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: hc.onPrimary,
                              ),
                        label: Text(
                          context.tr('ai.settingsSaveConnectBtn'),
                          style: context.text.labelLarge.copyWith(
                            color: hc.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hc.primary,
                          foregroundColor: hc.onPrimary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerHealthBanner extends StatelessWidget {
  const _ServerHealthBanner({
    required this.status,
    required this.onTestTap,
  });

  final AiServerStatus status;
  final VoidCallback onTestTap;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final Color badgeColor = switch (status.health) {
      AiServerHealth.online => hc.success,
      AiServerHealth.checking => hc.info,
      AiServerHealth.notConfigured => hc.accent,
      AiServerHealth.unauthorized => hc.danger,
      AiServerHealth.offline => hc.danger,
      AiServerHealth.unknown => hc.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          if (status.isChecking)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: badgeColor,
              ),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.health == AiServerHealth.notConfigured
                      ? context.tr('ai.settingsSmartDemoActive')
                      : '${context.tr('ai.settingsServerStatusPrefix')}${status.label}',
                  style: context.text.labelMedium.copyWith(
                    color: hc.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (status.message != null && status.message!.isNotEmpty)
                  Text(
                    status.message!,
                    style: context.text.labelSmall.copyWith(
                      color: hc.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: status.isChecking ? null : onTestTap,
            child: Text(context.tr('ai.settingsTestConnectionBtn')),
          ),
        ],
      ),
    );
  }
}
