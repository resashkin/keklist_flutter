import 'dart:io';

/// Represents errors that can occur during export operations
enum ExportError {
  /// No minds available to export
  noMindsToExport,

  /// Failed to create or write to export file
  fileCreationFailed,

  /// Failed to access audio files
  audioAccessFailed,

  /// Encryption failed
  encryptionFailed,

  /// Not enough storage space to complete export
  insufficientStorage,

  /// Unknown or unexpected error occurred
  unknownError,
}

/// Extension to provide user-friendly messages for export errors
extension ExportErrorMessage on ExportError {
  String get message {
    switch (this) {
      case ExportError.noMindsToExport:
        return 'No minds available to export.';
      case ExportError.fileCreationFailed:
        return 'Failed to create export file.';
      case ExportError.audioAccessFailed:
        return 'Failed to access audio files.';
      case ExportError.encryptionFailed:
        return 'Failed to encrypt export file.';
      case ExportError.insufficientStorage:
        return 'Insufficient storage space to complete export.';
      case ExportError.unknownError:
        return 'An unexpected error occurred during export.';
    }
  }
}

/// Base class for export operation results
sealed class ExportResult {
  const ExportResult();
}

/// Successful export result with file and statistics
final class ExportSuccess extends ExportResult {
  /// The exported file
  final File file;

  /// Number of minds exported
  final int mindsCount;

  /// Number of audio files included
  final int audioFilesCount;

  /// List of audio file names that were missing (not included)
  final List<String> missingAudioFiles;

  /// Whether the export is password-protected
  final bool isEncrypted;

  const ExportSuccess({
    required this.file,
    required this.mindsCount,
    required this.audioFilesCount,
    this.missingAudioFiles = const [],
    this.isEncrypted = false,
  });

  /// Get file size in bytes
  int get fileSizeBytes => file.existsSync() ? file.lengthSync() : 0;

  /// Get human-readable file size
  String get fileSizeFormatted {
    final bytes = fileSizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() {
    return 'ExportSuccess(mindsCount: $mindsCount, audioFilesCount: $audioFilesCount, missingAudioFiles: ${missingAudioFiles.length}, isEncrypted: $isEncrypted, fileSize: $fileSizeFormatted)';
  }
}

/// Failed export result with error information
final class ExportFailure extends ExportResult {
  /// The type of error that occurred
  final ExportError error;

  /// Optional detailed error message
  final String? details;

  /// Optional exception that caused the failure
  final Exception? exception;

  const ExportFailure({
    required this.error,
    this.details,
    this.exception,
  });

  /// Get user-friendly error message
  String get message => details ?? error.message;

  @override
  String toString() {
    return 'ExportFailure(error: $error, details: $details)';
  }
}
