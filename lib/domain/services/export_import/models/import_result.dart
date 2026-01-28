/// Represents errors that can occur during import operations
enum ImportError {
  /// The provided password is incorrect
  invalidPassword,

  /// The file is corrupted or cannot be read
  corruptedFile,

  /// The file format is invalid or not supported
  invalidFormat,

  /// The archive structure is invalid (missing minds.csv, etc.)
  invalidArchiveStructure,

  /// Audio files referenced in minds but missing from archive
  missingAudioFiles,

  /// Not enough storage space to complete import
  insufficientStorage,

  /// Unknown or unexpected error occurred
  unknownError,
}

/// Extension to provide user-friendly messages for import errors
extension ImportErrorMessage on ImportError {
  String get message {
    switch (this) {
      case ImportError.invalidPassword:
        return 'Incorrect password. Please try again.';
      case ImportError.corruptedFile:
        return 'The file is corrupted and cannot be read.';
      case ImportError.invalidFormat:
        return 'Invalid file format. Expected CSV or ZIP file.';
      case ImportError.invalidArchiveStructure:
        return 'Invalid archive structure. Missing minds.csv file.';
      case ImportError.missingAudioFiles:
        return 'Some audio files are missing from the archive.';
      case ImportError.insufficientStorage:
        return 'Insufficient storage space to complete import.';
      case ImportError.unknownError:
        return 'An unexpected error occurred during import.';
    }
  }
}

/// Base class for import operation results
sealed class ImportResult {
  const ImportResult();
}

/// Successful import result with statistics
final class ImportSuccess extends ImportResult {
  /// Number of minds imported
  final int mindsCount;

  /// Number of audio files imported
  final int audioFilesCount;

  /// List of audio file names that were skipped (already existed)
  final List<String> skippedAudioFiles;

  const ImportSuccess({
    required this.mindsCount,
    required this.audioFilesCount,
    this.skippedAudioFiles = const [],
  });

  @override
  String toString() {
    return 'ImportSuccess(mindsCount: $mindsCount, audioFilesCount: $audioFilesCount, skippedAudioFiles: ${skippedAudioFiles.length})';
  }
}

/// Failed import result with error information
final class ImportFailure extends ImportResult {
  /// The type of error that occurred
  final ImportError error;

  /// Optional detailed error message
  final String? details;

  /// Optional exception that caused the failure
  final Exception? exception;

  const ImportFailure({
    required this.error,
    this.details,
    this.exception,
  });

  /// Get user-friendly error message
  String get message => details ?? error.message;

  @override
  String toString() {
    return 'ImportFailure(error: $error, details: $details)';
  }
}
