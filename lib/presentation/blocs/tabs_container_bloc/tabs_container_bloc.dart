import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/domain/repositories/tabs/tabs_settings_repository.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';

final class TabsContainerBloc extends Bloc<TabsContainerEvent, TabsContainerState> with DisposeBag {
  final TabsSettingsRepository _repository;

  TabsContainerBloc({required TabsSettingsRepository repository})
      : _repository = repository,
        super(
          TabsContainerState(
            selectedTabIndex: 0,
            selectedTabs: [],
            unSelectedTabs: KeklistConstants.availableTabModels,
          ),
        ) {
    on<TabsContainerGetCurrentState>(_sendState);
    on<TabsContainerChangeSelectedTab>(_changeTab);
    on<TabsContainerSelectTab>(_selectTab);
    on<TabsContainerUnselectTab>(_unselectTab);
    _repository.stream.listen((data) => add(TabsContainerGetCurrentState())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  FutureOr<void> _sendState(
    TabsContainerGetCurrentState event,
    Emitter<TabsContainerState> emit,
  ) {
    final TabsContainerState newState = TabsContainerState(
      selectedTabIndex: _getSelectedTabIndex(),
      selectedTabs: _repository.value.selectedTabModels,
      unSelectedTabs: KeklistConstants.availableTabModels
          .where((tab) => !_repository.value.selectedTabModels.map((tab) => tab.type).contains(tab.type))
          .toList(),
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
        selectedTabs: state.selectedTabs,
        unSelectedTabs: KeklistConstants.availableTabModels
            .where((tab) => !_repository.value.selectedTabModels.map((tab) => tab.type).contains(tab.type))
            .toList(),
      ),
    );
  }

  FutureOr<void> _selectTab(TabsContainerSelectTab event, Emitter<TabsContainerState> emit) {
    final TabModel selectedTabModel =
        KeklistConstants.availableTabModels.firstWhere((tabModel) => tabModel.type == event.tabType);
    _repository.update(selectedTabList: _repository.value.selectedTabModels + [selectedTabModel]);
  }

  FutureOr<void> _unselectTab(TabsContainerUnselectTab event, Emitter<TabsContainerState> emit) {
    final List<TabModel> updatedTabList =
        _repository.value.selectedTabModels.where((tabModel) => tabModel.type != event.tabType).toList();
    _repository.update(selectedTabList: updatedTabList);
  }

  int _getSelectedTabIndex() {
    if (state.selectedTabIndex >= _repository.value.selectedTabModels.length - 1) {
      return _repository.value.selectedTabModels.length - 1;
    } else if (state.selectedTabIndex <= 0) {
      return 0;
    } else {
      return state.selectedTabIndex;
    }
  }
}
