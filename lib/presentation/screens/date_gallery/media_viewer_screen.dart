import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

final class MediaViewerScreen extends StatefulWidget {
  final AssetEntity asset;

  const MediaViewerScreen({super.key, required this.asset});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

final class _MediaViewerScreenState extends State<MediaViewerScreen> {
  File? _file;
  bool _isLoading = true;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadAsset() async {
    setState(() => _isLoading = true);

    final File? file = await widget.asset.file;
    if (file == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _file = file;
    });

    if (widget.asset.type == AssetType.video) {
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      setState(() => _isLoading = false);
      _videoController!.play();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final File? file = _file;
    if (file == null) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white, size: 64),
      );
    }

    if (widget.asset.type == AssetType.video) {
      return _buildVideoPlayer();
    } else {
      return _buildImageViewer(file);
    }
  }

  Widget _buildImageViewer(File file) {
    return PhotoView(
      imageProvider: FileImage(file),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.error_outline, color: Colors.white, size: 64),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final VideoPlayerController? controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: AnimatedOpacity(
                opacity: controller.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildVideoControls(controller),
        ),
      ],
    );
  }

  Widget _buildVideoControls(VideoPlayerController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(controller.value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(controller.value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
