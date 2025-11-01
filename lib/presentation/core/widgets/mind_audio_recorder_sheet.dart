import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'package:keklist/domain/repositories/files/app_file_repository.dart';

// Path to audio
typedef AudioRecordingResult = String?;

/// Bottom sheet widget that exposes a minimalistic audio recording experience.
/// Records audio into the dedicated user storage folder and returns a relative
/// path that can be embedded into `MindNoteContent`.
final class MindAudioRecorderSheet extends StatefulWidget {
  const MindAudioRecorderSheet({
    super.key,
    required this.fileRepository,
  });

  final AppFileRepository fileRepository;

  @override
  State<MindAudioRecorderSheet> createState() => _MindAudioRecorderSheetState();
}

final class _MindAudioRecorderSheetState extends State<MindAudioRecorderSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  AppFileHandle? _fileHandle;
  bool _isRecording = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _safeStop();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isRecording ? 'Recording…' : 'Record audio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _toggleRecording,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop' : 'Start'),
            ),
            if (_isRecording) ...[
              const SizedBox(height: 16),
              Text(
                'Tap Stop to save to your device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.of(context).maybePop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _completeRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required to record audio.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final AppFileHandle handle = await widget.fileRepository.createAudioFile();

    try {
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: handle.file.path,
      );
      _fileHandle = handle;
      setState(() {
        _isProcessing = false;
        _isRecording = true;
      });
    } catch (error) {
      _cleanupFile(handle.file);
      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start recording. Please try again.')),
      );
    }
  }

  Future<void> _completeRecording() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final String? recordedPath = await _recorder.stop();
      _isRecording = false;

      if (!mounted) {
        _cleanupFile(_fileHandle?.file);
        return;
      }

      if (recordedPath == null || _fileHandle == null) {
        _cleanupFile(_fileHandle?.file);
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording failed to complete. Please try again.')),
        );
        return;
      }

      Navigator.of(context).pop<AudioRecordingResult>(_fileHandle!.relativePath);
    } catch (error) {
      _cleanupFile(_fileHandle?.file);
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to stop the recording. Please try again.')),
      );
    }
  }

  Future<void> _safeStop() async {
    if (_isRecording) {
      await _recorder.stop();
      _cleanupFile(_fileHandle?.file);
    }
  }

  void _cleanupFile(File? file) {
    if (file == null) {
      return;
    }
    if (file.existsSync()) {
      unawaited(file.delete());
    }
  }
}
