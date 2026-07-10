import 'package:flutter/material.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Create or edit a single [Emotion]: emoji (required) and title (required).
/// The tree position is fixed by [parentId] at creation (set by where the user
/// tapped "add"); editing keeps the emotion's existing parent.
final class EmotionEditorScreen extends StatefulWidget {
  final Emotion? initial;

  /// Parent for a newly created emotion (`null` → top level). Ignored when editing.
  final String? parentId;

  /// Human label of the parent, shown as context when creating a child.
  final String? parentLabel;

  const EmotionEditorScreen({
    super.key,
    this.initial,
    this.parentId,
    this.parentLabel,
  });

  @override
  State<EmotionEditorScreen> createState() => _EmotionEditorScreenState();
}

class _EmotionEditorScreenState extends KekWidgetState<EmotionEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  late String _emoji = widget.initial?.emoji ?? '🙂';

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
        EmotionUpdate(emotion: widget.initial!.copyWith(title: title, emoji: _emoji)),
      );
    } else {
      sendEventToBloc<EmotionBloc>(EmotionCreate(title: title, emoji: _emoji, parentId: widget.parentId));
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
              if (!_isEditing && widget.parentLabel != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    '${context.l10n.parentLabel}: ${widget.parentLabel}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
