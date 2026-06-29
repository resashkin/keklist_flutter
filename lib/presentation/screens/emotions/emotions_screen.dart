import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/domain/services/entities/emotion_folder.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/emotions/emotion_archived_screen.dart';
import 'package:keklist/presentation/screens/emotions/emotion_editor_screen.dart';

/// Management screen for emotions and folders: create, edit, drag-to-reorder,
/// archive/delete. Archived emotions live behind the overflow menu.
final class EmotionsScreen extends StatelessWidget {
  const EmotionsScreen({super.key});

  Set<String> _referencedEmotionIds(BuildContext context) {
    final minds = context.read<MindRepository>().values;
    return minds.expand((mind) => mind.emotionIds).toSet();
  }

  void _openEmotionEditor(BuildContext context, {Emotion? emotion, String? folderId, required List<EmotionFolder> folders}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmotionEditorScreen(initial: emotion, folders: folders, initialFolderId: folderId),
      ),
    );
  }

  Future<void> _createFolder(BuildContext context) async {
    final title = await _promptForTitle(context, title: context.l10n.newFolder, hint: context.l10n.folderNameHint);
    if (title != null && title.trim().isNotEmpty && context.mounted) {
      context.read<EmotionBloc>().add(EmotionFolderCreate(title: title.trim()));
    }
  }

  Future<void> _editFolder(BuildContext context, EmotionFolder folder) async {
    final title = await _promptForTitle(
      context,
      title: context.l10n.editFolder,
      hint: context.l10n.folderNameHint,
      initial: folder.title,
    );
    if (title != null && title.trim().isNotEmpty && context.mounted) {
      context.read<EmotionBloc>().add(EmotionFolderUpdate(folder: folder.copyWith(title: title.trim())));
    }
  }

  Future<void> _deleteFolder(BuildContext context, EmotionFolder folder) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: folder.title,
      message: context.l10n.deleteFolderWithContentsMessage,
      okLabel: context.l10n.delete,
      isDestructiveAction: true,
    );
    if (result == OkCancelResult.ok && context.mounted) {
      context.read<EmotionBloc>().add(EmotionFolderDelete(id: folder.id));
    }
  }

  Future<void> _onEmotionAction(BuildContext context, Emotion emotion, bool isReferenced) async {
    if (isReferenced) {
      context.read<EmotionBloc>().add(EmotionArchive(id: emotion.id));
      return;
    }
    final result = await showOkCancelAlertDialog(
      context: context,
      title: emotion.title,
      message: context.l10n.deleteEmotionMessage,
      okLabel: context.l10n.delete,
      isDestructiveAction: true,
    );
    if (result == OkCancelResult.ok && context.mounted) {
      context.read<EmotionBloc>().add(EmotionDelete(id: emotion.id));
    }
  }

  Future<String?> _promptForTitle(BuildContext context, {required String title, required String hint, String? initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text), child: Text(context.l10n.save)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.emotions),
        actions: [
          BlocBuilder<EmotionBloc, EmotionState>(
            builder: (context, state) {
              final folders = state is EmotionsList ? state.folders : <EmotionFolder>[];
              return PopupMenuButton<String>(
                icon: const Icon(Icons.add),
                onSelected: (value) {
                  if (value == 'emotion') {
                    _openEmotionEditor(context, folders: folders);
                  } else {
                    _createFolder(context);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'emotion', child: Text(context.l10n.newEmotion)),
                  PopupMenuItem(value: 'folder', child: Text(context.l10n.newFolder)),
                ],
              );
            },
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
          final referenced = _referencedEmotionIds(context);
          final loose = state.looseEmotions;
          final folders = state.folders;

          if (loose.isEmpty && folders.isEmpty) {
            return Center(child: Text(context.l10n.noEmotionsYet));
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 32.0),
            children: [
              if (loose.isNotEmpty) _reorderableSection(context, loose, referenced),
              for (final folder in folders) ...[
                _folderHeader(context, folder),
                _reorderableSection(context, state.emotionsInFolder(folder.id), referenced),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _folderHeader(BuildContext context, EmotionFolder folder) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(folder.title, style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _editFolder(context, folder),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _deleteFolder(context, folder),
          ),
        ],
      ),
    );
  }

  Widget _reorderableSection(BuildContext context, List<Emotion> emotions, Set<String> referenced) {
    return ReorderableListView(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      onReorderItem: (oldIndex, newIndex) {
        final reordered = [...emotions];
        final moved = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, moved);
        context.read<EmotionBloc>().add(EmotionReorder(orderedEmotionIds: reordered.map((e) => e.id).toList()));
      },
      children: [
        for (final emotion in emotions)
          ListTile(
            key: ValueKey(emotion.id),
            leading: Text(emotion.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(emotion.title),
            onTap: () {
              final folders = (context.read<EmotionBloc>().state as EmotionsList).folders;
              _openEmotionEditor(context, emotion: emotion, folders: folders);
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  final folders = (context.read<EmotionBloc>().state as EmotionsList).folders;
                  _openEmotionEditor(context, emotion: emotion, folders: folders);
                } else {
                  _onEmotionAction(context, emotion, referenced.contains(emotion.id));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(context.l10n.edit)),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(referenced.contains(emotion.id) ? context.l10n.archive : context.l10n.delete),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
