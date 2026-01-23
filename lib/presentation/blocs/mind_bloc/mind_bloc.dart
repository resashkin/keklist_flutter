import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
// import 'package:home_widget/home_widget.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:rxdart/rxdart.dart';
import 'package:keklist/presentation/cubits/mind_searcher/mind_searcher_cubit.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

part 'mind_event.dart';
part 'mind_state.dart';

final class MindBloc extends Bloc<MindEvent, MindState> with DisposeBag {
  late final MindSearcherCubit _searcherCubit;
  late final MindRepository _mindRepository;

  MindBloc({required MindSearcherCubit mindSearcherCubit, required MindRepository mindRepository})
    : super(MindList(values: const [])) {
    _searcherCubit = mindSearcherCubit;
    _mindRepository = mindRepository;
    on<MindGetList>(_getMinds);
    on<MindUpdateMobileWidgets>(_updateMobileWidgets);
    on<MindCreate>(_createMind);
    on<MindDelete>(_deleteMind);
    on<MindClearCache>(_clearCache);
    on<MindEdit>(_editMind);
    on<MindStartSearch>(_startSearch);
    on<MindStopSearch>(_stopSearch);
    on<MindEnterSearchText>(
      _enterTextSearch,
      transformer: (events, mapper) => events.debounceTime(const Duration(milliseconds: 300)).asyncExpand(mapper),
    );
    on<MindInternalGetListFromCache>((_, emit) => _emitMindList(emit));
    _mindRepository.stream.listen((event) => add(MindInternalGetListFromCache())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();

    return super.close();
  }

  Future<void> _getMinds(MindGetList event, Emitter<MindState> emit) async {
    _emitMindList(emit);
  }

  Future<void> _createMind(MindCreate event, Emitter<MindState> emit) async {
    final int sortIndex =
        ((await _findMindsByDayIndex(event.dayIndex)).map((mind) => mind.sortIndex).maxOrNull ?? -1) + 1;

    final List<BaseMindNotePiece> sanitizedPieces = <BaseMindNotePiece>[];
    for (final BaseMindNotePiece piece in event.mindContent) {
      piece.map(
        text: (MindNoteText textPiece) {
          sanitizedPieces.add(textPiece);
        },
        audio: (MindNoteAudio audioPiece) {
          final String trimmedPath = audioPiece.appRelativeAbsoulutePath.trim();
          if (trimmedPath.isEmpty) {
            return;
          }
          sanitizedPieces.add(
            trimmedPath == audioPiece.appRelativeAbsoulutePath
                ? audioPiece
                : MindNoteAudio(
                    appRelativeAbsoulutePath: trimmedPath,
                    durationSeconds: audioPiece.durationSeconds,
                  ),
          );
        },
        unknown: () => null,
      );
    }

    final MindNoteContent content = sanitizedPieces.isEmpty
        ? MindNoteContent.empty()
        : MindNoteContent.fromPieces(sanitizedPieces);

    final Mind mind = Mind(
      id: const Uuid().v4(),
      dayIndex: event.dayIndex,
      note: content.toRawNoteString(),
      emoji: event.emoji,
      creationDate: DateTime.now().toUtc(),
      sortIndex: sortIndex,
      rootId: event.rootId,
    );
    _mindRepository.createMind(mind: mind);
  }

  // TODO: remove audio content as well when mind was related with it

  Future<void> _deleteMind(MindDelete event, Emitter<MindState> emit) async {
    await _mindRepository.deleteMindsWhere((mind) => mind.rootId == event.mind.id);
    await _mindRepository.deleteMind(mindId: event.mind.id);
  }

  FutureOr<void> _startSearch(MindStartSearch event, emit) async {
    emit(MindSearching(enabled: true, allValues: _mindRepository.values, resultValues: const []));
  }

  FutureOr<void> _stopSearch(MindStopSearch event, emit) async {
    emit(MindSearching(enabled: false, allValues: _mindRepository.values, resultValues: const []));
  }

  FutureOr<void> _enterTextSearch(MindEnterSearchText event, Emitter<MindState> emit) async {
    final List<Mind> filteredMinds = await _searcherCubit.searchMindList(event.text);
    emit(MindSearching(enabled: true, allValues: _mindRepository.values, resultValues: filteredMinds));
  }

  Future<List<Mind>> _findMindsByDayIndex(int index) async {
    final minds = await _mindRepository.obtainMindsWhere((mind) => mind.dayIndex == index && mind.rootId == null)
      ..sortedByProperty((it) => it.sortIndex);
    return minds.toList();
  }

  Future<void> _editMind(MindEdit event, Emitter<MindState> emit) async {
    final Mind editedMind = event.mind;
    await _mindRepository.updateMind(mind: editedMind);
  }

  Future<void> _emitMindList(Emitter<MindState> emit) async {
    emit(MindList(values: _mindRepository.values));
  }

  Future<void> _clearCache(MindClearCache event, Emitter<MindState> emit) async {
    await _mindRepository.deleteMinds();
  }

  Future<void> _updateMobileWidgets(MindUpdateMobileWidgets event, Emitter<MindState> emit) async {
    // if (DeviceUtils.safeGetPlatform() != SupportedPlatform.iOS) {
    //   return;
    // }
    // final Iterable<Mind> todayMinds =
    //     await _repository.obtainMindsWhere((mind) => mind.dayIndex == MindUtils.getTodayIndex() && mind.rootId == null);

    // final List<String> todayMindJSONList = todayMinds
    //     .map(
    //       (mind) => json.encode(
    //         mind,
    //         toEncodable: (i) => mind.toShortJson(),
    //       ),
    //     )
    //     .toList();
    // final List<Object?>? currentWidgetData = await HomeWidget.getWidgetData('mind_today_widget_today_minds');
    // if (listEquals(currentWidgetData, todayMindJSONList)) {
    //   return;
    // }
    // await HomeWidget.saveWidgetData('mind_today_widget_today_minds', todayMindJSONList);
    // await HomeWidget.updateWidget(iOSName: PlatformConstants.iosMindDayWidgetName);
  }
}
