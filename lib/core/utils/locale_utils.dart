import 'dart:ui';

class LocaleUtils {
  LocaleUtils._();

  /// デバイスの言語コードを取得
  /// 例: ja, en, zh, ko, es, fr
  static String get deviceLanguageCode {
    final locale = PlatformDispatcher.instance.locale;
    return locale.languageCode;
  }

  /// 翻訳が必要か判定（英語は不要）
  static bool get needsTranslation {
    return deviceLanguageCode != 'en';
  }

  /// 言語コードの表示名（バッジ用）
  static String get languageLabel {
    return deviceLanguageCode.toUpperCase();
  }
}
