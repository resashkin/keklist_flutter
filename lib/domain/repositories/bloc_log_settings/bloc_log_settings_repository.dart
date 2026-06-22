import 'dart:async';

import 'package:keklist/domain/repositories/bloc_log_settings/bloc_log_settings.dart';

abstract class BlocLogSettingsRepository {
  BlocLogSettings get value;
  Stream<BlocLogSettings> get stream;

  FutureOr<void> setVerbose(bool verbose);
  FutureOr<void> setSilenced(String blocName, bool silenced);
  FutureOr<void> recordKnownBloc(String blocName);
}
