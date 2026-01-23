import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/export_import/export_import_service.dart';
import 'package:keklist/domain/services/export_import/models/export_result.dart';
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

  setUp(() async {
    mockMindRepository = MockMindRepository();
    mockFileRepository = MockAppFileRepository();
    service = ExportImportService(
      mindRepository: mockMindRepository,
      fileRepository: mockFileRepository,
    );

    // Setup temp directory for tests
    tempDir = await Directory.systemTemp.createTemp('native_unzip_test_');

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

  test('exported ZIP can be extracted using native macOS unzip command', () async {
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
      Mind(
        id: '2',
        emoji: '😎',
        note: 'Another test note',
        dayIndex: 101,
        creationDate: DateTime(2024, 1, 2),
        sortIndex: 1,
        rootId: null,
      ),
    ];

    when(() => mockMindRepository.values).thenReturn(minds);

    // Act - Export to ZIP
    final exportResult = await service.exportToZIP(password: null);
    expect(exportResult, isA<ExportSuccess>());
    final exportFile = (exportResult as ExportSuccess).file;

    print('Exported ZIP file: ${exportFile.path}');
    print('File size: ${await exportFile.length()} bytes');

    // Try to extract using native unzip command
    final extractDir = Directory('${tempDir.path}/extracted');
    await extractDir.create();

    final unzipResult = await Process.run(
      'unzip',
      ['-t', exportFile.path], // Test archive integrity
      workingDirectory: tempDir.path,
    );

    print('unzip test stdout: ${unzipResult.stdout}');
    print('unzip test stderr: ${unzipResult.stderr}');
    print('unzip test exit code: ${unzipResult.exitCode}');

    // Assert - unzip should succeed (exit code 0)
    expect(unzipResult.exitCode, 0, reason: 'Native unzip command should succeed');

    // Now actually extract the files
    final extractResult = await Process.run(
      'unzip',
      ['-o', exportFile.path, '-d', extractDir.path],
      workingDirectory: tempDir.path,
    );

    print('unzip extract stdout: ${extractResult.stdout}');
    print('unzip extract stderr: ${extractResult.stderr}');
    print('unzip extract exit code: ${extractResult.exitCode}');

    expect(extractResult.exitCode, 0, reason: 'Native unzip extraction should succeed');

    // Verify extracted files exist
    final mindsFile = File('${extractDir.path}/minds.csv');
    expect(await mindsFile.exists(), true, reason: 'minds.csv should be extracted');

    // Verify content
    final csvContent = await mindsFile.readAsString();
    expect(csvContent.contains('Test note without audio'), true);
    expect(csvContent.contains('Another test note'), true);
  });

  test('exported ZIP with audio files can be extracted using native macOS unzip', () async {
    // Arrange - Create dummy audio file
    final audioFilePath = '${tempDir.path}/test_audio.m4a';
    final audioFile = File(audioFilePath);
    await audioFile.writeAsBytes([0xFF, 0xF1, 0x50, 0x80, 0x01, 0x3F, 0xFC]); // Dummy audio data

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

    // Act - Export to ZIP with audio
    final exportResult = await service.exportToZIP(password: null);
    expect(exportResult, isA<ExportSuccess>());
    final exportFile = (exportResult as ExportSuccess).file;

    print('Exported ZIP file: ${exportFile.path}');
    print('File size: ${await exportFile.length()} bytes');

    // Try to extract using native unzip command
    final extractDir = Directory('${tempDir.path}/extracted');
    await extractDir.create();

    final unzipResult = await Process.run(
      'unzip',
      ['-t', exportFile.path], // Test archive integrity
      workingDirectory: tempDir.path,
    );

    print('unzip test stdout: ${unzipResult.stdout}');
    print('unzip test stderr: ${unzipResult.stderr}');
    print('unzip test exit code: ${unzipResult.exitCode}');

    // Assert - unzip should succeed (exit code 0)
    expect(unzipResult.exitCode, 0, reason: 'Native unzip command should succeed');

    // Now actually extract the files
    final extractResult = await Process.run(
      'unzip',
      ['-o', exportFile.path, '-d', extractDir.path],
      workingDirectory: tempDir.path,
    );

    print('unzip extract stdout: ${extractResult.stdout}');
    print('unzip extract stderr: ${extractResult.stderr}');
    print('unzip extract exit code: ${extractResult.exitCode}');

    expect(extractResult.exitCode, 0, reason: 'Native unzip extraction should succeed');

    // Verify extracted files exist
    final mindsFile = File('${extractDir.path}/minds.csv');
    expect(await mindsFile.exists(), true, reason: 'minds.csv should be extracted');

    // Verify audio directory and file
    final audioDir = Directory('${extractDir.path}/audio');
    expect(await audioDir.exists(), true, reason: 'audio directory should be extracted');

    final extractedAudioFile = File('${extractDir.path}/audio/test_audio.m4a');
    expect(await extractedAudioFile.exists(), true, reason: 'audio file should be extracted');

    // Verify audio file content
    final audioBytes = await extractedAudioFile.readAsBytes();
    expect(audioBytes, [0xFF, 0xF1, 0x50, 0x80, 0x01, 0x3F, 0xFC], reason: 'Audio file content should match');

    // Verify CSV content
    final csvContent = await mindsFile.readAsString();
    expect(csvContent.contains('kekaudio'), true);
  });

  test('exported ZIP can be extracted using macOS Archive Utility (ditto)', () async {
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

    // Act - Export to ZIP
    final exportResult = await service.exportToZIP(password: null);
    expect(exportResult, isA<ExportSuccess>());
    final exportFile = (exportResult as ExportSuccess).file;

    print('Exported ZIP file for ditto: ${exportFile.path}');

    // Try to extract using ditto (macOS Archive Utility backend)
    final extractDir = Directory('${tempDir.path}/ditto_extracted');
    await extractDir.create();

    final dittoResult = await Process.run(
      'ditto',
      ['-x', '-k', exportFile.path, extractDir.path],
    );

    print('ditto stdout: ${dittoResult.stdout}');
    print('ditto stderr: ${dittoResult.stderr}');
    print('ditto exit code: ${dittoResult.exitCode}');

    // Assert
    expect(dittoResult.exitCode, 0, reason: 'ditto (Archive Utility) should succeed');

    // Verify extracted file
    final mindsFile = File('${extractDir.path}/minds.csv');
    expect(await mindsFile.exists(), true, reason: 'minds.csv should be extracted by ditto');
  });
}
