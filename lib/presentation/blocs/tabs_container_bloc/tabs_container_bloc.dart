import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/repositories/tabs/tabs_settings_repository.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';

final class TabsContainerBloc extends Bloc<TabsContainerEvent, TabsContainerState> with DisposeBag {
  final TabsSettingsRepository repository;

  TabsContainerBloc({required this.repository})
      : super(
          TabsContainerState(
            selectedTabIndex: 0,
            tabs: [],
          ),
        ) {
    on<TabsContainerGetCurrentState>(_sendState);
    on<TabsContainerChangeSelectedTab>(_changeTab);

    repository.stream.listen((data) => add(TabsContainerGetCurrentState())).disposed(by: this);
  }

  FutureOr<void> _sendState(
    TabsContainerGetCurrentState event,
    Emitter<TabsContainerState> emit,
  ) {
    final TabsContainerState newState = TabsContainerState(
      selectedTabIndex: state.selectedTabIndex,
      tabs: repository.value.tabModels,
    );
    emit(newState);
  }

  FutureOr<void> _changeTab(
    TabsContainerChangeSelectedTab event,
    Emitter<TabsContainerState> emit,
  ) {
    emit(
      TabsContainerState(
        selectedTabIndex: event.selectedIndex,
        tabs: state.tabs,
      ),
    );
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  // TODO: update order tabs and default tab
}
