import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:full_swipe_back_gesture/full_swipe_back_gesture.dart';
import 'package:gap/gap.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
import 'package:keklist/presentation/blocs/mind_creator_bloc/mind_creator_bloc.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/mind_widget.dart';
import 'package:keklist/presentation/core/widgets/overscroll_listener.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/actions/action_model.dart';
import 'package:keklist/presentation/screens/actions/actions_screen.dart';
import 'package:keklist/presentation/screens/mind_creator/mind_creator_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/messaged_list/mind_monolog_list_widget.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/screens/mind_info/mind_info_screen.dart';
import 'package:keklist/presentation/screens/mind_one_emoji_collection/mind_one_emoji_collection.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:provider/provider.dart';

final class MindDayCollectionScreen extends StatefulWidget {
  final int initialDayIndex;

  const MindDayCollectionScreen({super.key, required this.initialDayIndex});

  @override
  // ignore: no_logic_in_create_state
  State<MindDayCollectionScreen> createState() => _MindDayCollectionScreenState(dayIndex: initialDayIndex);
}

final class _MindDayCollectionScreenState extends KekWidgetState<MindDayCollectionScreen> {
  int dayIndex;
  final List<Mind> allMinds = [];

  final ScrollController _scrollController = ScrollController();

  List<Mind> get _dayMinds => MindUtils.findMindsByDayIndex(dayIndex: dayIndex, allMinds: allMinds);

  Map<String, List<Mind>> get _mindIdsToChildren => MindUtils.convertToMindChildren(minds: allMinds);

  bool _isMindContentVisible = false;
  Mind? _editableMind;

  DebugMenuDataState? _debugMenuState;

  Iterable<String> suggestions = KeklistConstants.defaultEmojiesToPick;

  _MindDayCollectionScreenState({required this.dayIndex});

