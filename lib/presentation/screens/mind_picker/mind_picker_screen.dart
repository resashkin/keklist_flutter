import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/presentation/blocs/mind_creator_bloc/mind_creator_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/mind_widget.dart';
import 'package:keklist/presentation/cubits/used_emoji/used_emoji_cubit.dart';
import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

final class MindPickerScreen extends StatefulWidget {
  final Iterable<String> suggestions;
  final Function(String) onSelect;

  const MindPickerScreen({super.key, required this.onSelect, this.suggestions = const []});

  @override
  MindPickerScreenState createState() => MindPickerScreenState();
}

final class MindPickerScreenState extends KekWidgetState<MindPickerScreen> {
  final List<Emoji> _emojies = Emoji.all();
  String _searchText = '';
  List<Emoji> _filteredMinds = [];
  Iterable<String> _suggestions = [];

  List<String> get _allEmojiCharacters {
    final List<String> suggestions = widget.suggestions.toList();
    return _suggestions.toList() + suggestions + _emojies.map((emoji) => emoji.char).toList();
  }

  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _textEditingController.addListener(() {
      setState(() {
        _searchText = _textEditingController.text;
        _filteredMinds = _emojies.where((mind) => mind.keywords.join().contains(_searchText)).toList();
      });
    });

    subscribeToBloc<MindCreatorBloc>(
      onNewState: (state) {
        setState(() => _suggestions = state.suggestions);
      },
    )?.disposed(by: this);
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          autofocus: true,
          controller: _textEditingController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(8),
            border: UnderlineInputBorder(),
            hintText: context.l10n.searchYourEmoji,
          ),
        ),
        Flexible(
          child: BlocBuilder<UsedEmojiCubit, UsedEmojiState>(
            builder: (context, frequencyState) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final widgetsInRowCount = (constraints.maxWidth / 80).ceil();

                  if (_searchText.isNotEmpty) {
                    // Split search results into frequent matches and the rest
                    final usedMatchItems = frequencyState.usedEmojis
                        .where((item) => _filteredMinds.any((e) => e.char == item.emoji))
                        .toList();
                    final usedChars = usedMatchItems.map((i) => i.emoji).toSet();
                    final otherMatchChars = _filteredMinds
                        .where((e) => !usedChars.contains(e.char))
                        .map((e) => e.char)
                        .toList();

                    return CustomScrollView(
                      slivers: [
                        if (usedMatchItems.isNotEmpty) ...[
                          SliverToBoxAdapter(child: _sectionHeader(context.l10n.emojiPickerUsedInMinds)),
                          SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: widgetsInRowCount,
                              childAspectRatio: 0.85,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = usedMatchItems[index];
                                return _FrequentEmojiCell(
                                  item: item,
                                  onTap: () => _pickEmoji(item.emoji),
                                );
                              },
                              childCount: usedMatchItems.length,
                            ),
                          ),
                        ],
                        if (otherMatchChars.isNotEmpty) ...[
                          if (usedMatchItems.isNotEmpty)
                            SliverToBoxAdapter(child: const Divider(height: 1)),
                          SliverToBoxAdapter(child: _sectionHeader(context.l10n.emojiPickerAll)),
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: widgetsInRowCount),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final emoji = otherMatchChars[index];
                                  return MindWidget(item: emoji, onTap: () => _pickEmoji(emoji), isHighlighted: true);
                                },
                                childCount: otherMatchChars.length,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }

                  // Normal mode: Frequent + All
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _sectionHeader(context.l10n.emojiPickerUsedInMinds)),
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widgetsInRowCount,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = frequencyState.usedEmojis[index];
                            return _FrequentEmojiCell(
                              item: item,
                              onTap: () => _pickEmoji(item.emoji),
                            );
                          },
                          childCount: frequencyState.usedEmojis.length,
                        ),
                      ),
                      SliverToBoxAdapter(child: const Divider(height: 1)),
                      SliverToBoxAdapter(child: _sectionHeader(context.l10n.emojiPickerAll)),
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: widgetsInRowCount),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final emoji = _allEmojiCharacters[index];
                              return MindWidget(item: emoji, onTap: () => _pickEmoji(emoji), isHighlighted: true);
                            },
                            childCount: _allEmojiCharacters.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      );

  void _pickEmoji(String emoji) {
    Navigator.of(context).pop();
    widget.onSelect(emoji);
  }
}

class _FrequentEmojiCell extends StatelessWidget {
  final UsedEmojiItem item;
  final VoidCallback onTap;

  const _FrequentEmojiCell({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 38)),
          if (item.count > 0)
            Text(
              '${item.count}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
