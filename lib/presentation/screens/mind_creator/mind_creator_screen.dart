import 'dart:math';

import 'package:flutter/material.dart';
import 'package:keklist/presentation/blocs/mind_creator_bloc/mind_creator_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

final class MindCreatorScreen extends StatefulWidget {
  final Function(String text, String emoji) onDone;
  final String? initialText;
  final String? initialEmoji;
  final String? hintText;
  final bool shouldSuggestEmoji;

  const MindCreatorScreen({
    super.key,
    required this.onDone,
    this.initialText,
    this.initialEmoji,
    this.hintText,
    this.shouldSuggestEmoji = false,
  });

  @override
  State<MindCreatorScreen> createState() => _MindCreatorScreenState();
}

final class _MindCreatorScreenState extends KekWidgetState<MindCreatorScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  String _selectedEmoji = '🙂';

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
        subscribeToBloc<MindCreatorBloc>(
          onNewState: (state) {
            if (state.suggestions.isEmpty) {
              return;
            }
            setState(() {
              _selectedEmoji = state.suggestions.first;
            });
          },
        )?.disposed(by: this);
      }

      if (widget.shouldSuggestEmoji) {
        _textEditingController.addListener(() {
          sendEventToBloc<MindCreatorBloc>(MindCreatorGetSuggestions(text: _textEditingController.text));
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDone(_textEditingController.text, _selectedEmoji);
            },
            child: Text(context.l10n.save, style: const TextStyle(fontSize: 16.0, color: Colors.blueAccent)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                _showEmojiPickerScreen(
                  onSelect: (emoji) {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                );
              },
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Stroke effect - smooth circular outline
                    ..._buildStrokeEmojis(
                      _selectedEmoji,
                      strokeColor: Theme.of(context).colorScheme.onSurface,
                      strokeWidth: 4.0,
                    ),
                    // Main emoji
                    Text(_selectedEmoji, style: const TextStyle(fontSize: 64.0)),
                    // Edit icon
                    Positioned(
                      right: 18,
                      bottom: 18,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                        ),
                        child: Icon(Icons.edit, size: 12, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
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
                hintText: widget.hintText ?? context.l10n.writeSomething,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPickerScreen({required Function(String) onSelect}) async {
    await showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => MindPickerScreen(onSelect: onSelect, suggestions: []),
    );
  }

  List<Widget> _buildStrokeEmojis(String emoji, {required Color strokeColor, required double strokeWidth}) {
    const double fontSize = 64.0;
    final List<Widget> strokeEmojis = [];

    // 16 directional offsets in a circle for smooth stroke effect
    const int directions = 16;
    for (int i = 0; i < directions; i++) {
      final double angle = (i * 2 * pi) / directions;
      final double dx = strokeWidth * cos(angle);
      final double dy = strokeWidth * sin(angle);

      strokeEmojis.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(strokeColor, BlendMode.srcIn),
            child: Text(emoji, style: const TextStyle(fontSize: fontSize)),
          ),
        ),
      );
    }

    return strokeEmojis;
  }
}
