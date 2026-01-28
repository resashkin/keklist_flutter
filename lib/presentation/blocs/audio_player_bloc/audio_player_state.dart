part of 'audio_player_bloc.dart';

sealed class AudioPlayerState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

// Initial state - no audio loaded
final class AudioPlayerInitial extends AudioPlayerState {}

// Loading audio file
final class AudioPlayerLoading extends AudioPlayerState {
  final MindNoteAudio audio;

  AudioPlayerLoading({required this.audio});

  @override
  List<Object?> get props => [audio.appRelativeAbsoulutePath];
}

// Ready to play / playing / paused
final class AudioPlayerReady extends AudioPlayerState {
  final MindNoteAudio audio;
  final String absolutePath;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<double>? waveform;
  final double amplitude; // For reactive waves (0.0 - 1.0)

  AudioPlayerReady({
    required this.audio,
    required this.absolutePath,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.waveform,
    this.amplitude = 0.0,
  });

  double get progress => duration.inMilliseconds == 0
      ? 0.0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  AudioPlayerReady copyWith({
    MindNoteAudio? audio,
    String? absolutePath,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<double>? waveform,
    double? amplitude,
  }) {
    return AudioPlayerReady(
      audio: audio ?? this.audio,
      absolutePath: absolutePath ?? this.absolutePath,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      waveform: waveform ?? this.waveform,
      amplitude: amplitude ?? this.amplitude,
    );
  }

  @override
  List<Object?> get props => [
        audio.appRelativeAbsoulutePath,
        absolutePath,
        isPlaying,
        position,
        duration,
        waveform,
        amplitude,
      ];
}

// Error state
final class AudioPlayerError extends AudioPlayerState {
  final MindNoteAudio? audio;
  final String message;

  AudioPlayerError({this.audio, required this.message});

  @override
  List<Object?> get props => [audio?.appRelativeAbsoulutePath, message];
}
