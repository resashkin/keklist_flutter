import 'package:material_ui/material_ui.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/kek_bottom_sheet.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Small nested bottom sheet to create or rename a single [Emotion] (emoji +
/// title). Dispatches to [EmotionBloc] and pops on save. Replaces the old
/// full-screen editor so all emotion management lives around the marking sheet.
final class EmotionEditorSheet extends StatefulWidget {
  final Emotion? initial;

  /// Parent for a newly created emotion (`null` → top level). Ignored when editing.
  final String? parentId;

  const EmotionEditorSheet({super.key, this.initial, this.parentId});

  static Future<void> show({
    required BuildContext context,
    Emotion? initial,
    String? parentId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EmotionEditorSheet(initial: initial, parentId: parentId),
      ),
    );
  }

  @override
  State<EmotionEditorSheet> createState() => _EmotionEditorSheetState();
}

class _EmotionEditorSheetState extends KekWidgetState<EmotionEditorSheet> {
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
      sendEventToBloc<EmotionBloc>(EmotionUpdate(emotion: widget.initial!.copyWith(title: title, emoji: _emoji)));
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
    return Container(
      decoration: KekBottomSheetStyle.decoration(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KekBottomSheetStyle.handle(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                _isEditing ? context.l10n.editEmotion : context.l10n.newEmotion,
                style: KekBottomSheetStyle.titleStyle(context),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickEmoji,
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _save(),
                      decoration: InputDecoration(
                        labelText: context.l10n.emotionNameHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(context.l10n.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
