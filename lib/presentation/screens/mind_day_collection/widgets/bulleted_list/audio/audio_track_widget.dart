import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/play_pause_button.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/bulleted_list/audio/wave_progress_widget.dart';
import 'package:provider/provider.dart';

/// TODO: refactor after AI
/// * use player as a global bloc?
/// * add real waves of audio instead of random pillars
/// * slide forward by finger above widget without creating UI components

final class AudioTrackWidget extends StatefulWidget {
  const AudioTrackWidget({
    super.key,
    required this.audio,
  });

  final MindNoteAudio audio;

  @override
  State<AudioTrackWidget> createState() => AudioTrackWidgetState();
}

final class AudioTrackWidgetState extends State<AudioTrackWidget> {
  late final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.playerStateStream.listen((PlayerState state) {
      if (!mounted) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        unawaited(_player.seek(Duration.zero));
        unawaited(_player.pause());
      }
      setState(() {});
    });
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant AudioTrackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio.appRelativeAbsoulutePath != widget.audio.appRelativeAbsoulutePath) {
      unawaited(_initialize());
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    setState(() {
      _hasError = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      final AppFileRepository fileRepository = context.read<AppFileRepository>();
      final String absolutePath = await fileRepository.resolveAbsolutePath(widget.audio.appRelativeAbsoulutePath);
      await _player.setFilePath(absolutePath);
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = _player.duration ?? Duration.zero;
      });

      _positionSubscription = _player.positionStream.listen((Duration position) {
        if (!mounted) {
          return;
        }
        setState(() {
          _position = position;
        });
      });
      _durationSubscription = _player.durationStream.listen((Duration? newDuration) {
        if (!mounted || newDuration == null) {
          return;
        }
        setState(() {
          _duration = newDuration;
        });
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_hasError) {
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onSeek(double relativePosition) {
    if (_hasError || _duration == Duration.zero || !relativePosition.isFinite) {
      return;
    }
    final double clamped = relativePosition.clamp(0.0, 1.0);
    final int targetMilliseconds = (_duration.inMilliseconds * clamped).round();
    final Duration targetPosition = Duration(milliseconds: targetMilliseconds);
    unawaited(_player.seek(targetPosition));
    setState(() {
      _position = targetPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _player.playing;
    final double progress =
        _duration.inMilliseconds == 0 ? 0 : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TODO: remove has error and make this button with disabled state
            PlayPauseButton(
              isPlaying: isPlaying,
              hasError: _hasError,
              onPressed: _togglePlayback,
            ),
            const Gap(4.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  WaveProgressWidget(
                    progress: _hasError ? 0.0 : progress,
                    onSeek: _hasError ? null : _onSeek,
                  ),
                  const Gap(2.0),
                  Text(
                    '${_formatDuration(_position)} / ${_duration == Duration.zero ? '--:--' : _formatDuration(_duration)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_hasError)
          Text(
            'Unable to play audio',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
