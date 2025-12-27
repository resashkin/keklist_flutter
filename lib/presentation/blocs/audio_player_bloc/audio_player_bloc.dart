import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';

part 'audio_player_event.dart';
part 'audio_player_state.dart';

final class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> with DisposeBag {
  late final AudioPlayer _player = AudioPlayer();
  Timer? _amplitudeTimer;
  int _lastPositionEmitMs = -1000;

  AudioPlayerBloc() : super(AudioPlayerInitial()) {
    on<AudioPlayerLoadAudio>(_onLoadAudio);
    on<AudioPlayerPlay>(_onPlay);
    on<AudioPlayerPause>(_onPause);
    on<AudioPlayerTogglePlayback>(_onTogglePlayback);
    on<AudioPlayerSeek>(_onSeek);
    on<AudioPlayerPositionUpdated>(_onPositionUpdated);
    on<AudioPlayerDurationUpdated>(_onDurationUpdated);
    on<AudioPlayerStateUpdated>(_onStateUpdated);
    on<AudioPlayerWaveformUpdated>(_onWaveformUpdated);
    on<AudioPlayerAmplitudeUpdated>(_onAmplitudeUpdated);
    on<AudioPlayerDispose>(_onDispose);

    // Setup stream subscriptions
    _player.positionStream
        .listen((Duration position) {
          final int now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastPositionEmitMs >= 200) {
            _lastPositionEmitMs = now;
            add(AudioPlayerPositionUpdated(position: position));
          }
        })
        .disposed(by: this);

    _player.durationStream
        .listen((Duration? duration) {
          if (duration != null) {
            add(AudioPlayerDurationUpdated(duration: duration));
          }
        })
        .disposed(by: this);

