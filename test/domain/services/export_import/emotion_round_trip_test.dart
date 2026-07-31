import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/repositories/emotion/emotion_repository.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/export_import/export_import_service.dart';
import 'package:keklist/domain/services/export_import/models/export_result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockMindRepository extends Mock implements MindRepository {}

class MockAppFileRepository extends Mock implements AppFileRepository {}

class MockEmotionRepository extends Mock implements EmotionRepository {}

class MockPathProviderPlatform extends PathProviderPlatform {
  String? tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

Emotion _emotion({
  required String id,
  required String title,
  String emoji = '🙂',
  String? parentId,
}) =>
    Emotion(
      id: id,
      title: title,
      emoji: emoji,
      parentId: parentId,
      isArchived: false,
      orderIndex: 0,
      creationDate: DateTime.utc(2026),
    );

Mind _mind({required String id, List<String> emotionIds = const []}) => Mind(
      id: id,
      emoji: '😀',
      note: 'note $id',
      dayIndex: 1,
      creationDate: DateTime.utc(2026),
      sortIndex: 0,
      rootId: null,
      emotionIds: emotionIds,
    );

void main() {
  late MockMindRepository mindRepository;
  late MockAppFileRepository fileRepository;
  late MockEmotionRepository emotionRepository;
  late ExportImportService service;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(_mind(id: 'fallback'));
    registerFallbackValue(<Emotion>[]);
  });

  setUp(() async {
    mindRepository = MockMindRepository();
    fileRepository = MockAppFileRepository();
    emotionRepository = MockEmotionRepository();
    service = ExportImportService(
      mindRepository: mindRepository,
      fileRepository: fileRepository,
      emotionRepository: emotionRepository,
    );

    tempDir = await Directory.systemTemp.createTemp('emotion_round_trip_');
    PathProviderPlatform.instance = MockPathProviderPlatform()..tempPath = tempDir.path;

    when(() => mindRepository.createMinds(minds: any(named: 'minds'))).thenAnswer((_) async {});
    when(() => emotionRepository.createEmotions(emotions: any(named: 'emotions'))).thenAnswer((_) async {});
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Exports the given state to a ZIP, then imports it back against whatever the
  /// repositories are currently mocked to hold.
  Future<File> exportZip({required List<Mind> minds, required List<Emotion> emotions}) async {
    when(() => mindRepository.values).thenReturn(minds);
    when(() => emotionRepository.values).thenReturn(emotions);
    final result = await service.exportToZIP();
    expect(result, isA<ExportSuccess>(), reason: 'export should succeed');
    return (result as ExportSuccess).file;
  }

  List<Mind> capturedImportedMinds() =>
      verify(() => mindRepository.createMinds(minds: captureAny(named: 'minds'))).captured.single as List<Mind>;

  group('CSV column compatibility', () {
    test('emotion ids survive a toCSVEntry round-trip', () {
      final row = _mind(id: 'm1', emotionIds: ['a', 'b']).toCSVEntry();
      expect(row.length, 8);
      expect(Mind.emotionIdsFromCSVEntry(row), ['a', 'b']);
    });

    test('a legacy 7-column row yields no emotions instead of throwing', () {
      final legacy = _mind(id: 'm1', emotionIds: ['a']).toCSVEntry().sublist(0, 7);
      expect(Mind.emotionIdsFromCSVEntry(legacy), isEmpty);
    });

    test('a mind with no tags produces an empty trailing field', () {
      expect(Mind.emotionIdsFromCSVEntry(_mind(id: 'm1').toCSVEntry()), isEmpty);
    });
  });

  group('ZIP round-trip', () {
    test('tags and definitions survive an import onto an empty device', () async {
      final joy = _emotion(id: 'e-joy', title: 'Joy');
      final file = await exportZip(minds: [_mind(id: 'm1', emotionIds: ['e-joy'])], emotions: [joy]);

      // Fresh device: nothing stored locally.
      when(() => emotionRepository.values).thenReturn(const []);
      await service.importFromFile(file);

      final created = verify(
        () => emotionRepository.createEmotions(emotions: captureAny(named: 'emotions')),
      ).captured.single as List<Emotion>;
      expect(created.map((e) => e.id), ['e-joy']);
      expect(capturedImportedMinds().single.emotionIds, ['e-joy']);
    });

    test('re-importing onto an identical device creates nothing', () async {
      final joy = _emotion(id: 'e-joy', title: 'Joy');
      final file = await exportZip(minds: [_mind(id: 'm1', emotionIds: ['e-joy'])], emotions: [joy]);

      // Same device: the identical definition is already present.
      when(() => emotionRepository.values).thenReturn([joy]);
      await service.importFromFile(file);

      verifyNever(() => emotionRepository.createEmotions(emotions: any(named: 'emotions')));
      expect(capturedImportedMinds().single.emotionIds, ['e-joy']);
    });

    test('a changed definition clones under a new id and remaps the tag', () async {
      final incoming = _emotion(id: 'e-joy', title: 'Joy');
      final file = await exportZip(minds: [_mind(id: 'm1', emotionIds: ['e-joy'])], emotions: [incoming]);

      // Local row shares the id but was renamed since the export.
      when(() => emotionRepository.values).thenReturn([_emotion(id: 'e-joy', title: 'Renamed')]);
      await service.importFromFile(file);

      final created = verify(
        () => emotionRepository.createEmotions(emotions: captureAny(named: 'emotions')),
      ).captured.single as List<Emotion>;
      expect(created.single.title, 'Joy');
      expect(created.single.id, isNot('e-joy'), reason: 'conflicting definition must clone');

      final importedTag = capturedImportedMinds().single.emotionIds.single;
      expect(importedTag, created.single.id, reason: 'tag must follow the clone, not the local row');
    });

    test('a cloned parent takes its children with it', () async {
      final parent = _emotion(id: 'e-parent', title: 'Parent');
      final child = _emotion(id: 'e-child', title: 'Child', parentId: 'e-parent');
      final file = await exportZip(minds: [_mind(id: 'm1')], emotions: [parent, child]);

      // Parent conflicts; child does not exist locally.
      when(() => emotionRepository.values).thenReturn([_emotion(id: 'e-parent', title: 'Different')]);
      await service.importFromFile(file);

      final created = verify(
        () => emotionRepository.createEmotions(emotions: captureAny(named: 'emotions')),
      ).captured.single as List<Emotion>;
      final clonedParent = created.firstWhere((e) => e.title == 'Parent');
      final importedChild = created.firstWhere((e) => e.title == 'Child');
      expect(importedChild.parentId, clonedParent.id,
          reason: 'child must follow the cloned parent or it becomes an invisible orphan');
    });

    test('an archive without emotions.csv still imports its minds', () async {
      // No emotions exported at all, so the entry is absent.
      final file = await exportZip(minds: [_mind(id: 'm1', emotionIds: ['gone'])], emotions: const []);

      when(() => emotionRepository.values).thenReturn(const []);
      await service.importFromFile(file);

      verifyNever(() => emotionRepository.createEmotions(emotions: any(named: 'emotions')));
      // Ids are kept verbatim when no remap applies — dangling, as before.
      expect(capturedImportedMinds().single.emotionIds, ['gone']);
    });

    test('archived emotions are exported so tagged minds keep resolving', () async {
      final archived = Emotion(
        id: 'e-old',
        title: 'Old',
        emoji: '🙂',
        parentId: null,
        isArchived: true,
        orderIndex: 3,
        creationDate: DateTime.utc(2026),
      );
      final file = await exportZip(minds: [_mind(id: 'm1', emotionIds: ['e-old'])], emotions: [archived]);

      when(() => emotionRepository.values).thenReturn(const []);
      await service.importFromFile(file);

      final created = verify(
        () => emotionRepository.createEmotions(emotions: captureAny(named: 'emotions')),
      ).captured.single as List<Emotion>;
      expect(created.single.isArchived, isTrue);
      expect(created.single.orderIndex, 3);
    });
  });
}
