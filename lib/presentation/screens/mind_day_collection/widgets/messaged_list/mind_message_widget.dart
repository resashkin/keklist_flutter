import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/screens/emotions/widgets/emotion_chip.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/mind_bullet_list_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/mind_bullet_widget.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';

final class MindMessageWidget extends StatelessWidget {
  final Mind mind;
  final List<Mind> children;
  final Function(Mind)? onRootOptions;
  final Function(Mind)? onChildOptions;

  const MindMessageWidget({
    super.key,
    required this.mind,
    required this.children,
    required this.onRootOptions,
    required this.onChildOptions,
  });

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      border: null,
      child: Column(
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        mind.emoji,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8.0),
                      SensitiveWidget(
                        child: Text(
                          mind.plainNote,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (mind.emotionIds.isNotEmpty) ...[
                        const SizedBox(height: 16.0),
                        _MindEmotionsRow(mind: mind),
                      ],
                    ],
                  ),
                ),
              ),
              if (onRootOptions != null) ...{
                Align(
                  alignment: Alignment.topRight,
                  child: SensitiveWidget(
                    mode: SensitiveMode.blurredAndNonTappable,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => onRootOptions?.call(mind),
                    ),
                  ),
                ),
              },
            ],
          ),
          if (children.isNotEmpty) ...[
            Container(height: 0.3, color: Colors.grey[300]),
            const Gap(16.0),
            MindBulletListWidget(
              models: children
                  .sortedByProperty((it) => it.creationDate)
                  .map(
                    (mind) => MindBulletModel(
                      entityId: mind.id,
                      emoji: mind.emoji,
                      content: mind.noteContent,
                    ),
                  )
                  .toList(),
              onLongPress: (String mindId) {
                final mind = children.firstWhere((it) => it.id == mindId);
                onChildOptions?.call(mind);
              },
            ),
            const SizedBox(height: 16.0),
          ]
        ],
      ),
    );
  }
}

/// Renders a mind's tagged emotions as small chips under its main emoji.
/// Resolves ids via [EmotionBloc] (archived included, so tagged minds still
/// show them) and skips ids that no longer resolve. Tapping a chip immediately
/// untags that emotion from the mind.
final class _MindEmotionsRow extends StatelessWidget {
  final Mind mind;

  const _MindEmotionsRow({required this.mind});

  void _remove(BuildContext context, String emotionId) {
    context.read<MindBloc>().add(
          MindSetEmotions(
            mindId: mind.id,
            emotionIds: mind.emotionIds.where((id) => id != emotionId).toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmotionBloc, EmotionState>(
      builder: (context, state) {
        if (state is! EmotionsList) return const SizedBox.shrink();
        final byId = {for (final Emotion emotion in state.emotions) emotion.id: emotion};
        final emotions = mind.emotionIds.map((id) => byId[id]).whereType<Emotion>().toList();
        if (emotions.isEmpty) return const SizedBox.shrink();

        return Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          alignment: WrapAlignment.center,
          children: [
            for (final emotion in emotions)
              EmotionChip(
                emojis: state.lineageEmojis(emotion),
                label: emotion.title,
                selected: true,
                onTap: () => _remove(context, emotion.id),
              ),
          ],
        );
      },
    );
  }
}
