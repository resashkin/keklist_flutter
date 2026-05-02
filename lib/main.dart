// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:keklist/domain/repositories/tabs/tabs_settings_repository.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/object/mind_object.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_hive_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_hive_repository.dart';
import 'package:keklist/domain/repositories/weather/object/weather_cache_object.dart';
import 'package:keklist/domain/repositories/weather/weather_repository.dart';
import 'package:keklist/domain/migrations/migration_runner.dart';
import 'package:keklist/domain/services/export_import/export_import_service.dart';
import 'package:keklist/keklist_app.dart';
import 'package:keklist/domain/hive_constants.dart';
import 'package:keklist/domain/repositories/settings/object/settings_object.dart';
import 'package:keklist/domain/repositories/debug_menu/object/debug_menu_object.dart';
import 'package:keklist/presentation/blocs/audio_player_bloc/audio_player_bloc.dart';
import 'package:keklist/presentation/blocs/mind_creator_bloc/mind_creator_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/user_profile_bloc/user_profile_bloc.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
import 'package:keklist/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_bloc.dart';
import 'package:keklist/presentation/blocs/membership_bloc/membership_bloc.dart';
import 'package:keklist/presentation/screens/preparation/preparation_screen.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/cubits/emoji_frequency/emoji_frequency_cubit.dart';
import 'package:keklist/presentation/cubits/mind_searcher/mind_searcher_cubit.dart';
import 'package:keklist/di/containers.dart';

import 'presentation/native/ios/watch/watch_communication_manager.dart';

// TODO: fix or exclude home_widget for android only

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initNativeWidgets();
  _setupBlockingLoadingWidget();
  runApp(const _AppRoot());
}

// ---------------------------------------------------------------------------
// Root widget — shows PreparationScreen while initializing, then the main app
// ---------------------------------------------------------------------------

final class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

final class _AppRootState extends State<_AppRoot> {
  final _stepNotifier = ValueNotifier<String>('');
  Widget? _app;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _stepNotifier.value = 'Loading...';
    await dotenv.load(fileName: 'dotenv');
    usePathUrlStrategy();

    _stepNotifier.value = 'Opening database...';
    final cipher = _buildHiveCipher();
    await _migrateToEncryptedIfNeeded(cipher);
    await _initHive(cipher);

    _stepNotifier.value = 'Finishing up...';
    final streamingPrefs = await StreamingSharedPreferences.instance;
    final injector = MainContainer(
      streamingSharedPreferences: streamingPrefs,
    ).initialize(Injector());

    _connectToWatchCommunicationManager(injector);
    _enableDebugBLOCLogs();

    final String revenueCatApiKey = () {
      if (kDebugMode) {
        return dotenv.env['REVENUE_CAT_TEST_API_KEY']!;
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.iOS:
            return dotenv.env['REVENUE_CAT_PROD_API_IOS_KEY']!;
          case TargetPlatform.android:
            return dotenv.env['REVENUE_CAT_PROD_API_ANDROID_KEY']!;
          default:
            return dotenv.env['REVENUE_CAT_TEST_API_KEY']!;
        }
      }
    }();
    await Purchases.configure(PurchasesConfiguration(revenueCatApiKey));

    final app = _getApplication(injector);
    setState(() => _app = app);
  }

  @override
  void dispose() {
    _stepNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _app ?? PreparationScreen(key: const ValueKey('prep'), stepNotifier: _stepNotifier),
    );
  }
}

// ---------------------------------------------------------------------------
// Hive encryption
// ---------------------------------------------------------------------------

HiveAesCipher _buildHiveCipher() {
  final keyString = dotenv.env['HIVE_ENCRYPTION_KEY'] ?? '';
  final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
  return HiveAesCipher(Uint8List.fromList(keyBytes));
}

