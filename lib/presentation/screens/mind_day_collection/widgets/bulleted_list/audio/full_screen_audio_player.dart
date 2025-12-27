import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/presentation/blocs/audio_player_bloc/audio_player_bloc.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/audio_reactive_waves_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/audio_timer_display_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/play_pause_button.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/wave_progress_widget.dart';

final class FullScreenAudioPlayerScreen extends StatefulWidget {
  final MindNoteAudio audio;
  final String emoji;

  const FullScreenAudioPlayerScreen({super.key, required this.audio, required this.emoji});

  @override
  State<FullScreenAudioPlayerScreen> createState() => _FullScreenAudioPlayerScreenState();
}

final class _FullScreenAudioPlayerScreenState extends State<FullScreenAudioPlayerScreen> {

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      buildWhen: (AudioPlayerState previous, AudioPlayerState current) {
        if (current is AudioPlayerReady) {
          return current.audio.appRelativeAbsoulutePath == widget.audio.appRelativeAbsoulutePath;
        }
        return true;
      },
      builder: (BuildContext context, AudioPlayerState state) {
        if (state is! AudioPlayerReady ||
            state.audio.appRelativeAbsoulutePath != widget.audio.appRelativeAbsoulutePath) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 12),

              // Audio reactive waves with emoji
              SizedBox(
                height: 300,
                child: AudioReactiveWavesWidget(amplitude: state.amplitude, emoji: widget.emoji),
              ),

              const SizedBox(height: 16),

              // Waveform seeker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: WaveProgressWidget(
                  progress: state.progress,
                  waveform: state.waveform,
                  onSeek: (double relativePos) => _onSeek(context, state.duration, relativePos),
                ),
              ),

              const SizedBox(height: 16),

              // Timer display
              AudioTimerDisplayWidget(position: state.position, duration: state.duration),

              const SizedBox(height: 48),

              // Play/Pause button
              PlayPauseButton(
                iconSize: 80.0,
                isPlaying: state.isPlaying,
                hasError: false,
                onPressed: () {
                  context.read<AudioPlayerBloc>().add(AudioPlayerTogglePlayback());
                },
              ),

              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  void _onSeek(BuildContext context, Duration duration, double relativePosition) {
    if (duration == Duration.zero || !relativePosition.isFinite) {
      return;
    }

    final double clamped = relativePosition.clamp(0.0, 1.0);
    final int targetMilliseconds = (duration.inMilliseconds * clamped).round();
    final Duration targetPosition = Duration(milliseconds: targetMilliseconds);

    context.read<AudioPlayerBloc>().add(AudioPlayerSeek(position: targetPosition));
  }
}
