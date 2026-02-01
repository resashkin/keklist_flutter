import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:collection/collection.dart';
import 'package:full_swipe_back_gesture/full_swipe_back_gesture.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_bloc.dart';
import 'package:keklist/domain/services/constants/onboarding_constants.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
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
import 'package:keklist/presentation/screens/settings/settings_screen.dart';
import 'package:keklist/presentation/screens/web_page/web_page_screen.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/screens/mind_picker/mind_picker_screen.dart';
import 'package:keklist/presentation/screens/mind_day_collection/mind_day_collection_screen.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:keklist/domain/period.dart';
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
  bool _isSettingsVisible = true;
  bool _isInsightsVisible = true;
  bool _isMonthView = false;
  final bool _isDemoMode = false;
  bool _hasShownOnboardingDialog = false;

  bool get _shouldShowTitles => _settingsDataState?.settings.shouldShowTitles ?? true;

  // NOTE: Состояние SearchBar.
  final TextEditingController _searchTextController = TextEditingController(text: null);
  bool get _isSearching => _searchingMindState != null && _searchingMindState!.enabled;
  List<Mind> get _searchResults => _isSearching ? _searchingMindState!.resultValues : [];

  // NOTE: Payments.
  // final PaymentService _payementService = PaymentService();

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
          case SettingsShowWhatsNew _:
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

            // Check if we should show onboarding deletion dialog
            if (!_hasShownOnboardingDialog) {
              final realMinds = state.values.where(
                (m) => !OnboardingConstants.isOnboardingMind(m.id, m.rootId),
              ).toList();

              final onboardingMinds = state.values.where(
                (m) => OnboardingConstants.isOnboardingMind(m.id, m.rootId),
              ).toList();

              if (realMinds.length == 1 && onboardingMinds.isNotEmpty) {
                _hasShownOnboardingDialog = true;
                _showDeleteOnboardingDialog();
              }
            }
          } else if (state is MindSearching) {
            setState(() => _searchingMindState = state);
          }
        },
      )?.disposed(by: this);

      // Lazy onboarding check
      subscribeToBloc<LazyOnboardingBloc>(
        onNewState: (state) {
          if (state is LazyOnboardingNeeded && state.shouldShow) {
            sendEventToBloc<LazyOnboardingBloc>(
              LazyOnboardingCreate(context: context),
            );
            sendEventToBloc<LazyOnboardingBloc>(LazyOnboardingMarkAsSeen());
          }
        },
      )?.disposed(by: this);
      sendEventToBloc<LazyOnboardingBloc>(LazyOnboardingCheck());

      // Auth removed - no authentication required

      subscribeToBloc<TabsContainerBloc>(onNewState: (state) {
        if (state is TabsContainerState) {
          setState(() {
            _isInsightsVisible = !state.selectedTabs.map((tab) => tab.type).contains(TabType.insights);
            _isSettingsVisible = !state.selectedTabs.map((tab) => tab.type).contains(TabType.settings);
          });
        }
      })?.disposed(by: this);

      // Auth removed - no authentication required
      sendEventToBloc<SettingsBloc>(SettingsGet());
      sendEventToBloc<MindBloc>(MindGetList());
      sendEventToBloc<TabsContainerBloc>(TabsContainerGetCurrentState());
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
              onSearch: () => sendEventToBloc<MindBloc>(MindStartSearch()),
              onTitle: () => _scrollToNow(),
              onCalendar: () => _showCalendarActions(),
              onSettings: _isSettingsVisible ? (() => _showSettings()) : null,
              onInsights: _isInsightsVisible ? (() => _showInsights()) : null,
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
        onTapToDay: (dayIndex) => _showDayCollectionScreen(groupDayIndex: dayIndex),
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

  void _showDayCollectionScreen({required int groupDayIndex}) {
    Navigator.of(context).push(
      BackSwipePageRoute(
        builder: (context) => MindDayCollectionScreen(initialDayIndex: groupDayIndex),
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

  int _getNowDayIndex() => DateUtils.getDayIndex(from: DateTime.now());

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

    final int dayIndex = DateUtils.getDayIndex(from: dates.first!);
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

    final int startDayIndex = DateUtils.getDayIndex(from: dates[0]!);
    final int endDayIndex = DateUtils.getDayIndex(from: dates[1]!);

    return (startDayIndex, endDayIndex);
  }

  void _showCalendarActions() {
    showBarModalBottomSheet(
      context: context,
      builder: (context) => ActionsScreen(
        actions: [
          (ActionModel.goToDate(context), () => _showDateSwitcher()),
          (ActionModel.showDigest(context), () => _showDigestPeriodOptions()),
        ],
      ),
    );
  }

  void _showDigestPeriodOptions() {
    showBarModalBottomSheet(
      context: context,
      builder: (context) => ActionsScreen(
        actions: [
          ...PeriodType.values.map((periodType) => (
                ActionModel.custom(
                  icon: _getPeriodIcon(periodType),
                  title: periodType.localizedTitle(context),
                ),
                () async {
                  final List<Mind> periodMinds = periodType.filterMinds(_minds.toList());
                  if (periodMinds.isNotEmpty) {
                    _showDigestForPeriod(periodType, periodMinds);
                  }
                }
              )),
          (
            ActionModel.custom(icon: const Icon(Icons.date_range), title: context.l10n.selectPeriod),
            () async => _showDigestForCustomPeriod()
          ),
        ],
      ),
    );
  }

  Icon _getPeriodIcon(PeriodType periodType) {
    switch (periodType) {
      case PeriodType.today:
        return const Icon(Icons.today);
      case PeriodType.yesterday:
        return const Icon(Icons.history);
      case PeriodType.thisWeek:
        return const Icon(Icons.view_week_rounded);
      case PeriodType.lastTwoWeeks:
        return const Icon(Icons.calendar_view_week);
      case PeriodType.thisMonth:
        return const Icon(Icons.calendar_view_month);
      case PeriodType.thisYear:
        return const Icon(Icons.calendar_today);
    }
  }

  void _showDigestForPeriod(PeriodType periodType, List<Mind> periodMinds) {
    if (mountedContext == null) {
      return;
    }

    Navigator.push(
      mountedContext!,
      BackSwipePageRoute(
        builder: (context) {
          return MindUniversalListScreen(
            allMinds: _minds,
            filterFunction: (mind) => periodType.filterMinds([mind]).isNotEmpty,
            title: '${periodType.localizedTitle(context)} (${periodMinds.length} ${context.l10n.minds})',
            emptyStateMessage: '${context.l10n.noMindsForPeriod} ${periodType.localizedTitle(context).toLowerCase()}',
            onSelectMind: (mind) => _showMindInfo(mind),
          );
        },
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
      BackSwipePageRoute(
        builder: (context) {
          bool filterFunction(mind) => mind.dayIndex >= startDayIndex && mind.dayIndex <= endDayIndex;
          return MindUniversalListScreen(
            allMinds: _minds,
            filterFunction: filterFunction,
            title: '${context.l10n.digest} (${_minds.where(filterFunction).length} ${context.l10n.minds})',
            emptyStateMessage: context.l10n.noMindsInSelectedPeriod,
            onSelectMind: (mind) => _showMindInfo(mind),
          );
        },
      ),
    );
  }

  // void _showUserProfile() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const UserProfileScreen(),
  //     ),
  //   );
  // }

  void _showSettings() {
    Navigator.push(
      context,
      BackSwipePageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showInsights() {
    Navigator.push(
      context,
      BackSwipePageRoute(
        builder: (context) => const InsightsScreen(),
      ),
    );
  }

  void _cancelSearch() {
    _searchTextController.clear();
    sendEventToBloc<MindBloc>(MindStopSearch());
    WidgetsBinding.instance.addPostFrameCallback((_) async => _jumpToNow());
  }

  void _showMindInfo(Mind mind) {
    Navigator.of(context).push(
      BackSwipePageRoute(
        builder: (_) => MindInfoScreen(
          rootMind: mind,
          allMinds: _minds,
        ),
      ),
    );
  }

  Future<void> _showDeleteOnboardingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteOnboardingMindsTitle),
        content: Text(context.l10n.deleteOnboardingMindsMessage),
        actions: [
          TextButton(
            child: Text(context.l10n.keepTutorial),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(context.l10n.deleteTutorial),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      sendEventToBloc<LazyOnboardingBloc>(LazyOnboardingDelete());
    }
  }
}
