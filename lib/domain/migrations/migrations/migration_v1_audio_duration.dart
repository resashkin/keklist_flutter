// ignore_for_file: avoid_print

import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:keklist/domain/migrations/migration.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';

/// Migration v1: Extract and persist audio durations for all existing audio recordings
///
/// Before this migration, audio durations were not persisted and had to be extracted
/// at runtime. This migration extracts durations once and stores them in the note content.
class MigrationV1AudioDuration extends Migration {
  @override
  int get version => 1;

  @override
  String get description =>
      'Extract and persist audio durations for existing recordings';

  @override
  Future<MigrationResult> run(MigrationContext context) async {
    try {
      print('[Migration v1] Starting audio duration extraction');

      final allMinds = context.mindRepository.values;
      final mindsWithAudio = allMinds.where((mind) => mind.audioNotes.isNotEmpty).toList();

      print('[Migration v1] Found ${mindsWithAudio.length} minds with audio');

      int updatedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      for (final mind in mindsWithAudio) {
        try {
          final noteContent = mind.noteContent;
          final audioPieces = noteContent.audioPieces;

          // Check if any audio pieces need duration extraction
          final needsUpdate = audioPieces.any((audio) => !audio.hasDuration);

          if (!needsUpdate) {
            skippedCount++;
            continue;
          }

          // Extract durations for audio pieces that don't have them
          final updatedPieces = <BaseMindNotePiece>[];

          for (final piece in noteContent.pieces) {
            if (piece is MindNoteAudio && !piece.hasDuration) {
              // Extract duration
              final duration = await _extractAudioDuration(
                piece.appRelativeAbsoulutePath,
                context,
              );

              updatedPieces.add(MindNoteAudio(
                appRelativeAbsoulutePath: piece.appRelativeAbsoulutePath,
                durationSeconds: duration,
              ));
            } else {
              updatedPieces.add(piece);
            }
          }

          // Create updated note content and mind
          final updatedContent = MindNoteContent.fromPieces(updatedPieces);
          final updatedMind = mind.copyWithNoteContent(updatedContent);

          // Update in repository
          await context.mindRepository.updateMind(mind: updatedMind);
          updatedCount++;
        } catch (e, stackTrace) {
          errorCount++;
          print('[Migration v1] Error updating mind ${mind.id}: $e');
          print('[Migration v1] Stack trace: $stackTrace');
          // Continue with next mind instead of failing the entire migration
        }
      }

      final message =
          'Updated $updatedCount minds, skipped $skippedCount, errors: $errorCount';
      print('[Migration v1] $message');

      if (errorCount > 0) {
        print(
            '[Migration v1] Warning: Some minds had errors but migration completed');
      }

      return MigrationResult.success(message: message);
    } catch (e, stackTrace) {
      print('[Migration v1] Fatal error: $e');
      print('[Migration v1] Stack trace: $stackTrace');
      return MigrationResult.failure(
        message: 'Failed to extract audio durations',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Extract duration from an audio file
  /// Returns duration in seconds, or 0.0 if file is missing/corrupt
  Future<double> _extractAudioDuration(
    String relativePath,
    MigrationContext context,
  ) async {
    try {
      // Resolve absolute path
      final absolutePath = await context.fileRepository.resolveAbsolutePath(relativePath);

      // Check if file exists
      final file = File(absolutePath);
      if (!await file.exists()) {
        print('[Migration v1] Audio file not found: $absolutePath');
        return 0.0;
      }

      // Extract duration using just_audio
      final player = AudioPlayer();
      try {
        await player.setFilePath(absolutePath);
        final duration = player.duration ?? Duration.zero;
        return duration.inMilliseconds / 1000.0;
      } finally {
        await player.dispose();
      }
    } catch (e) {
      print('[Migration v1] Error extracting duration for $relativePath: $e');
      return 0.0;
    }
  }
}