    _player.playerStateStream
        .listen((PlayerState playerState) {
          add(AudioPlayerStateUpdated(playerState: playerState));
        })
        .disposed(by: this);
  }

  @override
  Future<void> close() {
    _amplitudeTimer?.cancel();
    cancelSubscriptions();
    _player.dispose();
    return super.close();
  }

  Future<void> _onLoadAudio(AudioPlayerLoadAudio event, Emitter<AudioPlayerState> emit) async {
    emit(AudioPlayerLoading(audio: event.audio));

    try {
      await _player.setFilePath(event.absolutePath);

      final Duration duration = _player.duration ?? Duration.zero;

      emit(
        AudioPlayerReady(
          audio: event.audio,
          absolutePath: event.absolutePath,
          isPlaying: false,
          position: Duration.zero,
          duration: duration,
          amplitude: 0.0,
        ),
      );

      // Load waveform asynchronously
      unawaited(_loadWaveform(event.absolutePath));

      // Auto-play if requested
      if (event.autoPlay) {
        await _player.play();
      }

      // Start amplitude monitoring
      _startAmplitudeMonitoring();
    } catch (e) {
      emit(AudioPlayerError(audio: event.audio, message: 'Unable to load audio: $e'));
    }
  }

  Future<void> _onPlay(AudioPlayerPlay event, Emitter<AudioPlayerState> emit) async {
    await _player.play();
  }

  Future<void> _onPause(AudioPlayerPause event, Emitter<AudioPlayerState> emit) async {
    await _player.pause();
  }

  Future<void> _onTogglePlayback(AudioPlayerTogglePlayback event, Emitter<AudioPlayerState> emit) async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _onSeek(AudioPlayerSeek event, Emitter<AudioPlayerState> emit) async {
    await _player.seek(event.position);
  }

  void _onPositionUpdated(AudioPlayerPositionUpdated event, Emitter<AudioPlayerState> emit) {
    final AudioPlayerState currentState = state;
    if (currentState is AudioPlayerReady) {
      emit(currentState.copyWith(position: event.position));
    }
  }

  void _onDurationUpdated(AudioPlayerDurationUpdated event, Emitter<AudioPlayerState> emit) {
    final AudioPlayerState currentState = state;
    if (currentState is AudioPlayerReady) {
      emit(currentState.copyWith(duration: event.duration));
    }
  }

  void _onStateUpdated(AudioPlayerStateUpdated event, Emitter<AudioPlayerState> emit) {
    final AudioPlayerState currentState = state;
    if (currentState is AudioPlayerReady) {
      final bool isPlaying = event.playerState.playing;

      // Handle completion
      if (event.playerState.processingState == ProcessingState.completed) {
        unawaited(_player.seek(Duration.zero));
        unawaited(_player.pause());
      }

      emit(currentState.copyWith(isPlaying: isPlaying));
    }
  }

  void _onWaveformUpdated(AudioPlayerWaveformUpdated event, Emitter<AudioPlayerState> emit) {
    final AudioPlayerState currentState = state;
    if (currentState is AudioPlayerReady) {
      emit(currentState.copyWith(waveform: event.waveform));
    }
  }

  void _onAmplitudeUpdated(AudioPlayerAmplitudeUpdated event, Emitter<AudioPlayerState> emit) {
    final AudioPlayerState currentState = state;
    if (currentState is AudioPlayerReady) {
      emit(currentState.copyWith(amplitude: event.amplitude));
    }
  }

  void _onDispose(AudioPlayerDispose event, Emitter<AudioPlayerState> emit) {
    _amplitudeTimer?.cancel();
    _player.stop();
    emit(AudioPlayerInitial());
  }

  Future<void> _loadWaveform(String absolutePath) async {
    final File audioFile = File(absolutePath);
    if (!await audioFile.exists()) {
      return;
    }

    final File waveformFile = File('$absolutePath.waveform');

    try {
      if (await waveformFile.exists()) {
        final Waveform waveform = await JustWaveform.parse(waveformFile);
        add(AudioPlayerWaveformUpdated(waveform: _normalizeWaveform(waveform)));
        return;
      }

      JustWaveform.extract(
            audioInFile: audioFile,
            waveOutFile: waveformFile,
            zoom: const WaveformZoom.pixelsPerSecond(200),
          )
          .listen((WaveformProgress progress) {
            final Waveform? waveform = progress.waveform;
            if (waveform != null) {
              add(AudioPlayerWaveformUpdated(waveform: _normalizeWaveform(waveform)));
            }
          })
          .disposed(by: this);
    } catch (_) {
      // Waveform loading failed, continue without waveform
    }
  }

  List<double> _normalizeWaveform(Waveform waveform) {
    final double maxAmplitude = waveform.flags == 0 ? 32768.0 : 128.0;
    return List<double>.generate(waveform.length, (int index) {
      final double min = waveform.getPixelMin(index).abs() / maxAmplitude;
      final double max = waveform.getPixelMax(index).abs() / maxAmplitude;
      final double normalized = math.max(min, max);
      return normalized.isFinite ? normalized.clamp(0.0, 1.0) : 0.0;
    }, growable: false);
  }

  // Amplitude monitoring for reactive waves
  // Note: This is a simplified approach since just_audio doesn't provide
  // real-time amplitude. We simulate it based on waveform data and position.
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => _updateAmplitude());
  }

  void _updateAmplitude() {
    final AudioPlayerState currentState = state;
    if (currentState is! AudioPlayerReady || !currentState.isPlaying) {
      //add(AudioPlayerAmplitudeUpdated(amplitude: 0.0));
      return;
    }

    final List<double>? waveform = currentState.waveform;
    if (waveform == null || waveform.isEmpty) {
      //add(AudioPlayerAmplitudeUpdated(amplitude: 0.0));
      return;
    }

    // Calculate amplitude from waveform based on current position
    final double progress = currentState.progress;
    final int index = (progress * waveform.length).floor().clamp(0, waveform.length - 1);
    final double amplitude = waveform[index];

    add(AudioPlayerAmplitudeUpdated(amplitude: amplitude));
  }
}
