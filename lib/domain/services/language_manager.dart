import 'dart:ui';

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

  static SupportedLanguage fromCode(String code) => SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );

  Locale get locale {
    if (code == 'sr_Latn') {
      return const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
    }
    return Locale(code);
  }
}
