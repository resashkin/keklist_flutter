import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';

part 'emoji_frequency_state.dart';

final class EmojiFrequencyCubit extends Cubit<EmojiFrequencyState> {
  final MindRepository _repository;
  StreamSubscription<void>? _subscription;

  EmojiFrequencyCubit({required MindRepository repository})
      : _repository = repository,
        super(EmojiFrequencyState(frequentEmojis: [])) {
    _compute();
    _subscription = _repository.stream.skip(1).listen((_) => _compute());
  }

  void _compute() {
    final minds = _repository.values;
    if (minds.isEmpty) {
      emit(EmojiFrequencyState(
        frequentEmojis: KeklistConstants.defaultEmojiesToPick
            .map((e) => EmojiFrequencyItem(emoji: e, count: 0))
            .toList(),
      ));
      return;
    }

    final counts = <String, int>{};
    for (final mind in minds) {
      counts[mind.emoji] = (counts[mind.emoji] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.take(10).map((e) => EmojiFrequencyItem(emoji: e.key, count: e.value)).toList();

    emit(EmojiFrequencyState(frequentEmojis: top10));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
