import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/native/android/media_folder_channel.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart' as kek_date;
import 'package:keklist/presentation/screens/date_gallery/folder_media_item.dart';
import 'package:keklist/presentation/screens/date_gallery/folder_media_viewer_screen.dart';

const int _kGalleryColumnCount = 4;

final class FolderGalleryScreen extends StatefulWidget {
  final int dayIndex;
  final String folderPath;
  final bool recursive;
  final VoidCallback? onSettings;

  const FolderGalleryScreen({
    super.key,
    required this.dayIndex,
    required this.folderPath,
    this.recursive = false,
    this.onSettings,
  });

  @override
  State<FolderGalleryScreen> createState() => _FolderGalleryScreenState();
}

final class _FolderGalleryScreenState extends State<FolderGalleryScreen> {
  List<FolderMediaItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final DateTime dayDate = kek_date.DateUtils.getDateFromDayIndex(widget.dayIndex);
    final DateTime startOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final List<FolderMediaItem> items;
    if (Platform.isAndroid) {
      items = await _loadSafItems(startOfDay, endOfDay);
    } else {
      items = _loadFileItems(startOfDay, endOfDay);
    }

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  List<FolderMediaItem> _loadFileItems(DateTime startOfDay, DateTime endOfDay) {
    final Directory dir = Directory(widget.folderPath);
    if (!dir.existsSync()) return [];

    final List<File> files = dir
        .listSync(recursive: widget.recursive)
        .whereType<File>()
        .where((f) => _isMediaFile(f.path))
        .where((f) {
          final DateTime modified = f.statSync().modified;
          return modified.isAfter(startOfDay) && modified.isBefore(endOfDay);
        })
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files.map((f) => FolderFileItem(f)).toList();
  }

  Future<List<FolderMediaItem>> _loadSafItems(DateTime startOfDay, DateTime endOfDay) async {
    try {
      final List<SafFileInfo> all = await MediaFolderChannel.listFiles(widget.folderPath, recursive: widget.recursive);
      final List<FolderSafItem> items = all
          .where((f) => !f.isDirectory)
          .where((f) => _isMediaMimeType(f.mimeType))
          .where((f) {
            final DateTime? modified = f.lastModified;
            if (modified == null) return false;
            return modified.isAfter(startOfDay) && modified.isBefore(endOfDay);
          })
          .map((f) => FolderSafItem(
                uri: Uri.parse(f.uri),
                mimeType: f.mimeType,
                lastModified: f.lastModified,
              ))
          .toList()
        ..sort((a, b) {
          final DateTime aDate = a.lastModified ?? DateTime(0);
          final DateTime bDate = b.lastModified ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
      return items;
    } catch (_) {
      return [];
    }
  }

  bool _isMediaFile(String path) {
    final String ext = path.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'mp4', 'mov', 'avi', 'mkv', 'm4v'}
        .contains(ext);
  }

  bool _isMediaMimeType(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType.startsWith('image/') || mimeType.startsWith('video/');
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = kek_date.DateUtils.getDateFromDayIndex(widget.dayIndex);
    final Locale locale = Localizations.localeOf(context);
    final String yearSuffix = date.year == DateTime.now().year ? '' : ' ${date.year}';
    final String formattedDay = '${DateFormatters.dayMonthFormat(locale).format(date)}$yearSuffix';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(formattedDay, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500)),
            Text(
              _isLoading ? 'Loading...' : '${_items.length} media files',
              style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        actions: [
          if (widget.onSettings != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: widget.onSettings,
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonGrid(context);
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_open, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No media files for this day',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _kGalleryColumnCount,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) => _buildThumbnail(context, _items[index]),
    );
  }

  Widget _buildSkeletonGrid(BuildContext context) {
    final Color placeholder = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _kGalleryColumnCount,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: 20,
      itemBuilder: (context, _) => Container(color: placeholder)
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: Colors.white24),
    );
  }

  Widget _buildThumbnail(BuildContext context, FolderMediaItem item) {
    return GestureDetector(
      onTap: () => _openPreview(context, item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GalleryThumbnail(item: item),
          if (item.isVideo)
            const Positioned(
              bottom: 4,
              right: 4,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, FolderMediaItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: true,
        pageBuilder: (_, __, ___) => FolderMediaViewerScreen(item: item),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }
}

class _GalleryThumbnail extends StatefulWidget {
  final FolderMediaItem item;

  const _GalleryThumbnail({required this.item});

  @override
  State<_GalleryThumbnail> createState() => _GalleryThumbnailState();
}

class _GalleryThumbnailState extends State<_GalleryThumbnail> {
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
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (item is FolderSafItem) {
      final Uint8List? bytes;
      if (item.isVideo) {
        bytes = await MediaFolderChannel.getVideoThumbnail(item.uri.toString());
      } else {
        bytes = await MediaFolderChannel.getDocumentThumbnail(item.uri.toString(), 300, 300);
      }
      if (mounted) setState(() { _bytes = bytes; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    switch (item) {
      case FolderFileItem(:final file):
        if (item.isVideo) {
          return Container(
            color: Colors.black12,
            child: const Center(child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white)),
          );
        }
        return Image.file(file, fit: BoxFit.cover);
      case FolderSafItem():
        if (_loading) {
          final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
          return Container(color: color)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white24);
        }
        final bytes = _bytes;
        if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover);
        return Container(
          color: Colors.black12,
          child: Center(
            child: Icon(
              item.isVideo ? Icons.play_circle_outline : Icons.image_outlined,
              color: Colors.white54,
              size: 32,
            ),
          ),
        );
    }
  }
}
