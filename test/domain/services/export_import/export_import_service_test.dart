import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/export_import/export_import_service.dart';
import 'package:keklist/domain/services/export_import/models/export_result.dart';
import 'package:keklist/domain/services/export_import/models/import_result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockMindRepository extends Mock implements MindRepository {}

class MockAppFileRepository extends Mock implements AppFileRepository {}

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => _tempPath;

  String? _tempPath;

  void setTempPath(String path) {
    _tempPath = path;
  }
}

void main() {
  late MockMindRepository mockMindRepository;
  late MockAppFileRepository mockFileRepository;
  late ExportImportService service;
  late Directory tempDir;

  setUpAll(() {
    // Register fallback values for any() matchers
    registerFallbackValue(Mind(
      id: 'test',
      emoji: '😀',
      note: 'test',
      dayIndex: 0,
      creationDate: DateTime.now(),
      sortIndex: 0,
      rootId: null,
    ));
  });

  setUp(() async {
    mockMindRepository = MockMindRepository();
    mockFileRepository = MockAppFileRepository();
    service = ExportImportService(
      mindRepository: mockMindRepository,
      fileRepository: mockFileRepository,
    );

    // Setup temp directory for tests
    tempDir = await Directory.systemTemp.createTemp('export_import_test_');

    // Mock path provider
    final mockPathProvider = MockPathProviderPlatform();
    mockPathProvider.setTempPath(tempDir.path);
    PathProviderPlatform.instance = mockPathProvider;
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExportImportService - CSV Export', () {
    test('exportToCSV creates valid CSV file with minds', () async {
      // Arrange
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test note 1',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
        Mind(
          id: '2',
          emoji: '😎',
          note: 'Test note 2',
          dayIndex: 101,
          creationDate: DateTime(2024, 1, 2),
          sortIndex: 1,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);

      // Act
      final result = await service.exportToCSV();

      // Assert
      expect(result, isA<ExportSuccess>());
      final success = result as ExportSuccess;
      expect(success.mindsCount, 2);
      expect(success.audioFilesCount, 0);
      expect(success.isEncrypted, false);
      expect(success.file.existsSync(), true);
      expect(success.file.path.endsWith('.csv'), true);

      // Verify CSV content
      final csvContent = await success.file.readAsString();
      expect(csvContent.contains('Test note 1'), true);
      expect(csvContent.contains('Test note 2'), true);
    });

    test('exportToCSV returns error when no minds available', () async {
      // Arrange
      when(() => mockMindRepository.values).thenReturn([]);

      // Act
      final result = await service.exportToCSV();

      // Assert
      expect(result, isA<ExportFailure>());
      final failure = result as ExportFailure;
      expect(failure.error, ExportError.noMindsToExport);
    });
  });

  group('ExportImportService - ZIP Export', () {
    test('exportToZIP creates unencrypted ZIP without password', () async {
      // Arrange
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test note without audio',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);

      // Act
      final result = await service.exportToZIP(password: null);

      // Assert
      expect(result, isA<ExportSuccess>());
      final success = result as ExportSuccess;
      expect(success.mindsCount, 1);
      expect(success.isEncrypted, false);
      expect(success.file.existsSync(), true);
      expect(success.file.path.endsWith('.zip'), true);
    });

    test('exportToZIP creates encrypted ZIP with password', () async {
      // Arrange
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test note',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);

      // Act
      final result = await service.exportToZIP(password: 'test123');

      // Assert
      expect(result, isA<ExportSuccess>());
      final success = result as ExportSuccess;
      expect(success.mindsCount, 1);
      expect(success.isEncrypted, true);
      expect(success.file.existsSync(), true);
      expect(success.file.path.endsWith('.encrypted'), true);
    });

    test('exportToZIP includes audio files in archive', () async {
      // Arrange
      final audioFilePath = '${tempDir.path}/test_audio.m4a';
      final audioFile = File(audioFilePath);
      await audioFile.writeAsBytes([1, 2, 3, 4]); // Dummy audio data

      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test <kekaudio path="audio/test_audio.m4a" duration="5.5"/>',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);
      when(() => mockFileRepository.resolveAbsolutePath('audio/test_audio.m4a'))
          .thenAnswer((_) async => audioFilePath);

      // Act
      final result = await service.exportToZIP(password: null);

      // Assert
      expect(result, isA<ExportSuccess>());
      final success = result as ExportSuccess;
      expect(success.mindsCount, 1);
      expect(success.audioFilesCount, 1);
    });

    test('exportToZIP handles missing audio files gracefully', () async {
      // Arrange
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test <kekaudio path="audio/missing.m4a" duration="5.5"/>',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);
      when(() => mockFileRepository.resolveAbsolutePath('audio/missing.m4a'))
          .thenAnswer((_) async => '${tempDir.path}/missing.m4a');

      // Act
      final result = await service.exportToZIP(password: null);

      // Assert
      expect(result, isA<ExportSuccess>());
      final success = result as ExportSuccess;
      expect(success.mindsCount, 1);
      expect(success.audioFilesCount, 0);
      expect(success.missingAudioFiles, contains('audio/missing.m4a'));
    });

    test('exportToZIP treats empty password as no encryption', () async {
      // Arrange
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);

      // Act
      final result = await service.exportToZIP(password: '');

      // Assert
      expect(result, isA<ExportSuccess>());
      final success = result as ExportSuccess;
      expect(success.isEncrypted, false);
      expect(success.file.path.endsWith('.zip'), true);
    });
  });

  group('ExportImportService - CSV Import', () {
    test('importFromFile imports valid CSV file', () async {
      // Arrange
      final csvFile = File('${tempDir.path}/test.csv');
      await csvFile.writeAsString(
        '1;😀;Test note;100;0;2024-01-01 00:00:00.000;null\n'
        '2;😎;Another note;101;1;2024-01-02 00:00:00.000;null',
      );

      when(() => mockMindRepository.createMinds(minds: any(named: 'minds')))
          .thenAnswer((_) async {});

      // Act
      final result = await service.importFromFile(csvFile);

      // Assert
      expect(result, isA<ImportSuccess>());
      final success = result as ImportSuccess;
      expect(success.mindsCount, 2);
      expect(success.audioFilesCount, 0);

      verify(() => mockMindRepository.createMinds(minds: any(named: 'minds'))).called(1);
    });

    test('importFromFile handles empty CSV file', () async {
      // Arrange
      final csvFile = File('${tempDir.path}/empty.csv');
      await csvFile.writeAsString('');

      // Act
      final result = await service.importFromFile(csvFile);

      // Assert
      expect(result, isA<ImportFailure>());
      final failure = result as ImportFailure;
      expect(failure.error, ImportError.invalidFormat);
    });

    test('importFromFile fails when CSV has no valid rows', () async {
      // Arrange
      final csvFile = File('${tempDir.path}/invalid.csv');
      await csvFile.writeAsString(
        'invalid;row;with;not;enough;fields\n'
        'also;invalid;row\n',
      );

      // Act
      final result = await service.importFromFile(csvFile);

      // Assert
      expect(result, isA<ImportFailure>());
      final failure = result as ImportFailure;
      expect(failure.error, ImportError.invalidFormat);

      verifyNever(() => mockMindRepository.createMinds(minds: any(named: 'minds')));
    });

    test('importFromFile skips invalid CSV rows', () async {
      // Arrange
      final csvFile = File('${tempDir.path}/partial.csv');
      await csvFile.writeAsString(
        '1;😀;Test note;100;0;2024-01-01 00:00:00.000;null\n'
        'invalid;row;with;not;enough;fields\n'
        '2;😎;Another note;101;1;2024-01-02 00:00:00.000;null',
      );

      when(() => mockMindRepository.createMinds(minds: any(named: 'minds')))
          .thenAnswer((_) async {});

      // Act
      final result = await service.importFromFile(csvFile);

      // Assert
      expect(result, isA<ImportSuccess>());
      final success = result as ImportSuccess;
      expect(success.mindsCount, 2); // Only valid rows imported
    });
  });

  group('ExportImportService - ZIP Import', () {
    test('importFromFile imports unencrypted ZIP', () async {
      // Arrange - First export to create a valid ZIP
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);
      when(() => mockMindRepository.createMinds(minds: any(named: 'minds')))
          .thenAnswer((_) async {});

      final exportResult = await service.exportToZIP(password: null);
      expect(exportResult, isA<ExportSuccess>());
      final exportFile = (exportResult as ExportSuccess).file;

      // Act - Import the exported file
      final result = await service.importFromFile(exportFile);

      // Assert
      expect(result, isA<ImportSuccess>());
      final success = result as ImportSuccess;
      expect(success.mindsCount, 1);
    });

    test('importFromFile imports encrypted ZIP with correct password', () async {
      // Arrange - First export with password
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);
      when(() => mockMindRepository.createMinds(minds: any(named: 'minds')))
          .thenAnswer((_) async {});

      final exportResult = await service.exportToZIP(password: 'test123');
      expect(exportResult, isA<ExportSuccess>());
      final exportFile = (exportResult as ExportSuccess).file;

      // Act - Import with correct password
      final result = await service.importFromFile(exportFile, password: 'test123');

      // Assert
      expect(result, isA<ImportSuccess>());
      final success = result as ImportSuccess;
      expect(success.mindsCount, 1);
    });

    test('importFromFile fails with wrong password', () async {
      // Arrange - First export with password
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);

      final exportResult = await service.exportToZIP(password: 'test123');
      expect(exportResult, isA<ExportSuccess>());
      final exportFile = (exportResult as ExportSuccess).file;

      // Act - Import with wrong password
      final result = await service.importFromFile(exportFile, password: 'wrong');

      // Assert
      expect(result, isA<ImportFailure>());
      final failure = result as ImportFailure;
      expect(failure.error, ImportError.invalidPassword);
    });

    test('importFromFile fails when password required but not provided', () async {
      // Arrange - First export with password
      final minds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(minds);

      final exportResult = await service.exportToZIP(password: 'test123');
      expect(exportResult, isA<ExportSuccess>());
      final exportFile = (exportResult as ExportSuccess).file;

      // Act - Import without password
      final result = await service.importFromFile(exportFile, password: null);

      // Assert
      expect(result, isA<ImportFailure>());
      final failure = result as ImportFailure;
      expect(failure.error, ImportError.invalidPassword);
    });

    test('importFromFile handles non-existent file', () async {
      // Arrange
      final nonExistentFile = File('${tempDir.path}/nonexistent.zip');

      // Act
      final result = await service.importFromFile(nonExistentFile);

      // Assert
      expect(result, isA<ImportFailure>());
      final failure = result as ImportFailure;
      expect(failure.error, ImportError.corruptedFile);
    });
  });

  group('ExportImportService - Round Trip', () {
    test('export and import preserves all data without password', () async {
      // Arrange
      final originalMinds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test note 1',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
        Mind(
          id: '2',
          emoji: '😎',
          note: 'Test note 2',
          dayIndex: 101,
          creationDate: DateTime(2024, 1, 2),
          sortIndex: 1,
          rootId: '1',
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(originalMinds);

      List<Mind>? importedMinds;
      when(() => mockMindRepository.createMinds(minds: any(named: 'minds')))
          .thenAnswer((invocation) async {
        importedMinds = (invocation.namedArguments[#minds] as Iterable<Mind>).toList();
      });

      // Act - Export
      final exportResult = await service.exportToZIP(password: null);
      expect(exportResult, isA<ExportSuccess>());
      final exportFile = (exportResult as ExportSuccess).file;

      // Act - Import
      final importResult = await service.importFromFile(exportFile);
      expect(importResult, isA<ImportSuccess>());

      // Assert
      expect(importedMinds, isNotNull);
      expect(importedMinds!.length, 2);
      expect(importedMinds![0].id, '1');
      expect(importedMinds![0].emoji, '😀');
      expect(importedMinds![0].note, 'Test note 1');
      expect(importedMinds![1].id, '2');
      expect(importedMinds![1].rootId, '1');
    });

    test('export and import preserves all data with password', () async {
      // Arrange
      final originalMinds = [
        Mind(
          id: '1',
          emoji: '😀',
          note: 'Test note',
          dayIndex: 100,
          creationDate: DateTime(2024, 1, 1),
          sortIndex: 0,
          rootId: null,
        ),
      ];

      when(() => mockMindRepository.values).thenReturn(originalMinds);

      List<Mind>? importedMinds;
      when(() => mockMindRepository.createMinds(minds: any(named: 'minds')))
          .thenAnswer((invocation) async {
        importedMinds = (invocation.namedArguments[#minds] as Iterable<Mind>).toList();
      });

      // Act - Export with password
      final exportResult = await service.exportToZIP(password: 'test123');
      expect(exportResult, isA<ExportSuccess>());
      final exportFile = (exportResult as ExportSuccess).file;

      // Act - Import with same password
      final importResult = await service.importFromFile(exportFile, password: 'test123');
      expect(importResult, isA<ImportSuccess>());

      // Assert
      expect(importedMinds, isNotNull);
      expect(importedMinds!.length, 1);
      expect(importedMinds![0].id, originalMinds[0].id);
      expect(importedMinds![0].note, originalMinds[0].note);
    });
  });
}
