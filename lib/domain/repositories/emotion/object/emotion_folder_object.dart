import 'package:hive_ce/hive.dart';
import 'package:keklist/domain/services/entities/emotion_folder.dart';

part 'emotion_folder_object.g.dart';

@HiveType(typeId: 5)
class EmotionFolderObject extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2, defaultValue: 0)
  late int orderIndex;

  @HiveField(3)
  late DateTime creationDate;

  EmotionFolderObject();

  EmotionFolder toEmotionFolder() => EmotionFolder(
        id: id,
        title: title,
        orderIndex: orderIndex,
        creationDate: creationDate,
      );
}
