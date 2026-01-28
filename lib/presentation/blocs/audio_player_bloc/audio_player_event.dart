part of 'audio_player_bloc.dart';

@immutable
abstract class AudioPlayerEvent with EquatableMixin {
  @override
  List<Object?> get props => [];
}

// Load a new audio file
final class AudioPlayerLoadAudio extends AudioPlayerEvent {
  final MindNoteAudio audio;
  final String absolutePath;
  final bool autoPlay;

  AudioPlayerLoadAudio({
    required this.audio,
    required this.absolutePath,
    this.autoPlay = false,
  });

  @override
  List<Object?> get props => [audio.appRelativeAbsoulutePath, absolutePath, autoPlay];
}

// Playback control
final class AudioPlayerPlay extends AudioPlayerEvent {}

final class AudioPlayerPause extends AudioPlayerEvent {}

final class AudioPlayerTogglePlayback extends AudioPlayerEvent {}

// Seeking
final class AudioPlayerSeek extends AudioPlayerEvent {
  final Duration position;

  AudioPlayerSeek({required this.position});

  @override
  List<Object?> get props => [position];
}

// Internal events for stream updates
final class AudioPlayerPositionUpdated extends AudioPlayerEvent {
  final Duration position;

  AudioPlayerPositionUpdated({required this.position});

  @override
  List<Object?> get props => [position];
}

final class AudioPlayerDurationUpdated extends AudioPlayerEvent {
  final Duration duration;

  AudioPlayerDurationUpdated({required this.duration});

  @override
  List<Object?> get props => [duration];
}

final class AudioPlayerStateUpdated extends AudioPlayerEvent {
  final PlayerState playerState;

  AudioPlayerStateUpdated({required this.playerState});

  @override
  List<Object?> get props => [playerState];
}

final class AudioPlayerWaveformUpdated extends AudioPlayerEvent {
  final List<double> waveform;

  AudioPlayerWaveformUpdated({required this.waveform});

  @override
  List<Object?> get props => [waveform];
}

// For amplitude-reactive visualization
final class AudioPlayerAmplitudeUpdated extends AudioPlayerEvent {
  final double amplitude;

  AudioPlayerAmplitudeUpdated({required this.amplitude});

  @override
  List<Object?> get props => [amplitude];
}

// Cleanup
final class AudioPlayerDispose extends AudioPlayerEvent {}
