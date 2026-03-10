import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:keklist/native/android/media_folder_channel.dart';
import 'package:keklist/presentation/screens/date_gallery/folder_media_item.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

final class FolderMediaViewerScreen extends StatefulWidget {
  final FolderMediaItem item;
  final VoidCallback? onSettings;

  const FolderMediaViewerScreen({super.key, required this.item, this.onSettings});

  @override
  State<FolderMediaViewerScreen> createState() => _FolderMediaViewerScreenState();
}

final class _FolderMediaViewerScreenState extends State<FolderMediaViewerScreen> {
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  Uint8List? _safImageBytes;

  double _dragOffsetY = 0.0;
  double _backgroundOpacity = 1.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      _initVideo();
    } else if (widget.item case FolderSafItem()) {
      _loadSafImage();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    setState(() => _isLoading = true);
    switch (widget.item) {
      case FolderFileItem(:final file):
        _videoController = VideoPlayerController.file(file);
      case FolderSafItem(:final uri):
        _videoController = VideoPlayerController.contentUri(uri);
    }
    await _videoController!.initialize();
    _videoController!.addListener(() => setState(() {}));
    setState(() => _isLoading = false);
    _videoController!.play();
  }

  Future<void> _loadSafImage() async {
    setState(() => _isLoading = true);
    try {
      final item = widget.item as FolderSafItem;
      final Uint8List? bytes = await MediaFolderChannel.getDocumentContent(item.uri.toString());
      setState(() {
        _safImageBytes = bytes;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareMedia() async {
    switch (widget.item) {
      case FolderFileItem(:final file):
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      case FolderSafItem(:final uri):
        await SharePlus.instance.share(ShareParams(files: [XFile(uri.toString())]));
    }
  }

  void _onVerticalDragStart(DragStartDetails _) => setState(() => _isDragging = true);

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
          if (widget.onSettings != null)
            AnimatedOpacity(
              opacity: _isDragging ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: widget.onSettings,
              ),
            ),
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
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (widget.item.isVideo) {
      return _buildVideoPlayer();
    } else {
      return _buildImageViewer();
    }
  }

  Widget _buildImageViewer() {
    final ImageProvider imageProvider;
    switch (widget.item) {
      case FolderFileItem(:final file):
        imageProvider = FileImage(file);
      case FolderSafItem():
        final bytes = _safImageBytes;
        if (bytes == null) {
          return const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 64));
        }
        imageProvider = MemoryImage(bytes);
    }

    return PhotoViewGestureDetectorScope(
      axis: Axis.vertical,
      child: PhotoView(
        imageProvider: imageProvider,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        loadingBuilder: (context, event) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 64)),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final VideoPlayerController? controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
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
          onTap: () => setState(() {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          }),
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
      ],
    );
  }
}
