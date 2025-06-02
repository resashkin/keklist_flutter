import 'package:equatable/equatable.dart';
import 'package:keklist/presentation/core/helpers/enum_utils.dart';
import 'package:keklist/domain/repositories/message/message/message_object.dart';

class Message with EquatableMixin {
  final String id;
  final String text;
  final String rootMindId;
  final DateTime timestamp;
  final MessageSender sender;

  Message({
    required this.id,
    required this.text,
    required this.rootMindId,
    required this.timestamp,
    required this.sender,
  });

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [
        id,
        text,
        rootMindId,
        timestamp.millisecondsSinceEpoch,
      ];

  MessageObject toObject() => MessageObject()
    ..id = id
    ..text = text
    ..rootMindId = rootMindId
    ..timestamp = timestamp
    ..sender = EnumUtils.stringFromEnum(sender);
}

enum MessageSender { user, system, assistant }
