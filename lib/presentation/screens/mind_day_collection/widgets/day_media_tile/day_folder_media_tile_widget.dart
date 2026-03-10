import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:keklist/native/android/media_folder_channel.dart';
import 'package:keklist/presentation/screens/date_gallery/folder_media_item.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/day_media_tile/day_folder_media_preview_cubit.dart';

final class DayFolderMediaTileWidget extends StatelessWidget {
  final DayFolderMediaPreviewData data;
  final VoidCallback onTap;

  const DayFolderMediaTileWidget({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_open, size: 18.0),
                  const SizedBox(width: 6.0),
                  Text('Media Folder', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16.0),
                ],
              ),
              const SizedBox(height: 8.0),
              if (data.files.isEmpty)
                Text(
                  'No media for this day',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const int kSlots = 5;
                    const double gap = 4.0;
                    final double size = (constraints.maxWidth - gap * (kSlots - 1)) / kSlots;
                    final bool hasMore = data.totalCount > data.files.length;
                    final int remaining = data.totalCount - (data.files.length - 1);
                    return SizedBox(
                      height: size,
                      child: Row(
                        mainAxisAlignment: data.files.length < kSlots
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        spacing: gap,
                        children: data.files.asMap().entries.map((entry) {
                          final bool isLast = entry.key == data.files.length - 1;
                          final FolderMediaItem item = entry.value;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: size,
                                  height: size,
                                  child: _FolderItemThumbnail(item: item, size: size),
                                ),
                                if (isLast && hasMore)
                                  Container(
                                    width: size,
                                    height: size,
                                    color: Colors.black54,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '+$remaining',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size * 0.28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton placeholder tile shown while the cubit is loading.
final class DayFolderMediaSkeletonTile extends StatelessWidget {
  const DayFolderMediaSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color placeholder = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row placeholder
            Row(
              children: [
                Container(width: 18, height: 18, decoration: BoxDecoration(color: placeholder, shape: BoxShape.circle)),
                const SizedBox(width: 6.0),
                Container(width: 100, height: 14, decoration: BoxDecoration(color: placeholder, borderRadius: BorderRadius.circular(4))),
              ],
            ),
            const SizedBox(height: 8.0),
            LayoutBuilder(
              builder: (context, constraints) {
                const int kSlots = 5;
                const double gap = 4.0;
                final double size = (constraints.maxWidth - gap * (kSlots - 1)) / kSlots;
                return SizedBox(
                  height: size,
                  child: Row(
                    spacing: gap,
                    children: List.generate(
                      kSlots,
                      (_) => ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: Container(width: size, height: size, color: placeholder),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white24);
  }
}

class _FolderItemThumbnail extends StatefulWidget {
  final FolderMediaItem item;
  final double size;

  const _FolderItemThumbnail({required this.item, required this.size});

  @override
  State<_FolderItemThumbnail> createState() => _FolderItemThumbnailState();
}

class _FolderItemThumbnailState extends State<_FolderItemThumbnail> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final item = widget.item;
    if (item is FolderFileItem) {
      // For iOS/macOS files, Image.file handles everything — no async needed
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (item is FolderSafItem) {
      final double physicalSize = widget.size * WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final Uint8List? bytes;
      if (item.isVideo) {
        bytes = await MediaFolderChannel.getVideoThumbnail(item.uri.toString());
      } else {
        bytes = await MediaFolderChannel.getDocumentThumbnail(item.uri.toString(), physicalSize, physicalSize);
      }
      if (mounted) setState(() { _bytes = bytes; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    switch (item) {
      case FolderFileItem(:final file):
        if (item.isVideo) return _videoIcon();
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context)).round(),
        );
      case FolderSafItem():
        if (_loading) return _skeletonBox();
        final bytes = _bytes;
        if (bytes != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(bytes, fit: BoxFit.cover, width: widget.size, height: widget.size),
              if (item.isVideo) _videoPlayOverlay(),
            ],
          );
        }
        return item.isVideo ? _videoIcon() : _imageIcon();
    }
  }

  Widget _skeletonBox() {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Container(width: widget.size, height: widget.size, color: color)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white24);
  }

  Widget _videoPlayOverlay() => Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 28),
      );

  Widget _videoIcon() => Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 28),
      );

  Widget _imageIcon() => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: Colors.white54, size: 28),
      );
}
