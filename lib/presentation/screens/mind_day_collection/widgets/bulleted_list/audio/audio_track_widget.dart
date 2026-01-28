import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/presentation/blocs/audio_player_bloc/audio_player_bloc.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/full_screen_audio_player.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/play_pause_button.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/wave_progress_widget.dart';

final class AudioTrackWidget extends StatefulWidget {
  const AudioTrackWidget({super.key, required this.audio, required this.emoji});

  final MindNoteAudio audio;
  final String emoji;

  @override
  State<AudioTrackWidget> createState() => _AudioTrackWidgetState();
}

final class _AudioTrackWidgetState extends State<AudioTrackWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      buildWhen: (AudioPlayerState previous, AudioPlayerState current) {
        // Only rebuild if this audio is loaded or state changed
        if (current is AudioPlayerReady) {
          return current.audio.appRelativeAbsoulutePath == widget.audio.appRelativeAbsoulutePath;
        }
        if (current is AudioPlayerError) {
          return current.audio?.appRelativeAbsoulutePath == widget.audio.appRelativeAbsoulutePath;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (BuildContext context, AudioPlayerState state) {
        final bool isThisAudioLoaded =
            state is AudioPlayerReady && state.audio.appRelativeAbsoulutePath == widget.audio.appRelativeAbsoulutePath;

        final bool hasError =
            state is AudioPlayerError && state.audio?.appRelativeAbsoulutePath == widget.audio.appRelativeAbsoulutePath;

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
                        WaveProgressWidget(progress: 0.0, waveform: waveform),
                        if (widget.audio.hasDuration) ...[
                          const Gap(2.0),
                          Text(
                            _formatDuration(widget.audio.duration!),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
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
    final String absolutePath = await fileRepository.resolveAbsolutePath(widget.audio.appRelativeAbsoulutePath);

    if (context.mounted) {
      context.read<AudioPlayerBloc>().add(
        AudioPlayerLoadAudio(audio: widget.audio, absolutePath: absolutePath, autoPlay: autoPlay),
      );
    }
  }

  Future<void> _openFullScreenPlayer(BuildContext context) async {
    final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
    final AudioPlayerState state = bloc.state;

    // Load audio if not already loaded
    if (state is! AudioPlayerReady || state.audio.appRelativeAbsoulutePath != widget.audio.appRelativeAbsoulutePath) {
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        builder: (BuildContext context) => FullScreenAudioPlayerScreen(audio: widget.audio, emoji: widget.emoji),
      ).then((_) {
        sendEventToBloc<AudioPlayerBloc>(AudioPlayerDispose());
      });
    }
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
