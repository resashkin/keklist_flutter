import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/presentation/blocs/mind_creator_bloc/mind_creator_bloc.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

final class MindCreatorScreen extends StatefulWidget {
  final Function(String text, String emoji) onDone;
  final String buttonText;
  final Icon buttonIcon;
  final String? initialText;
  final String? initialEmoji;
  final String? hintText;
  final bool shouldSuggestEmoji;

  const MindCreatorScreen({
    super.key,
    required this.onDone,
    required this.buttonText,
    this.initialText,
    this.initialEmoji,
    required this.buttonIcon,
    this.hintText = 'Write something...',
    this.shouldSuggestEmoji = true,
  });

  @override
  State<MindCreatorScreen> createState() => _MindCreatorScreenState();
}

final class _MindCreatorScreenState extends KekWidgetState<MindCreatorScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  String _selectedEmoji = '🙂';

  late final MindCreatorBloc _bloc = MindCreatorBloc(mindRepository: context.read<MindRepository>());

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialEmoji != null) {
        setState(() {
          _selectedEmoji = widget.initialEmoji!;
        });
      }

      if (widget.initialText != null) {
        _textEditingController.text = widget.initialText!;
      }

      if (widget.shouldSuggestEmoji) {
        _textEditingController.addListener(() {
          _bloc.add(MindCreatorChangeText(text: _textEditingController.text));
        });
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _bloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _bloc,
      listener: (context, state) {
        if (state is MindCreatorState) {
          if (state.suggestions.isEmpty) {
            return;
          }
          setState(() {
            _selectedEmoji = state.suggestions.first;
          });
        }
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDone(_textEditingController.text, _selectedEmoji);
              },
              child: Text(
                widget.buttonText,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.blueAccent,
                ),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  _showEmojiPickerScreen(onSelect: (emoji) {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  });
                },
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 64.0),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                controller: _textEditingController,
                style: const TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12.0),
                  border: InputBorder.none,
                  hintText: widget.hintText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPickerScreen({required Function(String) onSelect}) async {
    await showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => MindPickerScreen(
        onSelect: onSelect,
        suggestions: _bloc.state.suggestions,
      ),
    );
  }
}
