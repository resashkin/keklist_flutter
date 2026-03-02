import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
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

  double _dragOffsetY = 0.0;
  double _backgroundOpacity = 1.0;
  bool _isDragging = false;

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
      _videoController!.addListener(() => setState(() {}));
      setState(() => _isLoading = false);
      _videoController!.play();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareMedia() async {
    final File? file = _file;
    if (file == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  void _onVerticalDragStart(DragStartDetails _) {
    setState(() => _isDragging = true);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffsetY += details.delta.dy;
      _backgroundOpacity = (1.0 - (_dragOffsetY.abs() / 350.0)).clamp(0.0, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffsetY.abs() > 120 || details.velocity.pixelsPerSecond.dy.abs() > 800) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffsetY = 0.0;
        _backgroundOpacity = 1.0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _backgroundOpacity),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AnimatedOpacity(
          opacity: _isDragging ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          if (_file != null)
            AnimatedOpacity(
              opacity: _isDragging ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: _shareMedia,
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffsetY),
          child: _buildBody(),
        ),
      ),
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
    // PhotoViewGestureDetectorScope yields the vertical drag gesture to the
    // parent GestureDetector whenever the image cannot pan further vertically
    // (i.e. at minimum/contained scale, or at the top/bottom edge when zoomed).
    // This lets pinch-zoom, double-tap-zoom, and pan all coexist naturally with
    // the swipe-to-dismiss gesture handled by the parent.
    return PhotoViewGestureDetectorScope(
      axis: Axis.vertical,
      child: PhotoView(
        imageProvider: FileImage(file),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 64),
        ),
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

  void _seekBy(int seconds) {
    final VideoPlayerController? controller = _videoController;
    if (controller == null) return;
    final Duration target = controller.value.position + Duration(seconds: seconds);
    controller.seekTo(target.isNegative ? Duration.zero : target);
  }

  Widget _buildVideoControls(VideoPlayerController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatDuration(controller.value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _seekBy(-10),
                    child: const SizedBox(
                      width: 56,
                      height: 44,
                      child: Center(child: Icon(Icons.replay_10, color: Colors.white, size: 28)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _seekBy(10),
                    child: const SizedBox(
                      width: 56,
                      height: 44,
                      child: Center(child: Icon(Icons.forward_10, color: Colors.white, size: 28)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDuration(controller.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
