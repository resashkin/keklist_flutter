// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/services.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:keklist/presentation/core/helpers/enum_utils.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/mind_service/main_service.dart';
import 'package:emojis/emoji.dart' as emojies_pub;

abstract class WatchCommunicationManager {
  void connect() {}
}

final class AppleWatchCommunicationManager implements WatchCommunicationManager {
  final MethodChannel _channel = const MethodChannel('com.sashkyn.kekable');

  final MindService mindService;
  final MindRepository mindRepository;
  final SupabaseClient client;

  AppleWatchCommunicationManager({
    required this.mindService,
    required this.mindRepository,
    required this.client,
  });

  @override
  void connect() {
    _setupCallBackHandler();
  }

  Future<void> _sendToWatch({
    required WatchOutputMethod outputMethod,
    required Map<WatchMethodArgumentKey, dynamic> arguments,
  }) async {
    final Map<String, String> methodArguments = arguments.map(
      (key, value) => MapEntry<String, String>(
        EnumUtils.stringFromEnum(key),
        value.toString(),
      ),
    );

    final String methodName = EnumUtils.stringFromEnum(outputMethod);
    await _channel.invokeMethod(
      methodName,
      [methodArguments],
    );
  }

  void _setupCallBackHandler() {
    _channel.setMethodCallHandler(
      (MethodCall call) async {
        if (client.auth.currentUser == null) {
          return _showError(error: WatchError.notAuthorized);
        }

        final String methodName = call.method;
        final dynamic methodArgs = call.arguments;

        // print('methodName = $methodName');
        // print('methodArgs = $methodArgs');

        // TODO: переписать на Switch
        if (methodName == EnumUtils.stringFromEnum(WatchInputMethod.obtainTodayMinds)) {
          return _showMindList();
        } else if (methodName == EnumUtils.stringFromEnum(WatchInputMethod.obtainPredictedEmojies)) {
          final String mindText = methodArgs[EnumUtils.stringFromEnum(WatchMethodArgumentKey.mindText)];
          return _showPredictedEmojies(mindText: mindText);
        } else if (methodName == EnumUtils.stringFromEnum(WatchInputMethod.createMind)) {
          final String mindText = methodArgs[EnumUtils.stringFromEnum(WatchMethodArgumentKey.mindText)];
          final String emoji = methodArgs[EnumUtils.stringFromEnum(WatchMethodArgumentKey.mindEmoji)];
          return _createMindForToday(
            mindText: mindText,
            emoji: emoji,
          );
        } else if (methodName == EnumUtils.stringFromEnum(WatchInputMethod.deleteMind)) {
          final String mindId = methodArgs[EnumUtils.stringFromEnum(WatchMethodArgumentKey.mindId)];
          return _removeMindFromToday(id: mindId);
        }
      },
    );
  }

  Future<void> _createMindForToday({
    required String mindText,
    required String emoji,
  }) async {
    final int dayIndex = MindUtils.getDayIndex(from: DateTime.now());
    final Iterable<Mind> mindList = await mindRepository.obtainMindsWhere((element) => element.dayIndex == dayIndex);
    final int sortIndex = mindList.length;

    final Mind mind = Mind(
      id: const Uuid().v4(),
      dayIndex: MindUtils.getDayIndex(from: DateTime.now()),
      note: mindText,
      emoji: emoji,
      creationDate: DateTime.now(),
      sortIndex: sortIndex,
      rootId: null,
    );
    await mindService.createMind(mind);
    final String mindJSON = json.encode(
      mind,
      toEncodable: (_) => mind.toShortJson(),
    );
    return _sendToWatch(
      outputMethod: WatchOutputMethod.mindDidCreated,
      arguments: {
        WatchMethodArgumentKey.mind: mindJSON,
      },
    );
  }

  Future<void> _showMindList() async {
    final Iterable<Mind> mindList =
        await mindRepository.obtainMindsWhere((element) => element.dayIndex == MindUtils.getTodayIndex());
    final Iterable<Mind> todayMindList = MindUtils.findTodayMinds(allMinds: mindList.toList());
    final List<String> mindJSONList = todayMindList
        .map(
          (mind) => json.encode(
            mind,
            toEncodable: (i) => mind.toShortJson(),
          ),
        )
        .toList();
    return _sendToWatch(
      outputMethod: WatchOutputMethod.showMinds,
      arguments: {
        WatchMethodArgumentKey.minds: mindJSONList,
      },
    );
  }

  Future<void> _removeMindFromToday({required String id}) async {
    await mindService.deleteMind(id);
    return _sendToWatch(
      outputMethod: WatchOutputMethod.mindDidDeleted,
      arguments: {},
    );
  }

  Future<void> _showPredictedEmojies({required String mindText}) async {
    final Iterable<Mind> minds = await mindRepository.obtainMinds();
    List<String> predictedEmojies = minds
        .map((mind) => mind.emoji)
        .toList()
        .distinct()
        .sorted((emoji1, emoji2) => minds
            .where((mind) => mind.emoji == emoji2)
            .length
            .compareTo(minds.where((mind) => mind.emoji == emoji1).length))
        .toList();

    if (predictedEmojies.isEmpty) {
      predictedEmojies = emojies_pub.Emoji.all().map((emoji) => emoji.char).toList();
    }

    final List<String> emojiJSONList = predictedEmojies.map((mind) => json.encode(mind)).toList();

    return _sendToWatch(
      outputMethod: WatchOutputMethod.showPredictedEmojies,
      arguments: {
        WatchMethodArgumentKey.emojies: emojiJSONList,
      },
    );
  }

  Future<void> _showError({required WatchError error}) async => _sendToWatch(
        outputMethod: WatchOutputMethod.showError,
        arguments: {
          WatchMethodArgumentKey.error: EnumUtils.stringFromEnum(error),
        },
      );
}

enum WatchInputMethod {
  obtainTodayMinds,
  obtainPredictedEmojies,
  createMind,
  deleteMind,
}

enum WatchOutputMethod {
  showMinds,
  showPredictedEmojies,
  showError,
  mindDidCreated,
  mindDidDeleted,
}

enum WatchMethodArgumentKey {
  minds,
  mind,
  mindId,
  mindText,
  mindEmoji,
  emojies,
  error,
}

enum WatchError { notAuthorized }
