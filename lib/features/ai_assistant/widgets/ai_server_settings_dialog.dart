import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../bindings/hajicare_ai_binding.dart';
import '../controllers/hajicare_ai_controller.dart';
import '../models/ai_server_config.dart';
import '../models/ai_server_status.dart';

/// Modal / Dialog **"Pengaturan Server AI"** untuk mengubah Base URL Ngrok / IP Server,
/// API Key Bearer, dan Nama Model secara dinamis (`SharedPreferences`) tanpa rebuild APK.
///
/// Dapat dipanggil dari:
/// 1. Tombol ikon Settings (⚙️) di pojok kanan atas `HajiCareAiAssistantPage`.
/// 2. Menu **Pengaturan Server AI (Hermes)** di halaman **Profil (`ProfileScreen`)**.
class AiServerSettingsDialog extends StatefulWidget {
  const AiServerSettingsDialog({super.key, required this.controller});

  final HajiCareAiController controller;

  /// Tampilkan modal pengaturan server AI yang responsif.
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
  bool _isSaving = false;
  String? _urlValidationError;
  String? _apiKeyValidationError;

  @override
  void initState() {
    super.initState();
    final cfg = widget.controller.serverConfig.value;
    _urlController = TextEditingController(text: cfg.baseUrl);
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
    final urlErr = AiServerConfig.validateBaseUrl(_urlController.text);
    final keyErr = AiServerConfig.validateApiKey(_apiKeyController.text);
    setState(() {
      _urlValidationError = urlErr;
      _apiKeyValidationError = keyErr;
    });
    return urlErr == null && keyErr == null;
  }

  Future<void> _handleTestConnection() async {
    if (!_validateInputs()) return;
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
              : context.hc.primary,
          content: Text(
            status.isOnline
                ? 'Pengaturan Server AI disimpan & terhubung (${status.latency?.inMilliseconds ?? 0} ms).'
                : 'Pengaturan Server AI disimpan (${status.label}).',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleResetDefault() async {
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
                // Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: hc.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_ethernet_rounded,
                        color: hc.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengaturan Server AI',
                            style: context.text.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: hc.textPrimary,
                            ),
                          ),
                          Text(
                            'Hermes Agent • Ngrok Static Domain / IP Server',
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
                      tooltip: 'Tutup',
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
                  'Base URL Server (Ngrok / HTTPS / IP)',
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
                  style: context.text.bodyMedium.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://DOMAIN_STATIC_NGROK_KAMU.ngrok-free.app',
                    errorText: _urlValidationError,
                    prefixIcon: const Icon(Icons.cloud_queue_rounded, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Tempel dari Clipboard',
                          icon: const Icon(Icons.content_paste_rounded, size: 19),
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
                        IconButton(
                          tooltip: 'Bersihkan',
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
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Endpoint otomatis: /v1/chat/completions • Health: /health',
                  style: context.text.labelSmall.copyWith(
                    color: hc.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // API Key Input
                Text(
                  'API Key Bearer',
                  style: context.text.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hc.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  autocorrect: false,
                  style: context.text.bodyMedium.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: AiServerConfig.defaultApiKey,
                    errorText: _apiKeyValidationError,
                    prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                    suffixIcon: IconButton(
                      tooltip: _obscureApiKey ? 'Tampilkan' : 'Sembunyikan',
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 20,
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
                const SizedBox(height: AppSpacing.md),

                // Model Name Input
                Text(
                  'Model Name',
                  style: context.text.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hc.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _modelController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'hermes',
                    prefixIcon: const Icon(Icons.psychology_rounded, size: 20),
                    filled: true,
                    fillColor: hc.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Technical Headers Info Box
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: hc.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: hc.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 18,
                        color: hc.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Header HTTP aktif: Content-Type: application/json, '
                          'Authorization: Bearer, & ngrok-skip-browser-warning: true.',
                          style: context.text.labelSmall.copyWith(
                            color: hc.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _handleResetDefault,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 20),
                        label: const Text(
                          'Simpan & Hubungkan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hc.primary,
                          foregroundColor: hc.onPrimary,
                          minimumSize: const Size(double.infinity, 48),
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
      AiServerHealth.notConfigured => hc.warning,
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
        color: badgeColor.withValues(alpha: 0.08),
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
                  'Status Server: ${status.label}',
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
          TextButton.icon(
            onPressed: status.isChecking ? null : onTestTap,
            icon: const Icon(Icons.network_check_rounded, size: 16),
            label: const Text('Cek /health'),
          ),
        ],
      ),
    );
  }
}
