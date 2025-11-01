import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:provider/provider.dart';

final class MindBulletWidget extends StatelessWidget {
  final MindBulletModel model;

  const MindBulletWidget({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final List<BaseMindNotePiece> pieces = model.content.pieces;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    final List<Widget> contentWidgets = pieces.isEmpty
        ? <Widget>[
            SensitiveWidget(
              child: Text(
                model.content.plainText,
                maxLines: null,
                style: const TextStyle(fontSize: 15.0),
              ),
            ),
          ]
        : <Widget>[];

    if (contentWidgets.isEmpty) {
      for (final BaseMindNotePiece piece in pieces) {
        if (contentWidgets.isNotEmpty) {
          contentWidgets.add(const Gap(12.0));
        }
        contentWidgets.add(
          piece.map(
            text: (MindNoteText textPiece) => SensitiveWidget(
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      child: Text(
                        textPiece.value,
                        maxLines: null,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            audio: (MindNoteAudio audioPiece) => SensitiveWidget(
              child: _MindAudioTrackWidget(audio: audioPiece),
            ),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        // TODO: just wathing how it goes without emoji on start...
        // const Gap(10.0),
        // Text(
        //   model.emoji,
        //   style: const TextStyle(fontSize: 25.0),
        // ),
        const Gap(10.0),
        Flexible(
          fit: FlexFit.tight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: contentWidgets,
            ),
          ),
        ),
        const Gap(16.0),
      ],
    );
  }
}

final class MindBulletModel {
  final String entityId;
  final String emoji;
  final MindNoteContent content;

  const MindBulletModel({
    required this.entityId,
    required this.emoji,
    required this.content,
  });
}

final class _MindAudioTrackWidget extends StatefulWidget {
  const _MindAudioTrackWidget({required this.audio});

  final MindNoteAudio audio;

  @override
  State<_MindAudioTrackWidget> createState() => _MindAudioTrackWidgetState();
}

final class _MindAudioTrackWidgetState extends State<_MindAudioTrackWidget> {
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
  void didUpdateWidget(covariant _MindAudioTrackWidget oldWidget) {
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
            _PlayPauseButton(
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
                  _WaveProgressWidget(
                    progress: _hasError ? 0.0 : progress,
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
        // Slider(
        //   value: progress,
        //   min: 0.0,
        //   max: 1.0,
        //   onChanged: _hasError ? null : _onSeek,
        // ),
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

final class _WaveProgressWidget extends StatelessWidget {
  const _WaveProgressWidget({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final Color inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.25);
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final double effectiveProgress = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int computedCount = (constraints.maxWidth / 6).floor();
        final int barCount = computedCount <= 0 ? 8 : computedCount;
        final double barWidth = 4;
        final List<double> heights = List<double>.generate(barCount, (int index) {
          final double normalized = (index % 4) / 4;
          return 10 + (14 * normalized);
        });
        final double activeBarsDouble = effectiveProgress * barCount;
        final int fullActiveBars = activeBarsDouble.floor();
        final double partialBarFraction = activeBarsDouble - fullActiveBars;

        return SizedBox(
          height: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(barCount, (int index) {
              Color barColor = inactiveColor;

              if (effectiveProgress >= 1.0 || index < fullActiveBars) {
                barColor = activeColor;
              } else if (index == fullActiveBars && partialBarFraction > 0 && fullActiveBars < barCount) {
                barColor = Color.lerp(inactiveColor, activeColor, partialBarFraction) ?? activeColor;
              }

              return Container(
                width: barWidth,
                height: heights[index],
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

final class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.hasError,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool hasError;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: hasError ? null : onPressed,
      iconSize: 36,
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primary,
      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
    );
  }
}
