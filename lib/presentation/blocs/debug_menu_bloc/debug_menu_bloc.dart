import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';

part 'debug_menu_event.dart';
part 'debug_menu_state.dart';

final class DebugMenuBloc extends Bloc<DebugMenuEvent, DebugMenuState> with DisposeBag {
  final DebugMenuRepository _repository;

  DebugMenuBloc({
    required DebugMenuRepository repository,
  })  : _repository = repository,
        super(
          DebugMenuDataState(
            debugMenuItems: repository.value,
            isDeveloperModeEnabled: repository.isDeveloperModeEnabled,
          ),
        ) {
    on<DebugMenuGet>(_getDebugMenuItems);
    on<DebugMenuUpdate>(_updateDebugMenuItem);
    on<DebugMenuEnableDeveloperMode>(_enableDeveloperMode);

    _repository.stream.listen((debugMenuItems) => add(DebugMenuGet())).disposed(by: this);
    _repository.developerModeStream.listen((isEnabled) => add(DebugMenuGet())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  FutureOr<void> _getDebugMenuItems(DebugMenuGet event, Emitter<DebugMenuState> emit) async {
    emit(
      DebugMenuDataState(
        debugMenuItems: _repository.value,
        isDeveloperModeEnabled: _repository.isDeveloperModeEnabled,
      ),
    );
  }

  FutureOr<void> _updateDebugMenuItem(DebugMenuUpdate event, Emitter<DebugMenuState> emit) async {
    emit(DebugMenuLoadingState(true));

    await _repository.update(
      flagType: event.flagType,
      value: event.value,
    );

    emit(DebugMenuLoadingState(false));
  }

  FutureOr<void> _enableDeveloperMode(DebugMenuEnableDeveloperMode event, Emitter<DebugMenuState> emit) async {
    await _repository.enableDeveloperMode();
  }
}
