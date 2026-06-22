part of 'used_emoji_cubit.dart';

final class UsedEmojiItem extends Equatable {
  final String emoji;
  final int count;
  const UsedEmojiItem({required this.emoji, required this.count});

  @override
  List<Object?> get props => [emoji, count];
}

final class UsedEmojiState extends Equatable {
  final List<UsedEmojiItem> usedEmojis;
  const UsedEmojiState({required this.usedEmojis});

  @override
  List<Object?> get props => [usedEmojis];
}
