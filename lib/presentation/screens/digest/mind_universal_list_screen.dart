import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:translator/translator.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/screens/actions/action_model.dart';
import 'package:keklist/presentation/screens/actions/actions_screen.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_collection_empty_day_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/messaged_list/mind_message_widget.dart';
import 'package:keklist/presentation/screens/mind_info/mind_info_screen.dart';
import 'package:keklist/presentation/screens/mind_one_emoji_collection/mind_one_emoji_collection.dart';

final class MindUniversalListScreen extends StatefulWidget {
  final String title;
  final String emptyStateMessage;
  final bool Function(Mind) filterFunction;
  final Iterable<Mind> allMinds;
  final Function? onSelectMind;
  final VoidCallback? onCreate;
  final IconData? createButtonIcon;
  final String? createButtonLabel;

  const MindUniversalListScreen({
    super.key,
    required this.allMinds,
    required this.filterFunction,
    this.title = "Minds",
    this.emptyStateMessage = "No minds",
    this.onSelectMind,
    this.onCreate,
    this.createButtonIcon,
    this.createButtonLabel,
  });

  @override
  State<MindUniversalListScreen> createState() => _MindUniversalListScreenState();
}

final class _MindUniversalListScreenState extends KekWidgetState<MindUniversalListScreen> {
  final List<Mind> _allMinds = [];
  final List<Mind> _filteredMinds = [];
  DebugMenuDataState? _debugMenuState;

  bool get _isSingleDay => _filteredMinds.map((m) => m.dayIndex).toSet().length <= 1;

  @override
  void initState() {
    super.initState();

    _allMinds.addAll(widget.allMinds);
    _recomputeFiltered();

    subscribeToBloc<MindBloc>(
      onNewState: (state) async {
        if (state is MindList) {
          setState(() {
            _allMinds
              ..clear()
              ..addAll(state.values);
            _recomputeFiltered();
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
    sendEventToBloc<DebugMenuBloc>(DebugMenuGet());
  }

  void _recomputeFiltered() {
    _filteredMinds
      ..clear()
      ..addAll(
        _allMinds
            .where(widget.filterFunction)
            .where((element) => element.rootId == null)
            .sortedByProperty((mind) => mind.dayIndex),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.onCreate == null
          ? null
          : FloatingActionButton.extended(
              onPressed: widget.onCreate,
              icon: Icon(widget.createButtonIcon ?? Icons.add),
              label: Text(
                widget.createButtonLabel ?? '',
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
              ),
              enableFeedback: true,
            ),
      body: BoolWidget(
        condition: _filteredMinds.isNotEmpty,
        falseChild: Center(
          child: MindCollectionEmptyStateWidget.noMinds(context: context, text: widget.emptyStateMessage),
        ),
        trueChild: Scrollbar(
          child: ListView.builder(
            // Clear the floating "Write" button so the last mind can scroll above it.
            padding: EdgeInsets.only(bottom: widget.onCreate == null ? 0.0 : 96.0 + MediaQuery.paddingOf(context).bottom),
            itemBuilder: (context, index) {
              final bool shouldShowTitle = !_isSingleDay &&
                  (index == 0 || _filteredMinds[index].dayIndex != _filteredMinds[index - 1].dayIndex);
              final String title = DateFormatters.formatFullDate(
                DateUtils.getDateFromDayIndex(_filteredMinds[index].dayIndex),
                Localizations.localeOf(context),
              );
              final Mind mind = _filteredMinds[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    BoolWidget(
                      condition: shouldShowTitle,
                      trueChild: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(title, style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                      ),
                      falseChild: const SizedBox.shrink(),
                    ),
                    GestureDetector(
                      onTap: () => widget.onSelectMind?.call(mind),
                      child: MindMessageWidget(
                        mind: mind,
                        children: widget.allMinds.where((element) => element.rootId == mind.id).toList(growable: false),
                        onRootOptions: (Mind mind) => _showActions(mind: mind),
                        onChildOptions: null,
                      ),
                    ),
                  ],
                ),
              );
            },
            itemCount: _filteredMinds.length,
          ),
        ),
      ),
    );
  }

  void _showActions({required Mind mind}) {
    showBarModalBottomSheet(
      context: context,
      builder: (context) => ActionsScreen(
        actions: [
          if (_debugMenuState?.debugMenuItems.firstWhereOrNull(
                (element) => element.type == DebugMenuType.translation && element.value,
              ) !=
              null)
            (ActionModel.tranlsateToEnglish(context), () => _translateToEnglish(mind: mind)),
          (ActionModel.edit(context), () => _editMind(mind)),
          (ActionModel.showAll(context), () => _showAllMinds(mind)),
          (ActionModel.delete(context), () => _removeMind(mind)),
        ],
      ),
    );
  }

  void _translateToEnglish({required Mind mind}) async {
    final GoogleTranslator translator = GoogleTranslator();
    final Translation translation = await translator.translate(mind.plainNote, to: 'en');

    if (!mounted) return;
    await showOkAlertDialog(context: context, message: translation.text);
  }

  void _editMind(Mind mind) {
    Navigator.of(context).push(
      SwipeablePageRoute(
        builder: (_) => MindInfoScreen(rootMind: mind, allMinds: _allMinds),
      ),
    );
  }

  void _showAllMinds(Mind mind) {
    Navigator.of(context).push(
      SwipeablePageRoute(
        builder: (_) => MindOneEmojiCollectionScreen(emoji: mind.emoji, allMinds: _allMinds),
      ),
    );
  }

  void _removeMind(Mind mind) {
    sendEventToBloc<MindBloc>(MindDelete(mind: mind));
  }
}
