import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:keklist/domain/hive_constants.dart';
import 'package:keklist/domain/repositories/mind/object/mind_object.dart';
import 'package:keklist/domain/repositories/mind/mind_hive_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';

Future<void> main() async {
  // Use an isolated temp dir so boxes never land in the project root.
  final tempDir = Directory.systemTemp.createTempSync('hive_mind_repo_benchmark');
  Hive.init(tempDir.path);
  Hive.registerAdapter<MindObject>(MindObjectAdapter());
  final hiveBox = await Hive.openBox<MindObject>(HiveConstants.mindBoxName);
  final MindRepository repository = MindHiveRepository(box: hiveBox);

  final minds = List.generate(
    10000,
    (index) {
      return Mind(
        id: index.toString(),
        note: 'Hahahahahahaasdgasjdglashdglsdhglskdfhglsdkfjhgsldkfahaha',
        emoji: ' ',
        dayIndex: 0,
        sortIndex: 5,
        creationDate: DateTime.now(),
        rootId: null,
      );
    },
    growable: false,
  );

  // syncBenchmark(
  //   'update minds in repository',
  //   settings: const BenchmarkSettings(minimumRunTime: Duration(seconds: 1)),
  //   () async {
  //     await repository.updateMinds(minds: minds);
  //   },
  // ).report();

  // syncBenchmark(
  //   'obtrain minds from repository',
  //   settings: const BenchmarkSettings(minimumRunTime: Duration(seconds: 1)),
  //   () async {
  //     await repository.obtainMinds();
  //   },
  // ).report();

  await Hive.deleteFromDisk();
  if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
}
