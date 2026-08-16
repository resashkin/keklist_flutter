import 'package:hive_ce/hive.dart';
import 'package:keklist/domain/services/entities/emotion.dart';

part 'emotion_object.g.dart';

@HiveType(typeId: 3)
class EmotionObject extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String emoji;

  // HiveField(3) previously held `folderIds` (removed with the folder feature).
  // The index is retired; new records omit it and old records ignore it on read.

  @HiveField(4, defaultValue: false)
  late bool isArchived;

  @HiveField(5, defaultValue: 0)
  late int orderIndex;

  @HiveField(6)
  late DateTime creationDate;

  @HiveField(7, defaultValue: null)
  late String? parentId;

  EmotionObject();

  Emotion toEmotion() => Emotion(
        id: id,
        title: title,
        emoji: emoji,
        parentId: parentId,
        isArchived: isArchived,
        orderIndex: orderIndex,
        creationDate: creationDate,
      );
}