  @override
  void initState() {
    super.initState();

    subscribeToBloc<MindBloc>(
      onNewState: (state) async {
        if (state is MindList) {
          setState(() {
            allMinds
              ..clear()
              ..addAll(state.values.sortedBySortIndex());
          });
        }
      },
    )?.disposed(by: this);

    subscribeToBloc<SettingsBloc>(
      onNewState: (state) {
        if (state is SettingsDataState) {
          setState(() {
            _isMindContentVisible = state.settings.isMindContentVisible;
          });
        }
      },
    )?.disposed(by: this);

    subscribeToBloc<DebugMenuBloc>(
      onNewState: (state) {
        if (state is DebugMenuDataState) {
          _debugMenuState = state;
        }
      },
    )?.disposed(by: this);

    subscribeToBloc<MindCreatorBloc>(
      onNewState: (state) {
        setState(() => suggestions = state.suggestions.take(5));
      },
    )?.disposed(by: this);

    sendEventToBloc<MindBloc>(MindGetList());
    sendEventToBloc<SettingsBloc>(SettingsGet());
    sendEventToBloc<DebugMenuBloc>(DebugMenuGet());
    sendEventToBloc<MindCreatorBloc>(MindCreatorGetSuggestions(text: ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              // TODO: refactor it
              '${DateFormatters.dayMonthFormat(Localizations.localeOf(context)).format(DateUtils.getDateFromDayIndex(dayIndex))}${DateUtils.getDateFromDayIndex(dayIndex).year != DateTime.now().year ? ' ${DateUtils.getDateFromDayIndex(dayIndex).year}' : ''}',
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
            Text(
              DateFormatters.formatWeekday(DateUtils.getDateFromDayIndex(dayIndex), Localizations.localeOf(context)),
              style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final int? selectedDayIndex = await _showDateSwitcherToNewDay();
              if (selectedDayIndex == null) {
                return;
              }
              _switchToDayIndex(selectedDayIndex);
            },
          ),
          BoolWidget(
            condition:
                _debugMenuState?.debugMenuItems.firstWhereOrNull(
                  (element) => element.type == DebugMenuType.sensitiveContent && element.value,
                ) !=
                null,
            trueChild: IconButton(
              icon: BoolWidget(
                condition: _isMindContentVisible,
                trueChild: const Icon(Icons.visibility_off_outlined),
                falseChild: const Icon(Icons.visibility),
              ),
              onPressed: () => _changeContentVisibility(),
            ),
            falseChild: SizedBox.shrink(),
          ),
        ],
      ),
      body: OverscrollListener(
        onOverscrollTopPointerUp: () => _switchToDayIndexWithScrollToTop(dayIndex - 1),
        onOverscrollBottomPointerUp: () => _switchToDayIndexWithScrollToBottom(dayIndex + 1),
        onOverscrollTop: () => _vibrate(),
        onOverscrollBottom: () => _vibrate(),
        overscrollTargetOffset: 150.0,
        scrollBottomOffset: 150.0,
        childScrollController: _scrollController,
        topOverscrollChild: Column(
          children: [
            Text(
              DateFormatters.formatFullDate(
                DateUtils.getDateFromDayIndex(dayIndex - 1),
                Localizations.localeOf(context),
              ),
            ),
            const Icon(Icons.arrow_upward),
          ],
        ),
        bottomOverscrollChild: Column(
          children: [
            const Icon(Icons.arrow_downward),
            Text(
              DateFormatters.formatFullDate(
                DateUtils.getDateFromDayIndex(dayIndex + 1),
                Localizations.localeOf(context),
              ),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: FlutterConstants.mobileOverscrollPhysics,
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 150), // FAB offset.
          child: BoolWidget(
            condition: _dayMinds.isNotEmpty,
            trueChild: MindMonologListWidget(
              minds: _dayMinds,
              onTap: (Mind mind) => _showMindInfo(mind),
              onOptions: (Mind mind) => _showActions(context, mind),
              mindIdsToChildren: _mindIdsToChildren,
            ),
            falseChild: _MindZeroCase(
              suggestions: suggestions,
              onEmojiTap: (emoji) => _showMindCreator(initialEmoji: emoji),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SensitiveWidget(
        mode: SensitiveMode.blurredAndNonTappable,
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          onPressed: () => _showMindCreator(),
          label: Text(context.l10n.create, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500)),
          enableFeedback: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    cancelSubscriptions();

    super.dispose();
  }

  Future<void> _changeContentVisibility() async {
    HapticFeedback.mediumImpact();
    if (!_isMindContentVisible) {
      final LocalAuthentication auth = LocalAuthentication();
      try {
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
        if (canAuthenticate) {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: context.l10n.pleaseAuthenticateToShowContent,
            options: const AuthenticationOptions(useErrorDialogs: false),
          );
          if (didAuthenticate) {
            setState(() {
              sendEventToBloc<SettingsBloc>(const SettingsChangeMindContentVisibility(isVisible: true));
            });
          }
        }
      } on Exception {
        setState(() {
          sendEventToBloc<SettingsBloc>(const SettingsChangeMindContentVisibility(isVisible: true));
        });
      }
    } else {
      setState(() {
        sendEventToBloc<SettingsBloc>(const SettingsChangeMindContentVisibility(isVisible: false));
      });
    }
  }

  Future<int?> _showDateSwitcherToNewDay() async {
    final List<DateTime?>? dates = await showCalendarDatePicker2Dialog(
      context: context,
      value: [DateUtils.getDateFromDayIndex(this.dayIndex)],
      config: CalendarDatePicker2WithActionButtonsConfig(firstDayOfWeek: 1),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );

    final DateTime? selectedDateTime = dates?.firstOrNull;
    if (selectedDateTime == null) {
      return null;
    }

    final int dayIndex = DateUtils.getDayIndex(from: selectedDateTime);
    return dayIndex;
  }

  void _showMindInfo(Mind mind) {
    Navigator.of(context).push(
      BackSwipePageRoute(
        builder: (_) => MindInfoScreen(rootMind: mind, allMinds: allMinds),
      ),
    );
  }

  void _switchToDayIndex(int dayIndex) {
    _scrollController.jumpTo(0);
    setState(() {
      this.dayIndex = dayIndex;
    });
  }

  void _switchToDayIndexWithScrollToTop(int dayIndex) {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 500.0);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    setState(() {
      this.dayIndex = dayIndex;
    });
  }

  void _switchToDayIndexWithScrollToBottom(int dayIndex) {
    _scrollController.jumpTo(-500);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    setState(() {
      this.dayIndex = dayIndex;
    });
  }

  void _vibrate() {
    Haptics.vibrate(HapticsType.heavy);
  }

  // TODO: extract to some navigator

  void _showActions(BuildContext context, Mind mind) {
    showBarModalBottomSheet(
      context: context,
      builder: (context) => ActionsScreen(
        actions: [
          if (mind.rootId != null) (ActionModel.convertToStandalone(context), () => _convertToStandalone(mind)),
          (ActionModel.edit(context), () => _editMind(mind)),
          (ActionModel.switchDay(context), () => _updateMindDay(mind)),
          (ActionModel.showAll(context), () => _showAllMinds(mind)),
          (ActionModel.delete(context), () => _removeMind(mind)),
        ],
      ),
    );
  }

  void _convertToStandalone(Mind mind) {
    final Mind standaloneMind = mind.copyWith(rootId: null);
    sendEventToBloc<MindBloc>(MindEdit(mind: standaloneMind));
  }

  void _editMind(Mind mind) {
    _editableMind = mind;
    _showMindCreator(initialText: mind.note, initialEmoji: mind.emoji);
  }

  Future<void> _updateMindDay(Mind mind) async {
    final int? switchedDay = await _showDateSwitcherToNewDay();
    if (switchedDay != null) {
      final List<Mind> switchedDayMinds = MindUtils.findMindsByDayIndex(dayIndex: switchedDay, allMinds: allMinds);
      final int sortIndex = (switchedDayMinds.map((mind) => mind.sortIndex).maxOrNull ?? -1) + 1;
      final Mind newMind = mind.copyWith(dayIndex: switchedDay, sortIndex: sortIndex);
      sendEventToBloc<MindBloc>(MindEdit(mind: newMind));
    }
  }

  void _showAllMinds(Mind mind) {
    Navigator.of(context).push(
      BackSwipePageRoute(
        builder: (_) => MindOneEmojiCollectionScreen(emoji: mind.emoji, allMinds: allMinds),
      ),
    );
  }

  void _removeMind(Mind mind) {
    sendEventToBloc<MindBloc>(MindDelete(mind: mind));
  }

  void _showMindCreator({String? initialText, String? initialEmoji}) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (_) {
        return MindCreatorScreen(
          initialEmoji: initialEmoji,
          initialText: initialText,
          onDone: (String text, String emoji) {
            if (_editableMind == null) {
              final String normalizedText = text.trim();
              final MindNoteContent content = normalizedText.isEmpty
                  ? MindNoteContent.empty()
                  : MindNoteContent.parse(normalizedText);
              final MindCreate event = MindCreate(
                dayIndex: dayIndex,
                mindContent: content.pieces,
                emoji: emoji,
                rootId: null,
              );
              sendEventToBloc<MindBloc>(event);
            } else {
              final Mind mindForEdit = _editableMind!.copyWith(note: text, emoji: emoji);
              sendEventToBloc<MindBloc>(MindEdit(mind: mindForEdit));
              _editableMind = null;
            }
          },
        );
      },
    );
  }
}

final class _MindZeroCase extends StatelessWidget {
  final Iterable<String> suggestions;
  final ValueChanged<String> onEmojiTap;

  const _MindZeroCase({required this.suggestions, required this.onEmojiTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Gap(32.0),
        if (suggestions.isNotEmpty) const Text('Pick emoji to write a new note...'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.0,
          children: suggestions
              .map(
                (emoji) => GestureDetector(
                  child: MindWidget.justEmoji(emoji: emoji).animate().fadeIn(),
                  onTap: () => onEmojiTap(emoji),
                ),
              )
              .toList(),
        ),
        const Gap(32.0),
      ],
    );
  }
}
