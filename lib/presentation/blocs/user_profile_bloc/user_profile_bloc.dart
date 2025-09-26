import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:uuid/uuid.dart';

final class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> with DisposeBag {
  final SettingsRepository _settingsRepository;
  final MindRepository _mindRepository;

  UserProfileBloc({
    required SettingsRepository settingsRepository,
    required MindRepository mindRepository,
  })  : _settingsRepository = settingsRepository,
        _mindRepository = mindRepository,
        super(
          UserProfileState(
            nickname: '',
            folders: [],
          ),
        ) {
    on<UserProfileGet>(_getUserProfile);
    on<UserProfileUpdateNickName>(_updateNickName);
    on<UserProfileAddFolderMind>(_addFolderMind);

    _settingsRepository.stream
        .map((settings) => settings.userName)
        .distinct()
        .listen((userName) async => add(UserProfileGet()))
        .disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();

    return super.close();
  }

  // On-Events

  Future<void> _getUserProfile(UserProfileGet event, Emitter<UserProfileState> emit) async {
    final List<Mind> folders =
        (await _mindRepository.obtainMindsWhere((mind) => mind.dayIndex == KeklistConstants.foldersDayIndex))
            .toList(growable: false);
    emit(
      UserProfileState(
        nickname: _settingsRepository.value.userName,
        folders: folders,
      ),
    );
  }

  Future<void> _updateNickName(
    UserProfileUpdateNickName event,
    Emitter<UserProfileState> emit,
  ) async {
    await _settingsRepository.updateUserName(event.nickName);
    emit(
      UserProfileState(
        nickname: state.nickname,
        folders: state.folders,
      ),
    );
  }

  Future<void> _addFolderMind(
    UserProfileAddFolderMind event,
    Emitter<UserProfileState> emit,
  ) async {
    final Mind mind = await _mindRepository.createMind(
      mind: Mind(
        id: const Uuid().v4(),
        dayIndex: 0,
        note: event.note,
        emoji: event.emoji,
        creationDate: DateTime.now().toUtc(),
        sortIndex: 0,
        rootId: null,
      ),
    );
    emit(
      UserProfileState(
        nickname: state.nickname,
        folders: state.folders.concat([mind]),
      ),
    );
  }

  // Private functions

  // Future<List<String>> _getSuggestionEmojies() async {
  //   final Iterable<Mind> minds = await _mindRepository.obtainMinds();
  //   final List<String> predictedEmojies = minds
  //       .map((mind) => mind.emoji)
  //       .toList()
  //       .distinct()
  //       .sorted((emoji1, emoji2) => minds
  //           .where((mind) => mind.emoji == emoji2)
  //           .length
  //           .compareTo(minds.where((mind) => mind.emoji == emoji1).length))
  //       .toList(growable: false);
  //   return predictedEmojies;
  // }
}

// Events.

abstract class UserProfileEvent {}

final class UserProfileGet extends UserProfileEvent {
  UserProfileGet();
}

final class UserProfileAddFolderMind extends UserProfileEvent {
  final String emoji;
  final String note;

  UserProfileAddFolderMind({required this.emoji, required this.note});
}

final class UserProfileUpdateNickName extends UserProfileEvent {
  final String nickName;

  UserProfileUpdateNickName({required this.nickName});
}

// State.

final class UserProfileState {
  final String? nickname;
  final List<Mind> folders;

  UserProfileState({
    required this.nickname,
    required this.folders,
  });
}
