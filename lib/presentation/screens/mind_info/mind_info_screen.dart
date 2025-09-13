import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
import 'package:keklist/presentation/core/helpers/extensions/state_extensions.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/overscroll_listener.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/screens/actions/action_model.dart';
import 'package:keklist/presentation/screens/actions/actions_screen.dart';
import 'package:keklist/presentation/screens/mind_chat_discussion/mind_chat_discussion_screen.dart';
import 'package:keklist/presentation/screens/mind_one_emoji_collection/mind_one_emoji_collection.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/messaged_list/mind_message_widget.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/widgets/creator_bottom_bar/mind_creator_bottom_bar.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:translator/translator.dart';

final class MindInfoScreen extends StatefulWidget {
  final Mind rootMind;
  final Iterable<Mind> allMinds;

  const MindInfoScreen({
    super.key,
    required this.rootMind,
    required this.allMinds,
  });

  @override
  State<MindInfoScreen> createState() => _MindInfoScreenState();
}

final class _MindInfoScreenState extends KekWidgetState<MindInfoScreen> {
  final TextEditingController _createMindEditingController = TextEditingController(text: null);
  final FocusNode _mindCreatorFocusNode = FocusNode();
  DebugMenuDataState? _debugMenuState;
  bool _creatorPanelHasFocus = false;
  Mind? _editableMind;
  late String _selectedEmoji = _rootMind.emoji;

  Mind get _rootMind => widget.allMinds.firstWhere(
        (element) => element.id == widget.rootMind.id,
        orElse: () => widget.rootMind,
      );
  late final List<Mind> _allMinds = widget.allMinds.toList();

  List<Mind> get _rootMindChildren => MindUtils.findMindsByRootId(rootId: _rootMind.id, allMinds: widget.allMinds)
      .sortedByProperty((mind) => mind.creationDate);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _mindCreatorFocusNode.addListener(() {
        if (_creatorPanelHasFocus == _mindCreatorFocusNode.hasFocus) {
          return;
        }
        setState(() {
          _creatorPanelHasFocus = _mindCreatorFocusNode.hasFocus;
        });
      });
    });

    subscribeToBloc<MindBloc>(onNewState: (state) async {
      if (state is MindList) {
        setState(() {
          _allMinds
            ..clear()
            ..addAll(state.values.sortedByCreationDate());
        });
      }
    })?.disposed(by: this);

    subscribeToBloc<DebugMenuBloc>(onNewState: (state) {
      if (state is DebugMenuDataState) {
        _debugMenuState = state;
      }
    })?.disposed(by: this);
    sendEventToBloc<DebugMenuBloc>(DebugMenuGet());
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind'),
        actions: [
          SensitiveWidget(
            mode: SensitiveMode.blurredAndNonTappable,
            child: IconButton(
              onPressed: () => _showActions(mind: _rootMind),
              icon: const Icon(Icons.more_vert),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          OverscrollListener(
            overscrollTargetOffset: 150.0,
            onOverscrollTop: () => Haptics.vibrate(HapticsType.heavy),
            onOverscrollTopPointerUp: () => _mindCreatorFocusNode.requestFocus(),
            childScrollController: _scrollController,
            topOverscrollChild: const Row(
              children: [
                Icon(Icons.arrow_upward),
                SizedBox(width: 8.0),
                Icon(Icons.keyboard_alt_outlined),
              ],
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: FlutterConstants.mobileOverscrollPhysics,
              padding: const EdgeInsets.only(bottom: 150.0),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MindMessageWidget(
                        mind: _rootMind,
                        children: _rootMindChildren,
                        onRootOptions: null,
                        onChildOptions: (Mind mind) => _showActions(mind: mind),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Stack(
            children: [
              // NOTE: Подложка для скрытия текста эмодзи.
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  height: 60,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MindCreatorBottomBar(
                    editableMind: _editableMind,
                    focusNode: _mindCreatorFocusNode,
                    textEditingController: _createMindEditingController,
                    placeholder: 'Comment mind...',
                    onDone: (CreateMindData data) {
                      if (_editableMind == null) {
                        sendEventToBloc<MindBloc>(
                          MindCreate(
                            dayIndex: _rootMind.dayIndex,
                            note: data.text,
                            emoji: _selectedEmoji,
                            rootId: _rootMind.id,
                          ),
                        );
                      } else {
                        final Mind mindForEdit = _editableMind!.copyWith(
                          note: data.text,
                          emoji: _selectedEmoji,
                        );
                        sendEventToBloc<MindBloc>(MindEdit(mind: mindForEdit));
                      }
                      _resetMindCreator();
                    },
                    suggestionMinds: const [],
                    selectedEmoji: _selectedEmoji,
                    onTapSuggestionEmoji: (_) {},
                    onTapEmoji: () {
                      _showEmojiPickerScreen(
                        onSelect: (String emoji) {
                          setState(() => _selectedEmoji = emoji);
                        },
                      );
                    },
                    doneTitle: 'DONE',
                    onTapCancelEdit: () {
                      _resetMindCreator();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resetMindCreator() {
    setState(() {
      _editableMind = null;
      _createMindEditingController.text = '';
      _hideKeyboard();
    });
  }

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _showEmojiPickerScreen({required Function(String) onSelect}) async {
    await showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => MindPickerScreen(onSelect: onSelect),
    );
  }

  void _showActions({required Mind mind}) {
    showBarModalBottomSheet(
      context: context,
      builder: (context) => ActionsScreen(
        actions: [
          if (_debugMenuState?.debugMenuItems
                  .firstWhereOrNull((element) => element.type == DebugMenuType.chatWithAI && element.value) !=
              null)
            (ActionModel.chatWithAI(), () => _showMessageScreen(mind: mind)),
          if (_debugMenuState?.debugMenuItems
                  .firstWhereOrNull((element) => element.type == DebugMenuType.translation && element.value) !=
              null)
            (ActionModel.tranlsateToEnglish(), () => _translateToEnglish(mind: mind)),
          (ActionModel.edit(), () => _editMind(mind)),
          (ActionModel.showAll(), () => _showAllMinds(mind)),
          (ActionModel.delete(), () => _removeMind(mind)),
        ],
      ),
    );
  }

  void _translateToEnglish({required Mind mind}) async {
    final GoogleTranslator translator = GoogleTranslator();
    final Translation translation = await translator.translate(mind.note, to: 'en');

    await showOkAlertDialog(
      context: context,
      message: translation.text,
    );
  }

  void _showMessageScreen({required Mind mind}) async {
    Navigator.of(mountedContext!).push(
      MaterialPageRoute(
        builder: (_) => MindChatDiscussionScreen(
          rootMind: mind,
          allMinds: _allMinds,
        ),
      ),
    );
  }

  void _editMind(Mind mind) {
    setState(() {
      _editableMind = mind;
      _selectedEmoji = mind.emoji;
    });
    _createMindEditingController.text = mind.note;
    _mindCreatorFocusNode.requestFocus();
  }

  void _showAllMinds(Mind mind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MindOneEmojiCollectionScreen(
          emoji: mind.emoji,
          allMinds: _allMinds,
        ),
      ),
    );
  }

  void _removeMind(Mind mind) {
    sendEventToBloc<MindBloc>(MindDelete(mind: mind));
  }
}
