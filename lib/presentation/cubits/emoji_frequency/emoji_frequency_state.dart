part of 'emoji_frequency_cubit.dart';

final class EmojiFrequencyItem {
  final String emoji;
  final int count;
  const EmojiFrequencyItem({required this.emoji, required this.count});
}

final class EmojiFrequencyState {
  final List<EmojiFrequencyItem> frequentEmojis;
  const EmojiFrequencyState({required this.frequentEmojis});
}
