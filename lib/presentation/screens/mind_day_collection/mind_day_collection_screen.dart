import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:gap/gap.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
import 'package:keklist/presentation/blocs/mind_creator_bloc/mind_creator_bloc.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/mind_widget.dart';
import 'package:keklist/presentation/core/widgets/overscroll_listener.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/mind_creator/mind_creator_screen.dart';
import 'package:keklist/presentation/screens/date_gallery/date_gallery_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/day_minds_card/day_minds_card.dart';
import 'package:keklist/presentation/screens/digest/mind_universal_list_screen.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/screens/mind_info/mind_info_screen.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/kek_floating_button.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/domain/repositories/weather/weather_repository.dart';
import 'package:keklist/presentation/cubits/weather/weather_cubit.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/day_media_tile/day_media_preview_cubit.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/day_media_tile/day_media_tile_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/day_media_tile/day_folder_media_preview_cubit.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/day_media_tile/day_folder_media_tile_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/media_folder_settings_bottom_sheet/media_folder_settings_bottom_sheet.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/photo_video_settings_bottom_sheet/photo_video_settings_bottom_sheet.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/sources_bottom_sheet/sources_bottom_sheet.dart';
import 'package:keklist/domain/services/weather/weather_api_service.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/weather_settings_bottom_sheet/weather_settings_bottom_sheet.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/weather_tile/weather_day_tile_widget.dart';
import 'package:keklist/presentation/screens/date_gallery/folder_gallery_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/presentation/blocs/membership_bloc/membership_bloc.dart';
import 'package:keklist/presentation/screens/paywall/paywall_bottom_sheet.dart';

final class MindDayCollectionScreen extends StatefulWidget {
  final int initialDayIndex;

  /// Extra bottom offset for the floating "To now" button so it clears an
  /// overlaying tab bar. Pass the tab bar height when hosted inside the tab
  /// container; leave 0 for standalone (pushed) usage with no tab bar.
  final double fabBottomOffset;

  const MindDayCollectionScreen({super.key, required this.initialDayIndex, this.fabBottomOffset = 0.0});

  @override
  // ignore: no_logic_in_create_state
  State<MindDayCollectionScreen> createState() => MindDayCollectionScreenState(dayIndex: initialDayIndex);
}

final class MindDayCollectionScreenState extends KekWidgetState<MindDayCollectionScreen> {
  int dayIndex;
  final List<Mind> allMinds = [];

  final ScrollController _scrollController = ScrollController();

  List<Mind> get _dayMinds => MindUtils.findMindsByDayIndex(dayIndex: dayIndex, allMinds: allMinds);

  bool _isMindContentVisible = false;
  bool _isPhotoVideoSourceEnabled = false;
  bool _isWeatherSourceEnabled = false;
  double? _weatherLatitude;
  double? _weatherLongitude;
  bool _isMediaFolderSourceEnabled = false;
  String? _mediaFolderPath;
  bool _isMediaFolderRecursive = false;
  final DayMediaPreviewCubit _mediaPreviewCubit = DayMediaPreviewCubit();
  final DayFolderMediaPreviewCubit _folderMediaPreviewCubit = DayFolderMediaPreviewCubit();
  WeatherCubit? _weatherCubit;
  bool _pendingWeatherEnable = false;

  DebugMenuDataState? _debugMenuState;

  Iterable<String> suggestions = KeklistConstants.defaultEmojiesToPick;

  MindDayCollectionScreenState({required this.dayIndex});

