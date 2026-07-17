import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:keklist/domain/hive_constants.dart';
import 'package:keklist/domain/repositories/mind/object/mind_object.dart';
import 'package:keklist/domain/repositories/mind/mind_hive_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    // Use an isolated temp dir so boxes never land in the project root.
    tempDir = Directory.systemTemp.createTempSync('hive_mind_repo_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter<MindObject>(MindObjectAdapter(), override: true);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });
  test('stream values and saved values the same', () async {
    // Given
    final hiveBox = await Hive.openBox<MindObject>(HiveConstants.mindBoxName);
    final MindRepository repository = MindHiveRepository(box: hiveBox);
    final Mind mind = Mind(
      id: '1',
      note: 'Heh1',
      emoji: ' ',
      dayIndex: 0,
      sortIndex: 5,
      creationDate: DateTime.now(),
      rootId: null,
    );

    // When
    await repository.updateMinds(minds: [mind, mind, mind, mind]);
    repository.stream.listen((minds) {
      // Then
      expect(repository.values, minds);
    });
  });
  test(
    'mind is created',
    () async {
      // Given
      final hiveBox = await Hive.openBox<MindObject>(HiveConstants.mindBoxName);
      final MindRepository repository = MindHiveRepository(box: hiveBox);

      // When
      var mind = Mind(
        id: '1',
        note: 'Heh1',
        emoji: ' ',
        dayIndex: 0,
        sortIndex: 5,
        creationDate: DateTime.now(),
        rootId: null,
      );
      await repository.createMind(mind: mind);
      final minds = await repository.obtainMinds();

      // Then
      expect(minds.contains(mind), true);
    },
  );
}
