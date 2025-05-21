import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/core/helpers/extensions/state_extensions.dart';
import 'package:keklist/presentation/core/helpers/platform_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/screens/actions/action_model.dart';
import 'package:keklist/presentation/screens/actions/actions_screen.dart';
import 'package:keklist/presentation/screens/digest/mind_universal_list_screen.dart';
import 'package:keklist/presentation/screens/insights/insights_screen.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_collection_empty_day_widget.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_month_collection_widget.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_row_widget.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_search_result_widget.dart';
import 'package:keklist/presentation/screens/mind_info/mind_info_screen.dart';
import 'package:keklist/presentation/screens/user_profile/user_profile_screen.dart';
import 'package:keklist/presentation/screens/web_page/web_page_screen.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';
import 'package:keklist/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:keklist/presentation/screens/mind_day_collection/mind_day_collection_screen.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
part 'local_widgets/search_app_bar/search_app_bar.dart';
part 'local_widgets/app_bar/mind_collection_app_bar.dart';
part 'local_widgets/body/mind_collection_body.dart';

final class MindCollectionScreen extends StatefulWidget {
  const MindCollectionScreen({super.key});

  @override
  State<MindCollectionScreen> createState() => _MindCollectionScreenState();
}

final class _MindCollectionScreenState extends KekWidgetState<MindCollectionScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  final ScrollController _monthGridScrollController = ScrollController();
  late final GridObserverController _monthGridObserverController = GridObserverController(
    controller: _monthGridScrollController,
  );

  Iterable<Mind> _minds = [];
  Map<int, Iterable<Mind>> _mindsByDayIndex = {};
  SettingsDataState? _settingsDataState;
  MindSearching? _searchingMindState;

  bool _isMonthView = false;
  final bool _isDemoMode = false;

  bool get _isOfflineMode => _settingsDataState?.settings.isOfflineMode ?? false;
  bool get _shouldShowTitles => _settingsDataState?.settings.shouldShowTitles ?? true;

  // NOTE: Состояние SearchBar.
  final TextEditingController _searchTextController = TextEditingController(text: null);
  bool get _isSearching => _searchingMindState != null && _searchingMindState!.enabled;
  List<Mind> get _searchResults => _isSearching ? _searchingMindState!.resultValues : [];

  // NOTE: Payments.
  // final PaymentService _payementService = PaymentService();

  // NOTE: Состояние обновления с сервером.
  bool _isUpdating = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToNow();

      // NOTE: Слежение за полем ввода поиска при изменении его значения.
      _searchTextController.addListener(() {
        sendEventToBloc<MindBloc>(
          MindEnterSearchText(text: _searchTextController.text),
        );
      });

      subscribeToBloc<SettingsBloc>(onNewState: (state) {
        switch (state) {
          case SettingsDataState settingsDataState:
            _settingsDataState = settingsDataState;
            if (settingsDataState.settings.isOfflineMode) {
              setState(() => _isUpdating = false);
            }
            sendEventToBloc<AuthBloc>(AuthGetStatus());
          case SettingsNeedToShowWhatsNew _:
            _showWhatsNew();
            sendEventToBloc<SettingsBloc>(SettingsWhatsNewShown());
        }
      })?.disposed(by: this);

      subscribeToBloc<MindBloc>(
        onNewState: (state) async {
          if (state is MindList) {
            setState(() {
              _minds = state.values;
              _mindsByDayIndex =
                  state.values.where((element) => element.rootId == null).groupListsBy((element) => element.dayIndex);
            });
            if (DeviceUtils.safeGetPlatform() == SupportedPlatform.iOS) {
              sendEventToBloc<MindBloc>(MindUpdateMobileWidgets());
            }
          } else if (state is MindServerOperationStarted) {
            if (state.type == MindOperationType.fetch) {
              setState(() => _isUpdating = true);
            }
          } else if (state is MindOperationCompleted) {
            if (state.type == MindOperationType.fetch) {
              setState(() => _isUpdating = false);
            }
          } else if (state is MindOperationError) {
            if (ModalRoute.of(context)?.isCurrent ?? false) {
              _showDayCollectionAndHandleError(state: state);
            }

            if (state.notCompleted == MindOperationType.fetch) {
              setState(() => _isUpdating = false);
            }

            // TODO: сделать единый центр обработки блокирующих событий UI-ных
            // Показ ошибки.
            if (MindOperationType.values
                .where(
                  (element) => element != MindOperationType.uploadCachedData && element != MindOperationType.fetch,
                )
                .contains(state.notCompleted)) {
              showOkAlertDialog(
                context: context,
                title: 'Error',
                message: state.localizedString,
              );
            }
          } else if (state is MindSearching) {
            setState(() => _searchingMindState = state);
          }
        },
      )?.disposed(by: this);

      subscribeToBloc<AuthBloc>(onNewState: (state) {
        switch (state) {
          case AuthCurrentState _:
            sendEventToBloc<MindBloc>(MindGetList());
        }
      })?.disposed(by: this);

      sendEventToBloc<AuthBloc>(AuthGetStatus());
      sendEventToBloc<SettingsBloc>(SettingsGet());
      sendEventToBloc<MindBloc>(MindGetList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BoolWidget(
          condition: !_isDemoMode,
          falseChild: const SizedBox.shrink(),
          trueChild: BoolWidget(
            condition: _isSearching,
            trueChild: _SearchAppBar(
              searchTextController: _searchTextController,
              onSearchAddEmotion: () => _showMindPickerScreen(onSelect: (emoji) {
                _searchTextController.text += emoji;
              }),
              onSearchCancel: () => _cancelSearch(),
            ),
            falseChild: _MindCollectionAppBar(
              isOfflineMode: _isOfflineMode,
              isUpdating: _isUpdating,
              onSearch: () => sendEventToBloc<MindBloc>(MindStartSearch()),
              onTitle: () => _scrollToNow(),
              onCalendar: () => _showCalendarActions(),
              // onUserProfile: () => _showUserProfile(),
              // onInsights: () => _showInsights(),
              onOfflineMode: () => print('heheh'),
              onCalendarLongTap: () => setState(() => _isMonthView = !_isMonthView),
            ),
          ),
        ),
      ),
      body: _MindCollectionBody(
        mindsByDayIndex: _mindsByDayIndex,
        isSearching: _isSearching,
        searchResults: _searchResults,
        hideKeyboard: _hideKeyboard,
        onTapToDay: (dayIndex) => _showDayCollectionScreen(
          groupDayIndex: dayIndex,
          initialError: null,
        ),
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        getNowDayIndex: _getNowDayIndex,
        shouldShowTitles: _shouldShowTitles,
        isMonthView: _isMonthView,
        monthGridScrollController: _monthGridScrollController,
        monthGridObserverController: _monthGridObserverController,
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  Future<void> _showWhatsNew() {
    return showCupertinoModalBottomSheet(
      context: context,
      builder: (builder) {
        return WebPageScreen(
          title: 'Whats new?',
          initialUri: Uri.parse(KeklistConstants.whatsNewURL),
        );
      },
    );
  }

  void _showDayCollectionScreen({
    required int groupDayIndex,
    required MindOperationError? initialError,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MindDayCollectionScreen(
          allMinds: _minds,
          initialDayIndex: groupDayIndex,
          initialError: initialError,
        ),
      ),
    );
  }

  void _showMindPickerScreen({required Function(String) onSelect}) async {
    await showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => MindPickerScreen(onSelect: onSelect),
    );
  }

  void _jumpToNow() {
    if (_isDemoMode) {
      return;
    }

    if (_itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: _getNowDayIndex());
    }
    _monthGridObserverController.jumpTo(index: _getNowDayIndex());
  }

  Future<void> _scrollToNow() => _scrollToDayIndex(_getNowDayIndex());

  Future<void> _scrollToDayIndex(int dayIndex) async {
    if (_isMonthView) {
      await _monthGridObserverController.animateTo(
        index: _getNowDayIndex(),
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    } else {
      await _itemScrollController.scrollTo(
        index: dayIndex,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  void _hideKeyboard() => FocusScope.of(context).requestFocus(FocusNode());

  int _getNowDayIndex() => MindUtils.getDayIndex(from: DateTime.now());

  // void _enableDemoMode() {
  //   if (_isDemoMode) {
  //     return;
  //   }

  //   setState(() => _isDemoMode = true);
  // }

  // void _disableDemoMode() {
  //   if (!_isDemoMode) {
  //     return;
  //   }

  //   setState(() => _isDemoMode = false);
  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     _jumpToNow();
  //   });
  // }

  Future<void> _showDateSwitcher() async {
    final List<DateTime?>? dates = await showCalendarDatePicker2Dialog(
      context: context,
      value: [],
      config: CalendarDatePicker2WithActionButtonsConfig(firstDayOfWeek: 1),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );

    if (dates == null || dates.isEmpty) {
      return;
    }

    final int dayIndex = MindUtils.getDayIndex(from: dates.first!);
    _scrollToDayIndex(dayIndex);
  }

  Future<(int startDateIndex, int endDateIndex)?> _showPeriodPicker() async {
    final List<DateTime?>? dates = await showCalendarDatePicker2Dialog(
      context: context,
      value: [],
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDayOfWeek: 1,
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    );

    if (dates == null || dates.length < 2) {
      return null;
    }

    final int startDayIndex = MindUtils.getDayIndex(from: dates[0]!);
    final int endDayIndex = MindUtils.getDayIndex(from: dates[1]!);

    return (startDayIndex, endDayIndex);
  }

  void _showCalendarActions() {
    showBarModalBottomSheet(
      context: context,
      builder: (context) => ActionsScreen(
        actions: [
          (ActionModel.goToDate(), () => _showDateSwitcher()),
          (ActionModel.showDigest(), () => _showDigestPeriodOptions()),
        ],
      ),
    );
  }

  // TODO: move to DateUtils

  DateTime _getLastDayOfWeek(DateTime date) {
    int currentWeekday = date.weekday;
    int daysToLastDay = DateTime.sunday - currentWeekday;
    return date.add(Duration(days: daysToLastDay));
  }

  void _showDigestPeriodOptions() {
    final DateTime now = DateTime.now();
    showBarModalBottomSheet(
      context: context,
      builder: (context) => ActionsScreen(
        actions: [
          (
            ActionModel.custom(icon: const Icon(Icons.view_week_rounded), title: 'This week'),
            () async {
              final DateTime thisWeekStartDate = now.subtract(Duration(days: now.weekday - 1));
              final DateTime endThisWeekDate = _getLastDayOfWeek(thisWeekStartDate);
              _showDigest(
                startDayIndex: MindUtils.getDayIndex(from: thisWeekStartDate),
                endDayIndex: MindUtils.getDayIndex(from: endThisWeekDate),
              );
            }
          ),
          (
            ActionModel.custom(icon: const Icon(Icons.view_week_rounded), title: 'Previous week'),
            () async {
              final DateTime lastWeekStartDate =
                  now.subtract(const Duration(days: 7)).subtract(Duration(days: now.weekday - 1));
              final DateTime endLastWeekDate = _getLastDayOfWeek(lastWeekStartDate);
              _showDigest(
                startDayIndex: MindUtils.getDayIndex(from: lastWeekStartDate),
                endDayIndex: MindUtils.getDayIndex(from: endLastWeekDate),
              );
            }
          ),
          (
            ActionModel.custom(icon: const Icon(Icons.calendar_view_week), title: 'Last 2 weeks'),
            () async {
              final DateTime twoWeeksAgoStartDate =
                  now.subtract(const Duration(days: 14)).subtract(Duration(days: now.weekday - 1));
              final DateTime thisWeekEndDate = _getLastDayOfWeek(now);
              _showDigest(
                startDayIndex: MindUtils.getDayIndex(from: twoWeeksAgoStartDate),
                endDayIndex: MindUtils.getDayIndex(from: thisWeekEndDate),
              );
            }
          ),
          (
            ActionModel.custom(icon: const Icon(Icons.date_range), title: 'Select period ...'),
            () async => _showDigestForCustomPeriod()
          ),
        ],
      ),
    );
  }

  void _showDigestForCustomPeriod() async {
    final (int startDayIndex, int endDayIndex)? period = await _showPeriodPicker();
    if (period == null) {
      return;
    }
    _showDigest(startDayIndex: period.$1, endDayIndex: period.$2);
  }

  void _showDigest({
    required int startDayIndex,
    required int endDayIndex,
  }) async {
    if (mountedContext == null) {
      return;
    }

    Navigator.push(
      mountedContext!,
      MaterialPageRoute(
        builder: (context) {
          bool filterFunction(mind) => mind.dayIndex >= startDayIndex && mind.dayIndex <= endDayIndex;
          return MindUniversalListScreen(
            allMinds: _minds,
            filterFunction: filterFunction,
            title: 'Digest (${_minds.where(filterFunction).length} minds)',
            emptyStateMessage: 'No minds in selected period',
            onSelectMind: (mind) => _showMindInfo(mind),
          );
        },
      ),
    );
  }

  void _showUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserProfileScreen(),
      ),
    );
  }

  void _showInsights() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InsightsScreen(),
      ),
    );
  }

  void _cancelSearch() {
    _searchTextController.clear();
    sendEventToBloc<MindBloc>(MindStopSearch());
    WidgetsBinding.instance.addPostFrameCallback((_) async => _jumpToNow());
  }

  void _showDayCollectionAndHandleError({required MindOperationError state}) {
    if ([
      MindOperationType.create,
      MindOperationType.edit,
    ].contains(state.notCompleted)) {
      if (state.minds.isEmpty) {
        return;
      }
      _showDayCollectionScreen(
        groupDayIndex: state.minds.first.dayIndex,
        initialError: state,
      );
    }
  }

  void _showMindInfo(Mind mind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MindInfoScreen(
          rootMind: mind,
          allMinds: _minds,
        ),
      ),
    );
  }
}
