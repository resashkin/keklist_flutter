import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/my_table.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/widgets/mind_widget.dart';

class MindIconedListWidget extends StatelessWidget {
  final List<Mind> minds;
  final Map<String, int>? mindIdsToChildCount;
  final Function(Mind) onTap;
  final Function(Mind) onLongTap;

  const MindIconedListWidget({
    super.key,
    required this.minds,
    required this.onTap,
    required this.onLongTap,
    required this.mindIdsToChildCount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmotionBloc, EmotionState>(
      builder: (context, state) {
        final Map<String, String> emojiByEmotionId = state is EmotionsList
            ? {for (final emotion in state.emotions) emotion.id: emotion.emoji}
            : const {};
        return Column(
          children: [
            const SizedBox(height: 10.0),
            MyTable(
              widgets: minds
                  .map(
                    (mind) => MindWidget.sized(
                      item: mind.emoji,
                      size: MindSize.large,
                      onTap: () => onTap(mind),
                      onLongTap: () => onLongTap(mind),
                      isHighlighted: mind.plainNote.isNotEmpty || mind.audioNotes.isNotEmpty,
                      badge: _obtainBadgeText(mind),
                      emotionEmojis:
                          mind.emotionIds.map((id) => emojiByEmotionId[id]).whereType<String>().toList(),
                    ).animate().fadeIn(),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  String? _obtainBadgeText(Mind mind) {
    final int? count = mindIdsToChildCount?[mind.id];
    if (count == null || count == 0) {
      return null;
    }
    return '${mindIdsToChildCount?[mind.id]}';
  }
}
