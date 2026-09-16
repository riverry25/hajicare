class AppConfig {
  AppConfig._();

  static const String orsApiKey = String.fromEnvironment(
    'ORS_API_KEY',
    defaultValue: '',
  );

  static bool get hasOrsApiKey => orsApiKey.isNotEmpty;
}
