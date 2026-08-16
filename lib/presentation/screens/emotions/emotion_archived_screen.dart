import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

/// Lists archived emotions. They still render on minds that use them, but are
/// hidden from pickers. From here the user can restore or permanently delete.
final class EmotionArchivedScreen extends StatelessWidget {
  const EmotionArchivedScreen({super.key});

  Future<void> _delete(BuildContext context, Emotion emotion) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: emotion.title,
      message: context.l10n.deleteEmotionMessage,
      okLabel: context.l10n.deletePermanently,
      isDestructiveAction: true,
    );
    if (result == OkCancelResult.ok && context.mounted) {
      context.read<EmotionBloc>().add(EmotionDelete(id: emotion.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.archived)),
      body: BlocBuilder<EmotionBloc, EmotionState>(
        builder: (context, state) {
          if (state is! EmotionsList) {
            return const Center(child: CircularProgressIndicator());
          }
          final archived = state.archivedEmotions;
          if (archived.isEmpty) {
            return Center(child: Text(context.l10n.noArchivedEmotions));
          }
          return ListView(
            children: [
              for (final emotion in archived)
                ListTile(
                  leading: Text(state.lineageEmojis(emotion).join(' '), style: const TextStyle(fontSize: 20)),
                  title: Text(emotion.title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => context.read<EmotionBloc>().add(EmotionUnarchive(id: emotion.id)),
                        child: Text(context.l10n.restore),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context, emotion),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
