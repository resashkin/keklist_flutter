import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';

part 'used_emoji_state.dart';

final class UsedEmojiCubit extends Cubit<UsedEmojiState> {
  final MindRepository _repository;
  StreamSubscription<void>? _subscription;

  UsedEmojiCubit({required MindRepository repository})
      : _repository = repository,
        super(UsedEmojiState(usedEmojis: [])) {
    _compute();
    _subscription = _repository.stream.skip(1).listen((_) => _compute());
  }

  void _compute() {
    final minds = _repository.values;
    if (minds.isEmpty) {
      emit(UsedEmojiState(
        usedEmojis: KeklistConstants.defaultEmojiesToPick
            .map((e) => UsedEmojiItem(emoji: e, count: 0))
            .toList(),
      ));
      return;
    }

    final counts = <String, int>{};
    for (final mind in minds) {
      counts[mind.emoji] = (counts[mind.emoji] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final all = sorted.map((e) => UsedEmojiItem(emoji: e.key, count: e.value)).toList();

    emit(UsedEmojiState(usedEmojis: all));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