// One-time migration: re-encrypts existing unencrypted boxes.
// After the first successful run the SharedPreferences flag prevents re-runs.
Future<void> _migrateToEncryptedIfNeeded(HiveAesCipher cipher) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('hive_aes_encrypted_v1') == true) return;

  Hive.registerAdapter<SettingsObject>(SettingsObjectAdapter());
  Hive.registerAdapter<MindObject>(MindObjectAdapter());
  Hive.registerAdapter<DebugMenuObject>(DebugMenuObjectAdapter());
  Hive.registerAdapter<WeatherCacheObject>(WeatherCacheObjectAdapter());
  await Hive.initFlutter();

  // --- Settings box ---
  // Convert through domain model to get fresh HiveObject instances (not linked to old box).
  final rawSettings = await Hive.openBox<SettingsObject>(HiveConstants.settingsBoxName);
  final settingsDomain = Map.fromEntries(
    rawSettings.keys.map((k) {
      final obj = rawSettings.get(k);
      return MapEntry(k, obj != null ? obj.toSettings().toObject() : null);
    }),
  );
  await rawSettings.close();
  await Hive.deleteBoxFromDisk(HiveConstants.settingsBoxName);
  final encSettings = await Hive.openBox<SettingsObject>(
    HiveConstants.settingsBoxName, encryptionCipher: cipher);
  for (final e in settingsDomain.entries) {
    if (e.value != null) await encSettings.put(e.key, e.value!);
  }
  await encSettings.close();

  // --- Mind box ---
  final rawMinds = await Hive.openBox<MindObject>(HiveConstants.mindBoxName);
  final mindsDomain = Map.fromEntries(
    rawMinds.keys.map((k) {
      final obj = rawMinds.get(k);
      return MapEntry(k, obj != null ? obj.toMind().toObject() : null);
    }),
  );
  await rawMinds.close();
  await Hive.deleteBoxFromDisk(HiveConstants.mindBoxName);
  final encMinds = await Hive.openBox<MindObject>(
    HiveConstants.mindBoxName, encryptionCipher: cipher);
  for (final e in mindsDomain.entries) {
    if (e.value != null) await encMinds.put(e.key, e.value!);
  }
  await encMinds.close();

  // --- Debug menu box ---
  final rawDebug = await Hive.openBox<DebugMenuObject>(HiveConstants.debugMenuBoxName);
  final debugDomain = Map.fromEntries(
    rawDebug.keys.map((k) {
      final obj = rawDebug.get(k);
      final data = obj?.toDebugMenuData();
      return MapEntry(k, data != null ? DebugMenuObject.fromDebugMenuData(data) : null);
    }),
  );
  await rawDebug.close();
  await Hive.deleteBoxFromDisk(HiveConstants.debugMenuBoxName);
  final encDebug = await Hive.openBox<DebugMenuObject>(
    HiveConstants.debugMenuBoxName, encryptionCipher: cipher);
  for (final e in debugDomain.entries) {
    if (e.value != null) await encDebug.put(e.key, e.value!);
  }
  await encDebug.close();

  // Weather cache is disposable — just delete and let it refetch.
  await Hive.deleteBoxFromDisk(HiveConstants.weatherCacheBoxName);

  await Hive.close();
  await prefs.setBool('hive_aes_encrypted_v1', true);
}

// ---------------------------------------------------------------------------
// Hive initialization (after encryption migration)
// ---------------------------------------------------------------------------

Future<void> _initHive(HiveAesCipher cipher) async {
  // Adapters may already be registered after migration; guard against duplicates.
  if (!Hive.isAdapterRegistered(SettingsObjectAdapter().typeId)) {
    Hive.registerAdapter<SettingsObject>(SettingsObjectAdapter());
  }
  if (!Hive.isAdapterRegistered(MindObjectAdapter().typeId)) {
    Hive.registerAdapter<MindObject>(MindObjectAdapter());
  }
  if (!Hive.isAdapterRegistered(DebugMenuObjectAdapter().typeId)) {
    Hive.registerAdapter<DebugMenuObject>(DebugMenuObjectAdapter());
  }
  if (!Hive.isAdapterRegistered(WeatherCacheObjectAdapter().typeId)) {
    Hive.registerAdapter<WeatherCacheObject>(WeatherCacheObjectAdapter());
  }

  await Hive.initFlutter();

  final Box<SettingsObject> settingsBox = await Hive.openBox<SettingsObject>(
    HiveConstants.settingsBoxName, encryptionCipher: cipher);
  if (settingsBox.get(HiveConstants.globalSettingsIndex) == null) {
    settingsBox.put(HiveConstants.globalSettingsIndex, KeklistSettings.initial().toObject());
  }

  final Box<MindObject> mindBox = await Hive.openBox<MindObject>(
    HiveConstants.mindBoxName, encryptionCipher: cipher);
  await Hive.openBox<DebugMenuObject>(
    HiveConstants.debugMenuBoxName, encryptionCipher: cipher);
  await Hive.openBox<WeatherCacheObject>(
    HiveConstants.weatherCacheBoxName, encryptionCipher: cipher);

  await _runMigrations(settingsBox, mindBox);
}

