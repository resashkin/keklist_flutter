import 'dart:io';

sealed class FolderMediaItem {
  bool get isVideo;
}

final class FolderFileItem extends FolderMediaItem {
  final File file;

  FolderFileItem(this.file);

  @override
  bool get isVideo {
    final String ext = file.path.split('.').last.toLowerCase();
    return const {'mp4', 'mov', 'avi', 'mkv', 'm4v'}.contains(ext);
  }
}

/// Android SAF item identified by a content:// URI.
final class FolderSafItem extends FolderMediaItem {
  final Uri uri;
  final String? mimeType;
  final DateTime? lastModified;

  FolderSafItem({required this.uri, this.mimeType, this.lastModified});

  @override
  bool get isVideo => mimeType?.startsWith('video/') ?? false;
}
