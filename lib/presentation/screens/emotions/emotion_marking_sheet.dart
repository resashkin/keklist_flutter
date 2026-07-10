import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/emotions/emotions_screen.dart';
import 'package:keklist/presentation/screens/emotions/widgets/emotion_chip.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Bottom sheet for tagging a mind with emotions. Emotions form a tree; the sheet
/// shows one level at a time. Tap a chip to toggle the tag, long-press to drill
/// into its children. Calls [onSelectionChanged] on every toggle so the caller
/// can persist immediately.
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

  /// Navigation path of parent ids; `null` is the root level.
  final List<String?> _path = [null];

  String? get _currentParentId => _path.last;

  void _toggle(Emotion emotion) {
    setState(() {
      if (!_selected.add(emotion.id)) _selected.remove(emotion.id);
    });
    widget.onSelectionChanged({..._selected});
  }

  void _drillInto(Emotion emotion) => setState(() => _path.add(emotion.id));

  void _goBack() => setState(() => _path.removeLast());

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

            final children = state.childrenOf(_currentParentId);
            final parent = _currentParentId == null ? null : state.byId(_currentParentId!);
            final selectedEmotions = _selected.map((id) => state.byId(id)).whereType<Emotion>().toList();

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
                  if (parent == null)
                    Text(context.l10n.emotions, style: Theme.of(context).textTheme.titleLarge)
                  else
                    _BreadcrumbHeader(
                      title: '${state.lineageEmojis(parent).join(' ')}  ${parent.title}',
                      onBack: _goBack,
                    ),
                  const SizedBox(height: 8.0),
                  Text(
                    context.l10n.emotionPickHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 12.0),
                  if (children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text(context.l10n.noEmotionsYet)),
                    )
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        for (final emotion in children)
                          EmotionChip(
                            emojis: [emotion.emoji],
                            label: emotion.title,
                            selected: _selected.contains(emotion.id),
                            hasChildren: state.hasActiveChildren(emotion.id),
                            onTap: () => _toggle(emotion),
                            onLongPress:
                                state.hasActiveChildren(emotion.id) ? () => _drillInto(emotion) : null,
                          ),
                      ],
                    ),
                  if (selectedEmotions.isNotEmpty) ...[
                    const SizedBox(height: 20.0),
                    Text(context.l10n.selected, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        for (final emotion in selectedEmotions)
                          EmotionChip(
                            emojis: state.lineageEmojis(emotion),
                            label: emotion.title,
                            selected: true,
                            onTap: () => _toggle(emotion),
                          ),
                      ],
                    ),
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
}

class _BreadcrumbHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _BreadcrumbHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        const SizedBox(width: 8.0),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}
