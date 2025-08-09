import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:hive/hive.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/hive_constants.dart';
import 'package:keklist/domain/repositories/tabs/tabs_settings_repository.dart';
import 'package:keklist/domain/repositories/tabs/tabs_settings_shared_preferences_repository.dart';
import 'package:keklist/domain/services/auth/auth_service.dart';
import 'package:keklist/domain/repositories/mind/object/mind_object.dart';
import 'package:keklist/domain/repositories/mind/mind_hive_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/object/settings_object.dart';
import 'package:keklist/domain/repositories/settings/settings_hive_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_hive_repository.dart';
import 'package:keklist/domain/repositories/debug_menu/object/debug_menu_object.dart';
import 'package:keklist/domain/services/mind_service/main_supabase_service.dart';
import 'package:keklist/presentation/core/helpers/platform_utils.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keklist/presentation/cubits/mind_searcher/mind_searcher_cubit.dart';
import 'package:keklist/presentation/native/ios/watch/watch_communication_manager.dart';
import 'package:keklist/domain/services/mind_service/main_service.dart';

final class MainContainer {
  final StreamingSharedPreferences _streamingSharedPreferences;

  MainContainer({required StreamingSharedPreferences streamingSharedPreferences})
      : _streamingSharedPreferences = streamingSharedPreferences;

  Injector initialize(Injector injector) {
    injector.map<MindService>(
      (injector) => MindSupabaseService(),
      isSingleton: true,
    );
    injector.map<MindSearcherCubit>(
      (injector) => MindSearcherCubit(repository: injector.get<MindRepository>()),
    );
    if (DeviceUtils.safeGetPlatform() == SupportedPlatform.iOS) {
      injector.map<WatchCommunicationManager>(
        (injector) => (AppleWatchCommunicationManager(
          mindService: injector.get<MindService>(),
          mindRepository: injector.get<MindRepository>(),
          client: Supabase.instance.client,
        )),
        isSingleton: true,
      );
    }
    injector.map<MindRepository>(
      (injector) => MindHiveRepository(box: Hive.box<MindObject>(HiveConstants.mindBoxName)),
    );
    injector.map<SettingsRepository>(
      (injector) => SettingsHiveRepository(box: Hive.box<SettingsObject>(HiveConstants.settingsBoxName)),
    );
    injector.map<DebugMenuRepository>(
      (injector) => DebugMenuHiveRepository(box: Hive.box<DebugMenuObject>(HiveConstants.debugMenuBoxName)),
    );
    injector.map<TabsSettingsRepository>(
      (injector) => TabsSettingsSharedPreferencesRepository(preferences: _streamingSharedPreferences),
    );
    injector.map<AuthService>(
      (injector) => AuthSupabaseService(client: Supabase.instance.client),
    );
    return injector;
  }
}
