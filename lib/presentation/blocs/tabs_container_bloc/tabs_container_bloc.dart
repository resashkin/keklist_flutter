import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/domain/repositories/tabs/tabs_settings_repository.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';

final class TabsContainerBloc extends Bloc<TabsContainerEvent, TabsContainerState> with DisposeBag {
  final TabsSettingsRepository _repository;
  final DebugMenuRepository _debugMenuRepository;

  TabsContainerBloc({
    required TabsSettingsRepository repository,
    required DebugMenuRepository debugMenuRepository,
  })  : _repository = repository,
        _debugMenuRepository = debugMenuRepository,
        super(
          TabsContainerState(
            selectedTabIndex: 0,
            selectedTabs: [],
            hiddenTabs: KeklistConstants.availableTabModels,
          ),
        ) {
    on<TabsContainerGetCurrentState>(_sendState);
    on<TabsContainerChangeSelectedTab>(_changeTab);
    on<TabsContainerSelectTab>(_selectTab);
    on<TabsContainerUnselectTab>(_unselectTab);
    on<TabsContainerReorderTabs>(_reorderTabs);
    _repository.stream.listen((data) => add(TabsContainerGetCurrentState())).disposed(by: this);
    _debugMenuRepository.developerModeStream.listen((_) => add(TabsContainerGetCurrentState())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  List<TabModel> get _availableTabModels {
    return KeklistConstants.availableTabModels
        .where((tab) => tab.type != TabType.debugMenu || _debugMenuRepository.isDeveloperModeEnabled)
        .toList();
  }

  FutureOr<void> _sendState(
    TabsContainerGetCurrentState event,
    Emitter<TabsContainerState> emit,
  ) {
    final availableTabs = _availableTabModels;
    final selectedTabs = _repository.value.selectedTabModels
        .where((tab) => availableTabs.any((available) => available.type == tab.type))
        .toList();

    final TabsContainerState newState = TabsContainerState(
      selectedTabIndex: _getSelectedTabIndex(),
      selectedTabs: _repository.value.selectedTabModels,
      hiddenTabs: KeklistConstants.availableTabModels
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
        hiddenTabs: KeklistConstants.availableTabModels
            .where((tab) => !_repository.value.selectedTabModels.map((tab) => tab.type).contains(tab.type))
            .toList(),
      ),
    );
  }

  FutureOr<void> _selectTab(TabsContainerSelectTab event, Emitter<TabsContainerState> emit) {
    final TabModel selectedTabModel =
        KeklistConstants.availableTabModels.firstWhere((tabModel) => tabModel.type == event.tabType);
    _repository.update(tabModels: _repository.value.selectedTabModels + [selectedTabModel]);
  }

  FutureOr<void> _unselectTab(TabsContainerUnselectTab event, Emitter<TabsContainerState> emit) {
    final List<TabModel> updatedTabList =
        _repository.value.selectedTabModels.where((tabModel) => tabModel.type != event.tabType).toList();
    _repository.update(tabModels: updatedTabList);
  }

  FutureOr<void> _reorderTabs(TabsContainerReorderTabs event, Emitter<TabsContainerState> emit) {
    final List<TabModel> updatedTabs = List.of(_repository.value.selectedTabModels);
    final tab = updatedTabs.removeAt(event.oldIndex);
    updatedTabs.insert(event.newIndex, tab);
    _repository.update(tabModels: updatedTabs);
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
