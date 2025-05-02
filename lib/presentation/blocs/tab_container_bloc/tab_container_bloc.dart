import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/presentation/blocs/tab_container_bloc/tab_container_event.dart';
import 'package:keklist/presentation/blocs/tab_container_bloc/tab_container_state.dart';

final class TabContainerBloc extends Bloc<TabContainerEvent, TabContainerState> {
  TabContainerBloc()
      : super(
          TabContainerState(
            selectedTabIndex: 0,
            tabs: [
              TabModel(type: TabType.calendar),
              TabModel(type: TabType.insights),
              TabModel(type: TabType.profile),
            ],
          ),
        ) {
    on<TabContainerGetCurrentState>(_sendState);
    on<TabContainerChangeSelectedTab>(_changeTab);
  }

  FutureOr<void> _sendState(
    TabContainerGetCurrentState event,
    Emitter<TabContainerState> emit,
  ) {
    emit(state);
  }

  FutureOr<void> _changeTab(
    TabContainerChangeSelectedTab event,
    Emitter<TabContainerState> emit,
  ) {
    emit(
      TabContainerState(
        selectedTabIndex: event.selectedIndex,
        tabs: state.tabs,
      ),
    );
  }
}
