import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/audio_track_widget.dart';

final class MindBulletWidget extends StatelessWidget {
  final MindBulletModel model;

  const MindBulletWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final List<BaseMindNotePiece> pieces = model.content.pieces;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    final List<Widget> contentWidgets = pieces.isEmpty
        ? <Widget>[
            SensitiveWidget(
              child: Text(model.content.plainText, maxLines: null, style: const TextStyle(fontSize: 15.0)),
            ),
          ]
        : <Widget>[];

    if (contentWidgets.isEmpty) {
      for (final BaseMindNotePiece piece in pieces) {
        if (contentWidgets.isNotEmpty) {
          contentWidgets.add(const Gap(12.0));
        }
        contentWidgets.add(
          piece.map(
            text: (MindNoteText textPiece) => SensitiveWidget(
              child: Align(
                alignment: .centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: .circular(18.0)),
                    child: Padding(
                      padding: .symmetric(horizontal: 14.0, vertical: 10.0),
                      child: Text(
                        textPiece.value,
                        maxLines: null,
                        style: TextStyle(fontSize: 15.0, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            audio: (MindNoteAudio audioPiece) => SensitiveWidget(
              child: AudioTrackWidget(audio: audioPiece, emoji: model.emoji),
            ),
            unknown: () => Padding(
              padding: .symmetric(horizontal: 14.0, vertical: 8.0),
              child: Text('Not supported media :(', style: const TextStyle(fontSize: 15.0)),
            ),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: .start,
      mainAxisSize: .max,
      children: [
        // TODO: just wathing how it goes without emoji on start...
        // const Gap(10.0),
        // Text(
        //   model.emoji,
        //   style: const TextStyle(fontSize: 25.0),
        // ),
        const Gap(10.0),
        Flexible(
          fit: .tight,
          child: Padding(
            padding: .symmetric(vertical: 6.0),
            child: Column(crossAxisAlignment: .end, mainAxisSize: .min, children: contentWidgets),
          ),
        ),
        const Gap(16.0),
      ],
    );
  }
}

final class MindBulletModel {
  final String entityId;
  final String emoji;
  final MindNoteContent content;

  const MindBulletModel({required this.entityId, required this.emoji, required this.content});
}