Future<void> _runMigrations(Box<SettingsObject> settingsBox, Box<MindObject> mindBox) async {
  final settingsRepo = SettingsHiveRepository(box: settingsBox);
  final mindRepo = MindHiveRepository(box: mindBox);
  final fileRepo = const AppFileRepository();
  final runner = MigrationRunner(
    settingsRepository: settingsRepo,
    mindRepository: mindRepo,
    fileRepository: fileRepo,
  );
  await runner.runPendingMigrations();
}

// ---------------------------------------------------------------------------
// App widget tree
// ---------------------------------------------------------------------------

Widget _getApplication(Injector mainInjector) => MultiProvider(
  providers: [
    RepositoryProvider(create: (context) => mainInjector.get<MindRepository>()),
    RepositoryProvider(create: (context) => mainInjector.get<AppFileRepository>()),
    RepositoryProvider(create: (context) => mainInjector.get<WeatherRepository>()),
  ],
  child: MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => MindBloc(
          mindSearcherCubit: mainInjector.get<MindSearcherCubit>(),
          mindRepository: mainInjector.get<MindRepository>(),
          fileRepository: mainInjector.get<AppFileRepository>(),
        ),
      ),
      BlocProvider(create: (context) => mainInjector.get<MindSearcherCubit>()),
      BlocProvider(create: (context) => mainInjector.get<EmojiFrequencyCubit>()),
      BlocProvider(create: (context) => MindCreatorBloc(mindRepository: mainInjector.get<MindRepository>())),
      BlocProvider(
        create: (context) => SettingsBloc(
          repository: mainInjector.get<SettingsRepository>(),
          exportImportService: mainInjector.get<ExportImportService>(),
        ),
      ),
      BlocProvider(
        create: (context) => UserProfileBloc(
          mindRepository: mainInjector.get<MindRepository>(),
          settingsRepository: mainInjector.get<SettingsRepository>(),
        ),
      ),
      BlocProvider(create: (context) => DebugMenuBloc(repository: mainInjector.get<DebugMenuRepository>())),
      BlocProvider(
        create: (context) => TabsContainerBloc(
          repository: mainInjector.get<TabsSettingsRepository>(),
          debugMenuRepository: mainInjector.get<DebugMenuRepository>(),
        ),
      ),
      BlocProvider(create: (context) => AudioPlayerBloc()),
      BlocProvider(
        create: (context) =>
            MembershipBloc(debugMenuRepository: mainInjector.get<DebugMenuRepository>())
              ..add(const MembershipGetEvent()),
      ),
      BlocProvider(
        create: (context) => LazyOnboardingBloc(
          mindRepository: mainInjector.get<MindRepository>(),
          settingsRepository: mainInjector.get<SettingsRepository>(),
        ),
      ),
    ],
    child: const KeklistApp(),
  ),
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _initNativeWidgets() {
  // HomeWidget.setAppGroupId(PlatformConstants.iosGroupId);
}

void _setupBlockingLoadingWidget() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 10000)
    ..indicatorType = EasyLoadingIndicatorType.pouringHourGlass
    ..loadingStyle = EasyLoadingStyle.light
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.black.withAlpha(200)
    ..indicatorColor = Colors.white
    ..textColor = Colors.black
    ..maskColor = Colors.blue.withValues(alpha: 0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

void _enableDebugBLOCLogs() {
  if (!kReleaseMode) {
    Bloc.observer = _LoggerBlocObserver();
  }
}

void _connectToWatchCommunicationManager(Injector mainInjector) {
  if (kIsWeb) {
    // no-op
  } else if (Platform.isIOS) {
    mainInjector.get<WatchCommunicationManager>().connect();
  }
}

final class _LoggerBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('onEvent: $event');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    print(error);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('onChange: ${bloc.state}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('onTransition: $bloc.state');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('onClose: ${bloc.runtimeType}');
  }
}
