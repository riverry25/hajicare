import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';

typedef SupportUriLauncher = Future<bool> Function(Uri uri);

/// Builds and opens the support channels configured for HajiCare.
class ProfileSupportService {
  ProfileSupportService({SupportUriLauncher? launcher})
    : _launcher = launcher ?? _launchExternally;

  final SupportUriLauncher _launcher;

  String get supportEmail => AppConstants.supportEmail.trim();

  bool get hasSupportEmail {
    final parts = supportEmail.split('@');
    return parts.length == 2 && parts.every((part) => part.trim().isNotEmpty);
  }

  String get supportWhatsAppDigits =>
      AppConstants.supportWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');

  bool get hasSupportWhatsApp {
    final digits = supportWhatsAppDigits;
    final isPlaceholder = RegExp(r'^(?:62)?0+$').hasMatch(digits);
    return digits.length >= 9 && !isPlaceholder;
  }

  Uri emailUri({bool reportProblem = false, String? platformLabel}) {
    final subject = reportProblem
        ? 'Laporan Masalah HajiCare'
        : 'Permintaan Bantuan HajiCare';
    final body = reportProblem
        ? [
            'Halo Tim HajiCare,',
            '',
            'Saya mengalami masalah berikut:',
            '[Tuliskan masalah di sini]',
            '',
            'Langkah sebelum masalah terjadi:',
            '[Tuliskan langkahnya di sini]',
            '',
            'Versi aplikasi: ${AppConstants.appVersion}',
            if (platformLabel != null && platformLabel.trim().isNotEmpty)
              'Perangkat: ${platformLabel.trim()}',
          ].join('\n')
        : [
            'Halo Tim HajiCare,',
            '',
            'Saya membutuhkan bantuan mengenai:',
            '[Tuliskan pertanyaan di sini]',
          ].join('\n');

    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': subject, 'body': body},
    );
  }

  Uri? get whatsAppUri {
    if (!hasSupportWhatsApp) return null;
    return Uri.https('wa.me', '/$supportWhatsAppDigits', {
      'text': 'Halo Tim HajiCare, saya membutuhkan bantuan.',
    });
  }

  Future<bool> openEmail({
    bool reportProblem = false,
    String? platformLabel,
  }) async {
    if (!hasSupportEmail) return false;
    return _tryLaunch(
      emailUri(reportProblem: reportProblem, platformLabel: platformLabel),
    );
  }

  Future<bool> openWhatsApp() async {
    final uri = whatsAppUri;
    if (uri == null) return false;
    return _tryLaunch(uri);
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await _launcher(uri);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _launchExternally(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
