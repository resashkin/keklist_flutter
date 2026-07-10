import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/emotions/emotion_archived_screen.dart';
import 'package:keklist/presentation/screens/emotions/emotion_editor_screen.dart';

/// Management screen for the emotion tree: add root/child emotions, edit,
/// archive/delete (cascading), and drag-reorder siblings. Parents expand inline
/// to reveal their children.
final class EmotionsScreen extends StatefulWidget {
  const EmotionsScreen({super.key});

  @override
  State<EmotionsScreen> createState() => _EmotionsScreenState();
}

class _EmotionsScreenState extends State<EmotionsScreen> {
  final Set<String> _expanded = {};

  void _openEditor({Emotion? emotion, String? parentId, String? parentLabel}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmotionEditorScreen(initial: emotion, parentId: parentId, parentLabel: parentLabel),
      ),
    );
  }

  Future<void> _archive(BuildContext context, Emotion emotion, bool hasChildren) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: emotion.title,
      message: hasChildren ? context.l10n.archiveEmotionSubtreeMessage : context.l10n.archiveEmotionMessage,
      okLabel: context.l10n.archive,
    );
    if (result == OkCancelResult.ok && context.mounted) {
      context.read<EmotionBloc>().add(EmotionArchive(id: emotion.id));
    }
  }

  Future<void> _delete(BuildContext context, Emotion emotion, bool hasChildren) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: emotion.title,
      message: hasChildren ? context.l10n.deleteEmotionSubtreeMessage : context.l10n.deleteEmotionMessage,
      okLabel: context.l10n.delete,
      isDestructiveAction: true,
    );
    if (result == OkCancelResult.ok && context.mounted) {
      context.read<EmotionBloc>().add(EmotionDelete(id: emotion.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.emotions),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.l10n.newEmotion,
            onPressed: () => _openEditor(parentId: null),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmotionArchivedScreen()),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'archived', child: Text(context.l10n.archived)),
            ],
          ),
        ],
      ),
      body: BlocBuilder<EmotionBloc, EmotionState>(
        builder: (context, state) {
          if (state is! EmotionsList) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.rootEmotions.isEmpty) {
            return Center(child: Text(context.l10n.noEmotionsYet));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32.0),
            children: _buildLevel(context, state, null, 0),
          );
        },
      ),
    );
  }

  /// Recursively builds the rows for one sibling group and any expanded subtrees.
  /// The sibling group is wrapped in a non-scrolling [ReorderableListView] so
  /// each level can be drag-reordered independently.
  List<Widget> _buildLevel(BuildContext context, EmotionsList state, String? parentId, int depth) {
    final siblings = state.childrenOf(parentId);
    if (siblings.isEmpty) return const [];

    return [
      ReorderableListView(
        key: ValueKey('level_${parentId ?? 'root'}'),
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (oldIndex, newIndex) {
          final reordered = [...siblings];
          final moved = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, moved);
          context.read<EmotionBloc>().add(EmotionReorder(orderedEmotionIds: reordered.map((e) => e.id).toList()));
        },
        children: [
          for (int i = 0; i < siblings.length; i++)
            _buildNode(context, state, siblings[i], depth, i),
        ],
      ),
    ];
  }

  Widget _buildNode(BuildContext context, EmotionsList state, Emotion emotion, int depth, int index) {
    final bool hasChildren = state.hasActiveChildren(emotion.id);
    final bool isExpanded = _expanded.contains(emotion.id);

    return Column(
      key: ValueKey(emotion.id),
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 20.0, right: 8.0),
          leading: SizedBox(
            width: 60,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChildren)
                  Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 4),
                Text(emotion.emoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
          ),
          title: Text(emotion.title),
          onTap: hasChildren
              ? () => setState(() => isExpanded ? _expanded.remove(emotion.id) : _expanded.add(emotion.id))
              : () => _openEditor(emotion: emotion),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'child':
                      _openEditor(parentId: emotion.id, parentLabel: emotion.title);
                    case 'edit':
                      _openEditor(emotion: emotion);
                    case 'archive':
                      _archive(context, emotion, hasChildren);
                    case 'delete':
                      _delete(context, emotion, hasChildren);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'child', child: Text(context.l10n.addSubEmotion)),
                  PopupMenuItem(value: 'edit', child: Text(context.l10n.edit)),
                  PopupMenuItem(value: 'archive', child: Text(context.l10n.archive)),
                  PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
                ],
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
        ),
        if (hasChildren && isExpanded) ..._buildLevel(context, state, emotion.id, depth + 1),
      ],
    );
  }
}
