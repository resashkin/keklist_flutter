import 'dart:async';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:keklist/domain/repositories/bloc_log_settings/bloc_log_settings.dart';
import 'package:keklist/domain/repositories/bloc_log_settings/bloc_log_settings_repository.dart';
import 'package:rxdart/rxdart.dart';

final class BlocLogSettingsHiveRepository implements BlocLogSettingsRepository {
  static const String _verboseKey = 'verbose';
  static const String _silencedKey = 'silenced';
  static const String _knownBlocsKey = 'known_blocs';

  final Box _box;
  final BehaviorSubject<BlocLogSettings> _subject = BehaviorSubject<BlocLogSettings>();

  BlocLogSettingsHiveRepository({required Box box}) : _box = box {
    _subject.add(_read());
    _subject.addStream(
      _box.watch().map((_) => _read()).debounceTime(const Duration(milliseconds: 10)),
    );
  }

  BlocLogSettings _read() {
    final bool verbose = _box.get(_verboseKey, defaultValue: false) as bool;
    final Set<String> silenced = _readStringSet(_silencedKey);
    final Set<String> knownBlocs = _readStringSet(_knownBlocsKey);
    return BlocLogSettings(verbose: verbose, silenced: silenced, knownBlocs: knownBlocs);
  }

  Set<String> _readStringSet(String key) {
    final raw = _box.get(key);
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return <String>{};
  }

  @override
  BlocLogSettings get value => _subject.value;

  @override
  Stream<BlocLogSettings> get stream => _subject.stream;

  @override
  FutureOr<void> setVerbose(bool verbose) async {
    await _box.put(_verboseKey, verbose);
  }

  @override
  FutureOr<void> setSilenced(String blocName, bool silenced) async {
    final Set<String> current = _readStringSet(_silencedKey);
    if (silenced) {
      current.add(blocName);
    } else {
      current.remove(blocName);
    }
    await _box.put(_silencedKey, current.toList(growable: false));
  }

  @override
  FutureOr<void> recordKnownBloc(String blocName) async {
    final Set<String> current = _readStringSet(_knownBlocsKey);
    if (current.add(blocName)) {
      await _box.put(_knownBlocsKey, current.toList(growable: false));
    }
  }
}
