enum Flavor {
  dev,
  stg,
  prod,
}

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
  });

  final Flavor flavor;
  final String appName;

  static AppConfig? _instance;

  static AppConfig get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'AppConfig が未初期化です。main_dev.dart / main_stg.dart / main_prod.dart で '
        'AppConfig.initialize を呼び出してください。',
      );
    }
    return i;
  }

  static void initialize(AppConfig config) {
    _instance = config;
  }
}
