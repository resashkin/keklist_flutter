import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/presentation/blocs/audio_player_bloc/audio_player_bloc.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/full_screen_audio_player.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/play_pause_button.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/wave_progress_widget.dart';

final class AudioTrackWidget extends StatelessWidget {
  const AudioTrackWidget({super.key, required this.audio, required this.emoji});

  final MindNoteAudio audio;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      buildWhen: (AudioPlayerState previous, AudioPlayerState current) {
        // Only rebuild if this audio is loaded or state changed
        if (current is AudioPlayerReady) {
          return current.audio.appRelativeAbsoulutePath == audio.appRelativeAbsoulutePath;
        }
        if (current is AudioPlayerError) {
          return current.audio?.appRelativeAbsoulutePath == audio.appRelativeAbsoulutePath;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (BuildContext context, AudioPlayerState state) {
        final bool isThisAudioLoaded =
            state is AudioPlayerReady && state.audio.appRelativeAbsoulutePath == audio.appRelativeAbsoulutePath;

        final bool hasError =
            state is AudioPlayerError && state.audio?.appRelativeAbsoulutePath == audio.appRelativeAbsoulutePath;

        final Duration duration = isThisAudioLoaded ? (state).duration : Duration.zero;
        final List<double>? waveform = isThisAudioLoaded ? (state).waveform : null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PlayPauseButton(
                  isPlaying: false,
                  hasError: hasError,
                  onPressed: () => _openFullScreenPlayer(context),
                  iconSize: 36.0,
                ),
                const Gap(4.0),
                Expanded(
                  child: InkWell(
                    onTap: () => _openFullScreenPlayer(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WaveProgressWidget(
                          progress: 0.0,
                          waveform: waveform,
                          onSeek: null, // No seeking in compact view
                        ),
                        BoolWidget(
                          condition: duration != Duration.zero,
                          trueChild: Column(
                            children: [
                              const Gap(2.0),
                              Text(_formatDuration(duration), style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          falseChild: SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (hasError)
              Text(
                'Unable to play audio',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
          ],
        );
      },
    );
  }

  Future<void> _loadAudio(BuildContext context, {bool autoPlay = false}) async {
    final AppFileRepository fileRepository = context.read<AppFileRepository>();
    final String absolutePath = await fileRepository.resolveAbsolutePath(audio.appRelativeAbsoulutePath);

    if (context.mounted) {
      context.read<AudioPlayerBloc>().add(
        AudioPlayerLoadAudio(audio: audio, absolutePath: absolutePath, autoPlay: autoPlay),
      );
    }
  }

  Future<void> _openFullScreenPlayer(BuildContext context) async {
    final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
    final AudioPlayerState state = bloc.state;

    // Load audio if not already loaded
    if (state is! AudioPlayerReady || state.audio.appRelativeAbsoulutePath != audio.appRelativeAbsoulutePath) {
      await _loadAudio(context, autoPlay: true);
    } else if (!state.isPlaying) {
      bloc.add(AudioPlayerPlay());
    }

    // Open bottom sheet
    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        builder: (BuildContext context) => FullScreenAudioPlayerScreen(audio: audio, emoji: emoji),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
