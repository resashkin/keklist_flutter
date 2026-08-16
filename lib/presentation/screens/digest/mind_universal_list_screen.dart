import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart' hide DateUtils;
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
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/kek_floating_button.dart';
import 'package:keklist/presentation/screens/actions/action_model.dart';
import 'package:keklist/presentation/screens/actions/actions_screen.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_collection_empty_day_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/messaged_list/mind_message_widget.dart';
import 'package:keklist/presentation/screens/mind_info/mind_info_screen.dart';
import 'package:keklist/presentation/screens/mind_one_emoji_collection/mind_one_emoji_collection.dart';

enum MindUniversalListTitleType {
  text,
  date,
}

final class MindUniversalListScreen extends StatefulWidget {
  final String title;
  final String emptyStateMessage;
  final bool Function(Mind) filterFunction;
  final Iterable<Mind> allMinds;
  final Function? onSelectMind;
  final VoidCallback? onCreate;
  final IconData? createButtonIcon;
  final String? createButtonLabel;
  final MindUniversalListTitleType titleType;

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
    this.titleType = MindUniversalListTitleType.text,
  });

  @override
  State<MindUniversalListScreen> createState() => _MindUniversalListScreenState();
}

final class _MindUniversalListScreenState extends KekWidgetState<MindUniversalListScreen> {
  final List<Mind> _allMinds = [];
  final List<Mind> _filteredMinds = [];
  DebugMenuDataState? _debugMenuState;

  final ScrollController _scrollController = ScrollController();
  final Set<String> _knownMindIds = {};
  String? _pendingScrollMindId;
  final GlobalKey _pendingScrollItemKey = GlobalKey();

  bool get _isSingleDay => _filteredMinds.map((m) => m.dayIndex).toSet().length <= 1;

  bool get _showsDateTitle =>
      widget.titleType == MindUniversalListTitleType.date && _filteredMinds.isNotEmpty && _isSingleDay;

  Widget _appBarTitle(BuildContext context) {
    if (!_showsDateTitle) return Text(widget.title);

    final Locale locale = Localizations.localeOf(context);
    final DateTime dayDate = DateUtils.getDateFromDayIndex(_filteredMinds.first.dayIndex);
    final String formattedDay = DateFormatters.dayMonthFormat(locale).format(dayDate);
    final String yearSuffix = dayDate.year == DateTime.now().year ? '' : ' ${dayDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$formattedDay$yearSuffix', style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500)),
        Text(
          DateFormatters.formatWeekday(dayDate, locale),
          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    _allMinds.addAll(widget.allMinds);
    _recomputeFiltered();
    _knownMindIds.addAll(_filteredMinds.map((mind) => mind.id));

    subscribeToBloc<MindBloc>(
      onNewState: (state) async {
        if (state is MindList) {
          setState(() {
            _allMinds
              ..clear()
              ..addAll(state.values);
            _recomputeFiltered();
            _detectCreatedMind();
          });
          if (_pendingScrollMindId != null) {
            _scrollToPendingMind(attemptsLeft: 8);
          }
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // A mind whose id was never in the filtered list before is a freshly created
  // (or moved-in) one — MindBloc only emits a generic MindList, so an id diff
  // is the only way to tell creation apart from edit/delete.
  void _detectCreatedMind() {
    final List<Mind> newMinds = _filteredMinds.where((mind) => !_knownMindIds.contains(mind.id)).toList();
    final bool hadMinds = _knownMindIds.isNotEmpty;
    _knownMindIds
      ..clear()
      ..addAll(_filteredMinds.map((mind) => mind.id));
    if (!hadMinds || newMinds.isEmpty) return;
    _pendingScrollMindId = newMinds.last.id;
  }

  // Item extents are estimates until rows are built, so a single animateTo can
  // undershoot: step toward the target each frame until the pending row exists,
  // then let ensureVisible finish precisely. maxScrollExtent (not the row's own
  // bottom) is the target for the last row so it clears the floating button.
  void _scrollToPendingMind({required int attemptsLeft}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? mindId = _pendingScrollMindId;
      if (!mounted || mindId == null || !_scrollController.hasClients) {
        _pendingScrollMindId = null;
        return;
      }
      final int index = _filteredMinds.indexWhere((mind) => mind.id == mindId);
      if (index == -1 || attemptsLeft <= 0) {
        _pendingScrollMindId = null;
        return;
      }

      final bool isLast = index == _filteredMinds.length - 1;
      final BuildContext? itemContext = _pendingScrollItemKey.currentContext;
      if (!isLast && itemContext != null) {
        _pendingScrollMindId = null;
        Scrollable.ensureVisible(
          itemContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
        return;
      }

      final ScrollPosition position = _scrollController.position;
      final double target = isLast
          ? position.maxScrollExtent
          : (position.maxScrollExtent * (index + 1) / _filteredMinds.length).clamp(0.0, position.maxScrollExtent);
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      if (!mounted || !_scrollController.hasClients) return;
      if (isLast && _scrollController.offset >= _scrollController.position.maxScrollExtent) {
        _pendingScrollMindId = null;
        return;
      }
      _scrollToPendingMind(attemptsLeft: attemptsLeft - 1);
    });
  }

  void _recomputeFiltered() {
    _filteredMinds
      ..clear()
      ..addAll(
        _allMinds
            .where(widget.filterFunction)
            .where((element) => element.rootId == null)
            .toList()
          ..sort((a, b) {
            final int dayComparison = a.dayIndex.compareTo(b.dayIndex);
            if (dayComparison != 0) return dayComparison;
            return a.sortIndex.compareTo(b.sortIndex);
          }),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: _showsDateTitle, title: _appBarTitle(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.onCreate == null
          ? null
          : KekFloatingButton(
              onPressed: widget.onCreate,
              label: widget.createButtonLabel ?? '',
              fallbackIcon: widget.createButtonIcon ?? Icons.add,
              sfSymbol: 'plus',
            ),
      body: BoolWidget(
        condition: _filteredMinds.isNotEmpty,
        falseChild: Center(
          child: MindCollectionEmptyStateWidget.noMinds(context: context, text: widget.emptyStateMessage),
        ),
        trueChild: Scrollbar(
          controller: _scrollController,
          child: ListView.builder(
            controller: _scrollController,
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
                key: mind.id == _pendingScrollMindId ? _pendingScrollItemKey : null,
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
          (ActionModel.switchDay(context), () => _switchDay(mind)),
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

  void _switchDay(Mind mind) async {
    final int? switchedDay = await _showDateSwitcherToNewDay();
    if (switchedDay == null) return;

    final List<Mind> switchedDayMinds = MindUtils.findMindsByDayIndex(
      dayIndex: switchedDay,
      allMinds: _allMinds,
    );
    final int sortIndex = (switchedDayMinds.map((mind) => mind.sortIndex).maxOrNull ?? -1) + 1;
    final Mind movedMind = mind.copyWith(dayIndex: switchedDay, sortIndex: sortIndex);
    sendEventToBloc<MindBloc>(MindEdit(mind: movedMind));
  }

  Future<int?> _showDateSwitcherToNewDay() async {
    final List<DateTime?>? dates = await showCalendarDatePicker2Dialog(
      context: context,
      value: [DateUtils.getDateFromDayIndex(DateUtils.getTodayIndex())],
      config: CalendarDatePicker2WithActionButtonsConfig(firstDayOfWeek: 1),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );

    if (dates?.firstOrNull == null) return null;

    return DateUtils.getDayIndex(from: dates!.first!);
  }

  void _removeMind(Mind mind) {
    sendEventToBloc<MindBloc>(MindDelete(mind: mind));
  }
}