  @override
  void initState() {
    super.initState();

    _weatherCubit = WeatherCubit(
      repository: context.read<WeatherRepository>(),
      apiService: WeatherApiService(),
    );

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
          final bool photoEnabled = state.settings.isPhotoVideoSourceEnabled;
          setState(() {
            _isMindContentVisible = state.settings.isMindContentVisible;
          });
          if (photoEnabled != _isPhotoVideoSourceEnabled) {
            setState(() => _isPhotoVideoSourceEnabled = photoEnabled);
            if (photoEnabled && !Platform.isAndroid) _mediaPreviewCubit.load(dayIndex);
          }
          final bool weatherEnabled = state.settings.isWeatherSourceEnabled;
          final double? lat = state.settings.weatherLatitude;
          final double? lon = state.settings.weatherLongitude;
          if (weatherEnabled != _isWeatherSourceEnabled || lat != _weatherLatitude || lon != _weatherLongitude) {
            setState(() {
              _isWeatherSourceEnabled = weatherEnabled;
              _weatherLatitude = lat;
              _weatherLongitude = lon;
            });
            if (weatherEnabled && lat != null && lon != null) {
              _weatherCubit?.loadForDay(dayIndex: dayIndex, latitude: lat, longitude: lon);
            }
          }
          final bool folderEnabled = state.settings.isMediaFolderSourceEnabled;
          final String? folderPath = state.settings.mediaFolderPath;
          final bool folderRecursive = state.settings.isMediaFolderRecursive;
          if (folderEnabled != _isMediaFolderSourceEnabled ||
              folderPath != _mediaFolderPath ||
              folderRecursive != _isMediaFolderRecursive) {
            setState(() {
              _isMediaFolderSourceEnabled = folderEnabled;
              _mediaFolderPath = folderPath;
              _isMediaFolderRecursive = folderRecursive;
            });
            if (folderEnabled && folderPath != null) {
              _folderMediaPreviewCubit.load(dayIndex, folderPath, recursive: folderRecursive);
            }
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

    subscribeToBloc<MindCreatorBloc>(
      onNewState: (state) {
        setState(() => suggestions = state.suggestions.take(5));
      },
    )?.disposed(by: this);

    subscribeToBloc<MembershipBloc>(
      onNewState: (state) {
        if (state is MembershipDataState && state.isPro && _pendingWeatherEnable) {
          _pendingWeatherEnable = false;
          sendEventToBloc<SettingsBloc>(const SettingsToggleWeatherSource(isEnabled: true));
        }
      },
    )?.disposed(by: this);

    sendEventToBloc<MindBloc>(MindGetList());
    sendEventToBloc<SettingsBloc>(SettingsGet());
    sendEventToBloc<DebugMenuBloc>(DebugMenuGet());
    sendEventToBloc<MindCreatorBloc>(MindCreatorGetSuggestions(text: ''));
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final DateTime dayDate = DateUtils.getDateFromDayIndex(dayIndex);
    final String formattedDay = DateFormatters.dayMonthFormat(locale).format(dayDate);
    final String yearSuffix = dayDate.year == DateTime.now().year ? '' : ' ${dayDate.year}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () async {
            final int? selectedDayIndex = await _showDateSwitcherToNewDay();
            if (selectedDayIndex == null) return;
            _switchToDayIndex(selectedDayIndex);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('$formattedDay$yearSuffix', style: const TextStyle(fontSize: 16.0, fontWeight: .w500)),
              Text(
                DateFormatters.formatWeekday(dayDate, locale),
                style: const TextStyle(fontSize: 14.0, fontWeight: .w300),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), tooltip: context.l10n.sources, onPressed: () => _showSources()),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: dayIndex == DateUtils.getTodayIndex()
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: widget.fabBottomOffset),
              child: KekFloatingButton(
                onPressed: () => goToToday(),
                label: 'To now',
                fallbackIcon: dayIndex < DateUtils.getTodayIndex() ? Icons.arrow_downward : Icons.arrow_upward,
                sfSymbol: dayIndex < DateUtils.getTodayIndex() ? 'arrow.down' : 'arrow.up',
              ),
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: FlutterConstants.mobileOverscrollPhysics,
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                    child: DayMindsCard(
                      minds: _dayMinds,
                      onTap: () => _showMindsList(),
                    ),
                  ),
                  if (_isPhotoVideoSourceEnabled && !Platform.isAndroid)
                    BlocBuilder<DayMediaPreviewCubit, DayMediaPreviewState>(
                      bloc: _mediaPreviewCubit,
                      builder: (context, state) {
                        if (state is DayMediaPreviewData) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: DayMediaTileWidget(data: state, onTap: () => _openGallery()),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  if (_isMediaFolderSourceEnabled && _mediaFolderPath != null && Platform.isAndroid)
                    BlocBuilder<DayFolderMediaPreviewCubit, DayFolderMediaPreviewState>(
                      bloc: _folderMediaPreviewCubit,
                      builder: (context, state) {
                        if (state is DayFolderMediaPreviewLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: DayFolderMediaSkeletonTile(),
                          );
                        }
                        if (state is DayFolderMediaPreviewData) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: DayFolderMediaTileWidget(
                              data: state,
                              onTap: () => _openFolderGallery(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  if (_isWeatherSourceEnabled &&
                      _weatherLatitude != null &&
                      _weatherLongitude != null &&
                      _weatherCubit != null)
                    BlocBuilder<WeatherCubit, WeatherState>(
                      bloc: _weatherCubit,
                      builder: (context, state) {
                        if (state is WeatherLoaded) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: WeatherDayTileWidget(data: state.data),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    cancelSubscriptions();
    _mediaPreviewCubit.close();
    _folderMediaPreviewCubit.close();
    _weatherCubit?.close();
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
          if (!mounted) return;
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: context.l10n.pleaseAuthenticateToShowContent,
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
      SwipeablePageRoute(
        builder: (_) => MindInfoScreen(rootMind: mind, allMinds: allMinds),
      ),
    );
  }

  void _openGallery() {
    Navigator.of(context).push(SwipeablePageRoute(builder: (_) => DateGalleryScreen(dayIndex: dayIndex)));
  }

  void _openFolderGallery() {
    final String? path = _mediaFolderPath;
    if (path == null) return;
    Navigator.of(context).push(
      SwipeablePageRoute(
        builder: (_) => FolderGalleryScreen(
          dayIndex: dayIndex,
          folderPath: path,
          recursive: _isMediaFolderRecursive,
          onSettings: () => _showMediaFolderSettings(),
        ),
      ),
    );
  }

  void _showMindsList() {
    final Locale locale = Localizations.localeOf(context);
    final DateTime dayDate = DateUtils.getDateFromDayIndex(dayIndex);
    final String title = DateFormatters.formatFullDate(dayDate, locale);
    final int capturedDayIndex = dayIndex;
    Navigator.of(context).push(
      SwipeablePageRoute(
        builder: (_) => MindUniversalListScreen(
          allMinds: allMinds,
          filterFunction: (mind) => mind.dayIndex == capturedDayIndex,
          title: title,
          emptyStateMessage: context.l10n.noMindsForThisDay,
          onSelectMind: (mind) => _showMindInfo(mind),
          onCreate: () => _showMindCreator(),
          createButtonIcon: Icons.add,
          createButtonLabel: context.l10n.create,
        ),
      ),
    );
  }

  void _showSources() {
    showBarModalBottomSheet(
      context: context,
      builder: (_) => SourcesBottomSheet(
        isPhotoVideoEnabled: _isPhotoVideoSourceEnabled,
        onPhotoVideoToggled: (enabled) {
          sendEventToBloc<SettingsBloc>(SettingsTogglePhotoVideoSource(isEnabled: enabled));
        },
        onPhotoVideoSettings: null,
        isWeatherEnabled: _isWeatherSourceEnabled,
        onWeatherToggled: _onWeatherToggled,
        onWeatherSettings: () => _showWeatherSettings(),
        isMediaFolderEnabled: _isMediaFolderSourceEnabled,
        onMediaFolderToggled: (enabled) {
          sendEventToBloc<SettingsBloc>(SettingsUpdateMediaFolderSource(isEnabled: enabled));
        },
        onMediaFolderSettings: () => _showMediaFolderSettings(),
      ),
    );
  }

  void _showPhotoVideoSettings() {
    showBarModalBottomSheet(
      context: context,
      builder: (_) => const PhotoVideoSettingsBottomSheet(),
    );
  }

  void _showMediaFolderSettings() {
    showBarModalBottomSheet(
      context: context,
      builder: (_) => MediaFolderSettingsBottomSheet(
        initialFolderPath: _mediaFolderPath,
        isRecursive: _isMediaFolderRecursive,
        onFolderPicked: (path) {
          sendEventToBloc<SettingsBloc>(SettingsUpdateMediaFolderSource(folderPath: path));
        },
        onRecursiveChanged: (value) {
          sendEventToBloc<SettingsBloc>(SettingsUpdateMediaFolderSource(isRecursive: value));
        },
      ),
    );
  }

  Future<void> _onWeatherToggled(bool enabled) async {
    if (!enabled) {
      sendEventToBloc<SettingsBloc>(const SettingsToggleWeatherSource(isEnabled: false));
      return;
    }
    final membershipState = context.read<MembershipBloc>().state;
    final bool isPro = membershipState is MembershipDataState && membershipState.isPro;
    if (isPro) {
      sendEventToBloc<SettingsBloc>(const SettingsToggleWeatherSource(isEnabled: true));
    } else {
      _pendingWeatherEnable = true;
      final purchased = await PaywallBottomSheet.show(context);
      if (purchased) sendEventToBloc<MembershipBloc>(const MembershipRefreshEvent());
    }
  }

  void _showWeatherSettings() {
    showBarModalBottomSheet(
      context: context,
      builder: (_) => WeatherSettingsBottomSheet(
        initialLatitude: _weatherLatitude,
        initialLongitude: _weatherLongitude,
        weatherApiService: WeatherApiService(),
        onSave: (lat, lon) {
          sendEventToBloc<SettingsBloc>(SettingsUpdateWeatherLocation(latitude: lat, longitude: lon));
        },
      ),
    );
  }

  void goToToday() => _switchToDayIndex(DateUtils.getTodayIndex());

  void _switchToDayIndex(int dayIndex) {
    _scrollController.jumpTo(0);
    setState(() {
      this.dayIndex = dayIndex;
    });
    if (_isPhotoVideoSourceEnabled && !Platform.isAndroid) _mediaPreviewCubit.load(dayIndex);
    _reloadFolderMedia(dayIndex);
    _reloadWeather(dayIndex);
  }

  void _switchToDayIndexWithScrollToTop(int dayIndex) {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 500.0);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    setState(() {
      this.dayIndex = dayIndex;
    });
    if (_isPhotoVideoSourceEnabled && !Platform.isAndroid) _mediaPreviewCubit.load(dayIndex);
    _reloadFolderMedia(dayIndex);
    _reloadWeather(dayIndex);
  }

  void _switchToDayIndexWithScrollToBottom(int dayIndex) {
    _scrollController.jumpTo(-500);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    setState(() {
      this.dayIndex = dayIndex;
    });
    if (_isPhotoVideoSourceEnabled && !Platform.isAndroid) _mediaPreviewCubit.load(dayIndex);
    _reloadFolderMedia(dayIndex);
    _reloadWeather(dayIndex);
  }

  void _reloadFolderMedia(int dayIndex) {
    if (_isMediaFolderSourceEnabled && _mediaFolderPath != null) {
      _folderMediaPreviewCubit.load(dayIndex, _mediaFolderPath!, recursive: _isMediaFolderRecursive);
    }
  }

  void _reloadWeather(int dayIndex) {
    if (_isWeatherSourceEnabled && _weatherLatitude != null && _weatherLongitude != null) {
      _weatherCubit?.loadForDay(dayIndex: dayIndex, latitude: _weatherLatitude!, longitude: _weatherLongitude!);
    }
  }

  void _vibrate() {
    Haptics.vibrate(HapticsType.heavy);
  }

  void _showMindCreator({String? initialText, String? initialEmoji}) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (_) {
        return MindCreatorScreen(
          initialEmoji: initialEmoji,
          initialText: initialText,
          onDone: (String text, String emoji) {
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
          },
        );
      },
    );
  }
}


final class _MindInteractiveZeroCase extends StatelessWidget {
  final String title;
  final Iterable<String> suggestions;
  final ValueChanged<String> onEmojiTap;

  const _MindInteractiveZeroCase({required this.suggestions, required this.onEmojiTap, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Gap(32.0),
        if (suggestions.isNotEmpty) Text(title),
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
