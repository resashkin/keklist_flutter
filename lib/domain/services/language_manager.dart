import 'dart:async';
import 'dart:ui';

import 'package:rxdart/rxdart.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

/// Language codes supported by the app
enum SupportedLanguage {
  english('en', 'English', '🇺🇸'),
  russian('ru', 'Русский', '🇷🇺'),
  serbian('sr', 'Српски (ћирилица)', '🇷🇸'),
  serbianLatin('sr_Latn', 'Srpski (latinica)', '🇷🇸'),
  kazakh('kk', 'Қазақша', '🇰🇿'),
  kyrgyz('ky', 'Кыргызча', '🇰🇬'),
  uzbek('uz', 'Oʻzbekcha', '🇺🇿'),
  spanish('es', 'Español', '🇪🇸'),
  chinese('zh', '中文', '🇨🇳'),
  japanese('ja', '日本語', '🇯🇵'),
  german('de', 'Deutsch', '🇩🇪'),
  italian('it', 'Italiano', '🇮🇹');

  const SupportedLanguage(this.code, this.displayName, this.flag);

  final String code;
  final String displayName;
  final String flag;

  static SupportedLanguage fromCode(String code) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );
  }

  Locale get locale {
    if (code == 'sr_Latn') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    }
    return Locale(code);
  }
}

/// Manages app language settings and provides reactive language changes
final class LanguageManager {
  static const String _languageKey = 'app_language';

  final StreamingSharedPreferences _preferences;
  final BehaviorSubject<SupportedLanguage> _languageSubject = BehaviorSubject<SupportedLanguage>();

  LanguageManager({required StreamingSharedPreferences preferences}) : _preferences = preferences {
    _initializeLanguage();
  }

  /// Current selected language
  SupportedLanguage get currentLanguage => _languageSubject.value;

  /// Stream of language changes
  Stream<SupportedLanguage> get languageStream => _languageSubject.stream;

  /// Get current locale for MaterialApp
  Locale get currentLocale => currentLanguage.locale;

  /// Initialize language from preferences or device locale
  Future<void> _initializeLanguage() async {
    try {
      // Try to get saved language preference
      final String savedLanguage = _preferences.getString(_languageKey, defaultValue: '').getValue();

      if (savedLanguage.isNotEmpty) {
        // User has previously set a language preference, use it
        _languageSubject.add(SupportedLanguage.fromCode(savedLanguage));
      } else {
        // First launch - detect device locale
        final deviceLocale = _detectDeviceLocale();
        _languageSubject.add(deviceLocale);
        await setLanguage(deviceLocale);
      }
    } catch (e) {
      // Fallback - detect device locale
      final deviceLocale = _detectDeviceLocale();
      _languageSubject.add(deviceLocale);
      await setLanguage(deviceLocale);
    }
  }

  /// Detect device locale and return supported language or fallback to English
  SupportedLanguage _detectDeviceLocale() {
    final deviceLocale = PlatformDispatcher.instance.locale;
    final deviceLanguageCode = deviceLocale.languageCode;
    final deviceScriptCode = deviceLocale.scriptCode;

    // Special handling for Serbian with script detection
    if (deviceLanguageCode == 'sr') {
      if (deviceScriptCode == 'Latn') {
        return SupportedLanguage.serbianLatin;
      } else {
        return SupportedLanguage.serbian;
      }
    }

    // Try to find exact match
    for (final language in SupportedLanguage.values) {
      if (language.code == deviceLanguageCode) {
        return language;
      }
    }

    // Try to find partial match (e.g., 'zh-CN' -> 'zh')
    for (final language in SupportedLanguage.values) {
      if (deviceLanguageCode.startsWith(language.code)) {
        return language;
      }
    }

    // Fallback to English
    return SupportedLanguage.english;
  }

  /// Set app language
  Future<void> setLanguage(SupportedLanguage language) async {
    await _preferences.setString(_languageKey, language.code);
    _languageSubject.add(language);
  }

  /// Get all supported languages for UI
  List<SupportedLanguage> get supportedLanguages => SupportedLanguage.values;

  /// Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return SupportedLanguage.values.any((lang) => lang.code == languageCode);
  }

  /// Dispose resources
  void dispose() {
    _languageSubject.close();
  }
}
