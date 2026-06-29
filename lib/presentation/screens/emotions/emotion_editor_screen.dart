import 'package:flutter/material.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/domain/services/entities/emotion_folder.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Create or edit a single [Emotion]: emoji (required), title (required) and an
/// optional single folder. Dispatches to [EmotionBloc] and pops on save.
final class EmotionEditorScreen extends StatefulWidget {
  final Emotion? initial;
  final List<EmotionFolder> folders;
  final String? initialFolderId;

  const EmotionEditorScreen({
    super.key,
    this.initial,
    required this.folders,
    this.initialFolderId,
  });

  @override
  State<EmotionEditorScreen> createState() => _EmotionEditorScreenState();
}

class _EmotionEditorScreenState extends KekWidgetState<EmotionEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  late String _emoji = widget.initial?.emoji ?? '🙂';
  late String? _folderId = widget.initial?.folderIds.firstOrNull ?? widget.initialFolderId;

  bool get _isEditing => widget.initial != null;
  bool get _canSave => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initial?.title ?? '';
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    final String title = _titleController.text.trim();
    if (title.isEmpty) return;

    if (_isEditing) {
      sendEventToBloc<EmotionBloc>(
        EmotionUpdate(
          emotion: widget.initial!.copyWith(
            title: title,
            emoji: _emoji,
            folderIds: _folderId == null ? const [] : [_folderId!],
          ),
        ),
      );
    } else {
      sendEventToBloc<EmotionBloc>(EmotionCreate(title: title, emoji: _emoji, folderId: _folderId));
    }
    Navigator.of(context).pop();
  }

  void _pickEmoji() async {
    await showCupertinoModalBottomSheet(
      context: context,
      builder: (_) => MindPickerScreen(onSelect: (emoji) => setState(() => _emoji = emoji)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? context.l10n.editEmotion : context.l10n.newEmotion),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(context.l10n.save),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickEmoji,
                  child: Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Text(_emoji, style: const TextStyle(fontSize: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              TextField(
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.l10n.emotionNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String?>(
                initialValue: _folderId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(context.l10n.noFolderOption)),
                  ...widget.folders.map(
                    (folder) => DropdownMenuItem<String?>(value: folder.id, child: Text(folder.title)),
                  ),
                ],
                onChanged: (value) => setState(() => _folderId = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
