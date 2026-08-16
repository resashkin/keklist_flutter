import 'package:keklist/domain/services/language_manager.dart';

/// The starter emotions created the first time the emotion marker is opened,
/// localized to the user's language. See
/// `documentation/adr/ADR-0003-localized-emotion-seeding.md`.
///
/// These are seed *data*, not UI strings, which is why they live here rather
/// than in the ARB files: they are written to Hive once at first use and never
/// rendered from a localization key. A language missing from [_titles] falls
/// back to English rather than throwing.
abstract final class EmotionSeed {
  /// Emoji for the five starter emotions, in display order. Emoji are
  /// language-neutral, so only the titles vary by locale.
  static const List<String> emojis = ['😠', '😨', '😢', '😄', '❤️'];

  /// Titles in the same order as [emojis]: angry, fear, sad, joy, love.
  static const Map<SupportedLanguage, List<String>> _titles = {
    SupportedLanguage.english: ['Angry', 'Fear', 'Sad', 'Joy', 'Love'],
    SupportedLanguage.russian: ['Злость', 'Страх', 'Грусть', 'Радость', 'Любовь'],
    SupportedLanguage.serbian: ['Бес', 'Страх', 'Туга', 'Радост', 'Љубав'],
    SupportedLanguage.serbianLatin: ['Bes', 'Strah', 'Tuga', 'Radost', 'Ljubav'],
    SupportedLanguage.kazakh: ['Ашу', 'Қорқыныш', 'Мұң', 'Қуаныш', 'Махаббат'],
    SupportedLanguage.kyrgyz: ['Ачуу', 'Коркуу', 'Капа', 'Кубаныч', 'Сүйүү'],
    SupportedLanguage.uzbek: ['Gʻazab', 'Qoʻrquv', 'Qaygʻu', 'Quvonch', 'Sevgi'],
    SupportedLanguage.spanish: ['Enfado', 'Miedo', 'Tristeza', 'Alegría', 'Amor'],
    SupportedLanguage.chinese: ['愤怒', '恐惧', '悲伤', '快乐', '爱'],
    SupportedLanguage.japanese: ['怒り', '恐れ', '悲しみ', '喜び', '愛'],
    SupportedLanguage.german: ['Wut', 'Angst', 'Trauer', 'Freude', 'Liebe'],
    SupportedLanguage.italian: ['Rabbia', 'Paura', 'Tristezza', 'Gioia', 'Amore'],
  };

  /// Starter emotions for [language], falling back to English.
  static List<({String emoji, String title})> forLanguage(SupportedLanguage language) {
    final titles = _titles[language] ?? _titles[SupportedLanguage.english]!;
    return [for (int i = 0; i < emojis.length; i++) (emoji: emojis[i], title: titles[i])];
  }
}
