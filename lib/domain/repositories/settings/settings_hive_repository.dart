import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:keklist/domain/hive_constants.dart';
import 'package:keklist/domain/repositories/settings/object/settings_object.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:rxdart/rxdart.dart';

final class SettingsHiveRepository implements SettingsRepository {
  final Box<SettingsObject> _hiveBox;
  final BehaviorSubject<KeklistSettings> _behaviorSubject = BehaviorSubject<KeklistSettings>();
  SettingsObject? get _settingsObject => _hiveBox.values.firstOrNull;

  SettingsHiveRepository({required Box<SettingsObject> box}) : _hiveBox = box {
    if (_settingsObject != null) {
      _behaviorSubject.add(_settingsObject!.toSettings());
    } else {
      updateSettings(KeklistSettings.initial());
    }
    _behaviorSubject.addStream(
      _hiveBox
          .watch()
          .whereNotNull()
          .map((_) => _settingsObject!.toSettings())
          .debounceTime(const Duration(milliseconds: 10)),
    );
  }

  @override
  KeklistSettings get value => _behaviorSubject.value;

  @override
  Stream<KeklistSettings> get stream => _behaviorSubject;

  @override
  FutureOr<void> updateDarkMode(bool isDarkMode) async {
    final SettingsObject? settingsObject = _hiveBox.get(HiveConstants.globalSettingsIndex);
    settingsObject?.isDarkMode = isDarkMode;
    await settingsObject?.save();
  }

  @override
  FutureOr<void> updateMindContentVisibility(bool isVisible) async {
    final SettingsObject? settingsObject = _hiveBox.get(HiveConstants.globalSettingsIndex);
    settingsObject?.isMindContentVisible = isVisible;
    await settingsObject?.save();
  }

  @override
  FutureOr<void> updateOpenAIKey(String? openAIKey) async {
    final SettingsObject? settingsObject = _hiveBox.get(HiveConstants.globalSettingsIndex);
    settingsObject?.openAIKey = openAIKey;
    await settingsObject?.save();
  }

  @override
  FutureOr<void> updateLanguage(SupportedLanguage language) async {
    final SettingsObject? settingsObject = _hiveBox.get(HiveConstants.globalSettingsIndex);
    settingsObject?.language = language.code;
    await settingsObject?.save();
  }

  @override
  FutureOr<void> updatePreviousAppVersion(String? previousAppVersion) async {
    final SettingsObject? settingsObject = _hiveBox.get(HiveConstants.globalSettingsIndex);
    settingsObject?.previousAppVersion = previousAppVersion;
    await settingsObject?.save();
  }

  @override
  FutureOr<void> updateSettings(KeklistSettings settings) async {
    await _hiveBox.put(HiveConstants.globalSettingsIndex, settings.toObject());
  }

  @override
  FutureOr<void> updateShouldShowTitles(bool shouldShowTitles) async {
    final SettingsObject? settingsObject = _hiveBox.get(HiveConstants.globalSettingsIndex);
    settingsObject?.shouldShowTitles = shouldShowTitles;
    await settingsObject?.save();
  }

  @override
  FutureOr<void> updateUserName(String userName) async {
    final SettingsObject? settingsObject = _hiveBox.get(HiveConstants.globalSettingsIndex);
    settingsObject?.userName = userName;
    await settingsObject?.save();
  }
}
