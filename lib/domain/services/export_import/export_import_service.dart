import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:encrypt/encrypt.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/domain/services/export_import/models/export_result.dart';
import 'package:keklist/domain/services/export_import/models/import_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;

/// Service responsible for exporting and importing minds with audio files
/// Supports CSV, ZIP, and encrypted ZIP formats with AES-256 encryption
class ExportImportService {
  final MindRepository _mindRepository;
  final AppFileRepository _fileRepository;

  const ExportImportService({required MindRepository mindRepository, required AppFileRepository fileRepository})
    : _mindRepository = mindRepository,
      _fileRepository = fileRepository;

  // Encryption constants
  static const int _saltLength = 16;
  static const int _ivLength = 16;
  static const int _pbkdf2Iterations = 10000;

  /// Export minds to CSV file (backward compatibility)
  Future<ExportResult> exportToCSV() async {
    try {
      final minds = _mindRepository.values.toList();

      if (minds.isEmpty) {
        return const ExportFailure(error: ExportError.noMindsToExport, details: 'No minds available to export');
      }

      // Convert to CSV
      final csvEntryList = minds.map((mind) => mind.toCSVEntry()).toList();
      final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(csvEntryList);

      // Write to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${tempDir.path}/keklist_export_$timestamp.csv');
      await file.writeAsString(csv);

      return ExportSuccess(file: file, mindsCount: minds.length, audioFilesCount: 0, isEncrypted: false);
    } catch (e) {
      return ExportFailure(
        error: ExportError.fileCreationFailed,
        details: 'Failed to create CSV file: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Export minds to ZIP archive with audio files
  /// If password is provided, the ZIP will be encrypted with AES-256
  Future<ExportResult> exportToZIP({String? password}) async {
    try {
      final minds = _mindRepository.values.toList();

      if (minds.isEmpty) {
        return const ExportFailure(error: ExportError.noMindsToExport, details: 'No minds available to export');
      }

      // Create CSV content
      final csvEntryList = minds.map((mind) => mind.toCSVEntry()).toList();
      final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(csvEntryList);

      // Collect unique audio files
      final audioFiles = <String>{}; // Use Set to avoid duplicates
      final missingAudioFiles = <String>[];

      for (final mind in minds) {
        final noteContent = MindNoteContent.parse(mind.note);
        for (final audioPiece in noteContent.audioPieces) {
          audioFiles.add(audioPiece.appRelativeAbsoulutePath);
        }
      }

      // Create archive
      final archive = Archive();

      // Add minds.csv to root
      archive.addFile(ArchiveFile('minds.csv', csv.length, utf8.encode(csv)));

      // Add audio files
      int successfulAudioCount = 0;
      for (final relativePath in audioFiles) {
        try {
          final absolutePath = await _fileRepository.resolveAbsolutePath(relativePath);
          final file = File(absolutePath);

          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            // Extract just the filename from the relative path (e.g., "audio/uuid.m4a" -> "uuid.m4a")
            final fileName = relativePath.split('/').last;
            archive.addFile(ArchiveFile('audio/$fileName', bytes.length, bytes));
            successfulAudioCount++;
          } else {
            missingAudioFiles.add(relativePath);
          }
        } catch (e) {
          missingAudioFiles.add(relativePath);
        }
      }

      // Encode archive to bytes
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      // Encrypt if password provided
      // Always use .zip extension - encryption is detected automatically during import
      final Uint8List finalBytes;
      final bool isEncrypted;

      if (password != null && password.isNotEmpty) {
        finalBytes = await _encryptBytes(Uint8List.fromList(zipBytes), password);
        isEncrypted = true;
      } else {
        finalBytes = Uint8List.fromList(zipBytes);
        isEncrypted = false;
      }

      // Write to file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${tempDir.path}/keklist_export_$timestamp.zip');
      await file.writeAsBytes(finalBytes);

      return ExportSuccess(
        file: file,
        mindsCount: minds.length,
        audioFilesCount: successfulAudioCount,
        missingAudioFiles: missingAudioFiles,
        isEncrypted: isEncrypted,
      );
    } catch (e) {
      return ExportFailure(
        error: ExportError.unknownError,
        details: 'Export failed: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Import minds from a file (CSV, ZIP, or encrypted ZIP)
  /// Automatically detects file format
  Future<ImportResult> importFromFile(File file, {String? password}) async {
    try {
      if (!await file.exists()) {
        return const ImportFailure(error: ImportError.corruptedFile, details: 'File does not exist');
      }

      final fileName = file.path.toLowerCase();

      // Detect file type by extension
      if (fileName.endsWith('.csv')) {
        return await _importFromCSV(file);
      } else if (fileName.endsWith('.zip')) {
        return await _importFromZIP(file, password: password);
      } else {
        // Try to detect by content
        final bytes = await file.readAsBytes();

        // Check if it's a ZIP file (starts with PK magic number)
        if (bytes.length > 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
          return await _importFromZIP(file, password: password);
        }

        // Try as CSV
        try {
          return await _importFromCSV(file);
        } catch (e) {
          return const ImportFailure(
            error: ImportError.invalidFormat,
            details: 'Could not detect file format. Expected CSV or ZIP.',
          );
        }
      }
    } catch (e) {
      return ImportFailure(
        error: ImportError.unknownError,
        details: 'Import failed: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Import from CSV file (backward compatibility)
  Future<ImportResult> _importFromCSV(File file) async {
    try {
      final csvContent = await file.readAsString();

      if (csvContent.trim().isEmpty) {
        return const ImportFailure(error: ImportError.invalidFormat, details: 'CSV file is empty');
      }

      final rawRows = const CsvToListConverter(fieldDelimiter: ';', shouldParseNumbers: false).convert(csvContent);

      if (rawRows.isEmpty) {
        return const ImportFailure(error: ImportError.invalidFormat, details: 'No data found in CSV file');
      }

      final mindsToImport = <Mind>[];

      for (final row in rawRows) {
        if (row.length < 7) {
          continue; // Skip invalid rows
        }

        try {
          final mind = Mind(
            id: row[0].toString(),
            emoji: row[1].toString(),
            note: row[2].toString(),
            dayIndex: int.parse(row[3].toString()),
            sortIndex: int.parse(row[4].toString()),
            creationDate: DateTime.parse(row[5].toString()),
            rootId: row[6].toString() == 'null' ? null : row[6].toString(),
          );
          mindsToImport.add(mind);
        } catch (e) {
          // Skip invalid rows
          continue;
        }
      }

      if (mindsToImport.isEmpty) {
        return const ImportFailure(error: ImportError.invalidFormat, details: 'No valid minds found in CSV file');
      }

      // Batch import
      await _mindRepository.createMinds(minds: mindsToImport);

      return ImportSuccess(mindsCount: mindsToImport.length, audioFilesCount: 0);
    } catch (e) {
      return ImportFailure(
        error: ImportError.corruptedFile,
        details: 'Failed to parse CSV file: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Import from ZIP or encrypted ZIP file
  Future<ImportResult> _importFromZIP(File file, {String? password}) async {
    Directory? tempExtractDir;

    try {
      final fileBytes = await file.readAsBytes();
      Uint8List zipBytes;

      // Check if file is encrypted (doesn't start with PK magic number)
      final isEncrypted = !(fileBytes.length > 2 && fileBytes[0] == 0x50 && fileBytes[1] == 0x4B);

      if (isEncrypted) {
        if (password == null || password.isEmpty) {
          return const ImportFailure(
            error: ImportError.invalidPassword,
            details: 'This file is password-protected. Please provide a password.',
          );
        }

        // Decrypt
        try {
          zipBytes = await _decryptBytes(fileBytes, password);
        } catch (e) {
          return ImportFailure(
            error: ImportError.invalidPassword,
            details: 'Failed to decrypt file. Please check your password.',
            exception: e is Exception ? e : Exception(e.toString()),
          );
        }
      } else {
        zipBytes = fileBytes;
      }

      // Decode ZIP archive
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(zipBytes);
      } catch (e) {
        return ImportFailure(
          error: ImportError.corruptedFile,
          details: 'Failed to extract ZIP archive: $e',
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }

      // Validate archive structure
      final mindsFile = archive.firstWhere(
        (file) => file.name == 'minds.csv',
        orElse: () => throw Exception('minds.csv not found'),
      );

      // Extract to temporary directory
      final tempDir = await getTemporaryDirectory();
      tempExtractDir = Directory('${tempDir.path}/keklist_import_${DateTime.now().millisecondsSinceEpoch}');
      await tempExtractDir.create(recursive: true);

      // Extract archive
      for (final file in archive) {
        final filePath = '${tempExtractDir.path}/${file.name}';
        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }

      // Parse CSV
      final csvContent = utf8.decode(mindsFile.content as List<int>);
      final rawRows = const CsvToListConverter(fieldDelimiter: ';', shouldParseNumbers: false).convert(csvContent);

      final mindsToImport = <Mind>[];

      for (final row in rawRows) {
        if (row.length < 7) continue;

        try {
          final mind = Mind(
            id: row[0].toString(),
            emoji: row[1].toString(),
            note: row[2].toString(),
            dayIndex: int.parse(row[3].toString()),
            sortIndex: int.parse(row[4].toString()),
            creationDate: DateTime.parse(row[5].toString()),
            rootId: row[6].toString() == 'null' ? null : row[6].toString(),
          );
          mindsToImport.add(mind);
        } catch (e) {
          continue;
        }
      }

      if (mindsToImport.isEmpty) {
        return const ImportFailure(error: ImportError.invalidFormat, details: 'No valid minds found in archive');
      }

      // Copy audio files to app directory
      final audioDir = Directory('${tempExtractDir.path}/audio');
      int audioFilesCopied = 0;
      final skippedAudioFiles = <String>[];

      if (await audioDir.exists()) {
        final audioFiles = await audioDir.list().where((entity) => entity is File).cast<File>().toList();

        for (final audioFile in audioFiles) {
          final fileName = audioFile.path.split('/').last;
          final relativePath = 'audio/$fileName';
          final targetPath = await _fileRepository.resolveAbsolutePath(relativePath);
          final targetFile = File(targetPath);

          // Skip if file already exists
          if (await targetFile.exists()) {
            skippedAudioFiles.add(fileName);
            continue;
          }

          // Ensure parent directory exists
          await targetFile.parent.create(recursive: true);

          // Copy file
          await audioFile.copy(targetPath);
          audioFilesCopied++;
        }
      }

      // Import minds
      await _mindRepository.createMinds(minds: mindsToImport);

      // Cleanup
      await tempExtractDir.delete(recursive: true);

      return ImportSuccess(
        mindsCount: mindsToImport.length,
        audioFilesCount: audioFilesCopied,
        skippedAudioFiles: skippedAudioFiles,
      );
    } catch (e) {
      // Cleanup on error
      if (tempExtractDir != null && await tempExtractDir.exists()) {
        await tempExtractDir.delete(recursive: true);
      }

      if (e.toString().contains('minds.csv not found')) {
        return const ImportFailure(
          error: ImportError.invalidArchiveStructure,
          details: 'Archive is missing minds.csv file',
        );
      }

      return ImportFailure(
        error: ImportError.unknownError,
        details: 'Failed to import from ZIP: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Encrypt bytes using AES-256-CBC with PBKDF2 key derivation
  /// Format: [16B salt][16B IV][encrypted data]
  Future<Uint8List> _encryptBytes(Uint8List data, String password) async {
    try {
      // Generate random salt and IV
      final salt = _generateRandomBytes(_saltLength);
      final iv = _generateRandomBytes(_ivLength);

      // Derive key from password using PBKDF2
      final key = _deriveKey(password, salt);

      // Encrypt data
      final encrypter = Encrypter(AES(Key(key), mode: AESMode.cbc));
      final encrypted = encrypter.encryptBytes(data, iv: IV(iv));

      // Combine salt + IV + encrypted data
      final result = Uint8List(salt.length + iv.length + encrypted.bytes.length);
      result.setRange(0, salt.length, salt);
      result.setRange(salt.length, salt.length + iv.length, iv);
      result.setRange(salt.length + iv.length, result.length, encrypted.bytes);

      return result;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt bytes encrypted with _encryptBytes
  Future<Uint8List> _decryptBytes(Uint8List data, String password) async {
    try {
      if (data.length < _saltLength + _ivLength) {
        throw Exception('Invalid encrypted data format');
      }

      // Extract salt and IV
      final salt = data.sublist(0, _saltLength);
      final iv = data.sublist(_saltLength, _saltLength + _ivLength);
      final encryptedData = data.sublist(_saltLength + _ivLength);

      // Derive key from password using same salt
      final key = _deriveKey(password, salt);

      // Decrypt data
      final encrypter = Encrypter(AES(Key(key), mode: AESMode.cbc));
      final decrypted = encrypter.decryptBytes(Encrypted(encryptedData), iv: IV(iv));

      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Derive encryption key from password using PBKDF2
  Uint8List _deriveKey(String password, Uint8List salt) {
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, _pbkdf2Iterations, 32));

    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = pc.SecureRandom('Fortuna');
    final seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = DateTime.now().millisecondsSinceEpoch % 256;
    }
    random.seed(pc.KeyParameter(seed));

    return random.nextBytes(length);
  }
}
