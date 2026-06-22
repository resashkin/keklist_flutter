part of 'used_emoji_cubit.dart';

final class UsedEmojiItem {
  final String emoji;
  final int count;
  const UsedEmojiItem({required this.emoji, required this.count});
}

final class UsedEmojiState {
  final List<UsedEmojiItem> usedEmojis;
  const UsedEmojiState({required this.usedEmojis});
}
