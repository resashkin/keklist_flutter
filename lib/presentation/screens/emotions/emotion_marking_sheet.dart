import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/emotions/emotions_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Bottom sheet for tagging a mind with emotions. Presents loose emotions and
/// folder sections in a single scroll, multi-select. Calls [onSelectionChanged]
/// on every toggle so the caller can persist immediately (action menu) or hold
/// the selection locally (mind editor).
final class EmotionMarkingSheet extends StatefulWidget {
  final Set<String> initialSelectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  const EmotionMarkingSheet({
    super.key,
    required this.initialSelectedIds,
    required this.onSelectionChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required Set<String> initialSelectedIds,
    required ValueChanged<Set<String>> onSelectionChanged,
  }) {
    return showCupertinoModalBottomSheet(
      context: context,
      builder: (_) => EmotionMarkingSheet(
        initialSelectedIds: initialSelectedIds,
        onSelectionChanged: onSelectionChanged,
      ),
    );
  }

  @override
  State<EmotionMarkingSheet> createState() => _EmotionMarkingSheetState();
}

class _EmotionMarkingSheetState extends State<EmotionMarkingSheet> {
  late final Set<String> _selected = {...widget.initialSelectedIds};

  void _toggle(Emotion emotion) {
    setState(() {
      if (_selected.contains(emotion.id)) {
        _selected.remove(emotion.id);
      } else {
        _selected.add(emotion.id);
      }
    });
    widget.onSelectionChanged({..._selected});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: BlocBuilder<EmotionBloc, EmotionState>(
          builder: (context, state) {
            if (state is! EmotionsList) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final loose = state.looseEmotions;
            final folders = state.folders;
            // Selected emotions that are archived won't appear in any section —
            // surface them so the user can still untag them.
            final archivedSelected = state.archivedEmotions.where((e) => _selected.contains(e.id)).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(context.l10n.emotions, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12.0),
                  if (loose.isEmpty && folders.isEmpty && archivedSelected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text(context.l10n.noEmotionsYet)),
                    ),
                  if (loose.isNotEmpty) _chipsWrap(loose),
                  for (final folder in folders)
                    if (state.emotionsInFolder(folder.id).isNotEmpty) ...[
                      const SizedBox(height: 16.0),
                      Text(folder.title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8.0),
                      _chipsWrap(state.emotionsInFolder(folder.id)),
                    ],
                  if (archivedSelected.isNotEmpty) ...[
                    const SizedBox(height: 16.0),
                    Text(context.l10n.archived, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8.0),
                    _chipsWrap(archivedSelected),
                  ],
                  const SizedBox(height: 20.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmotionsScreen()),
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: Text(context.l10n.setupEmotions),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chipsWrap(List<Emotion> emotions) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: emotions
          .map(
            (emotion) => FilterChip(
              showCheckmark: false,
              avatar: Text(emotion.emoji, style: const TextStyle(fontSize: 18)),
              label: Text(emotion.title),
              selected: _selected.contains(emotion.id),
              onSelected: (_) => _toggle(emotion),
            ),
          )
          .toList(),
    );
  }
}
