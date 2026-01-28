import 'dart:io';

import 'package:just_audio/just_audio.dart';

/// Utility class for extracting audio metadata
final class AudioDurationExtractor {
  const AudioDurationExtractor();

  /// Extract duration from an audio file
  /// Returns duration in seconds, or 0.0 if file is missing/corrupt
  Future<double> extractDuration(String absolutePath) async {
    try {
      // Check if file exists
      final file = File(absolutePath);
      if (!await file.exists()) {
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
      // Return 0 on any error (corrupted file, unsupported format, etc.)
      return 0.0;
    }
  }
}
