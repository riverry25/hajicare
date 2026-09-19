class AppConfig {
  AppConfig._();

  /// OpenRouteService / HeiGIT API Key.
  ///
  /// [SECURITY NOTICE]:
  /// For production environments, API keys should not be bundled inside client binaries.
  /// A backend proxy (e.g. Firebase HTTPS Cloud Function / Node proxy) should mediate requests:
  /// Flutter Client -> Secure Backend Proxy -> HeiGIT ORS -> Flutter Client.
  ///
  /// For local development / academic evaluation only, `--dart-define=ORS_API_KEY=your_key`
  /// can be passed during build. If empty, the app gracefully falls back to public OSRM foot routing.
  static const String orsApiKey = String.fromEnvironment(
    'ORS_API_KEY',
    defaultValue: '',
  );

  static bool get hasOrsApiKey => orsApiKey.isNotEmpty;
}
