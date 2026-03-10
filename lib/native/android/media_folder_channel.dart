import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Dart wrapper for the Android-side [MediaFolderPlugin] Kotlin plugin.
/// All methods are Android-only; callers must guard with [Platform.isAndroid].
class MediaFolderChannel {
  static const _channel = MethodChannel('com.sashkyn.emodzen/media_folder');

  static final LinkedHashMap<String, Uint8List> _thumbCache = LinkedHashMap();
  static final LinkedHashMap<String, Uint8List> _videoCache = LinkedHashMap();
  static const int _maxCache = 300;

  /// Opens the Android SAF directory picker pre-navigated to DCIM/Camera.
  /// Returns the tree URI string, or null if cancelled.
  /// Automatically persists URI permissions across app restarts.
  static Future<String?> openDocumentTree() async {
    return _channel.invokeMethod<String>('openDocumentTree');
  }

  /// Lists children of the SAF tree at [treeUri].
  /// Pass [recursive] = true to include all subdirectory contents.
  static Future<List<SafFileInfo>> listFiles(String treeUri, {bool recursive = false}) async {
    final result = await _channel.invokeListMethod<Map>('listFiles', {
      'treeUri': treeUri,
      'recursive': recursive,
    });
    return (result ?? [])
        .map((e) => SafFileInfo.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Reads the full content of a document URI as bytes.
  static Future<Uint8List?> getDocumentContent(String uri) {
    return _channel.invokeMethod<Uint8List>('getDocumentContent', {'uri': uri});
  }

  /// Returns a JPEG thumbnail for an image document URI, with in-memory cache.
  static Future<Uint8List?> getDocumentThumbnail(String uri, double width, double height) async {
    final key = '${uri}_${width.toInt()}x${height.toInt()}';
    if (_thumbCache.containsKey(key)) return _thumbCache[key];
    final bytes = await _channel.invokeMethod<Uint8List>('getDocumentThumbnail', {
      'uri': uri,
      'width': width.toInt(),
      'height': height.toInt(),
    });
    if (bytes != null) {
      if (_thumbCache.length >= _maxCache) _thumbCache.remove(_thumbCache.keys.first);
      _thumbCache[key] = bytes;
    }
    return bytes;
  }

  /// Returns a JPEG thumbnail of the first frame of a video document URI,
  /// with in-memory cache.
  static Future<Uint8List?> getVideoThumbnail(String uri) async {
    if (_videoCache.containsKey(uri)) return _videoCache[uri];
    final bytes = await _channel.invokeMethod<Uint8List>('getVideoThumbnail', {'uri': uri});
    if (bytes != null) {
      if (_videoCache.length >= _maxCache) _videoCache.remove(_videoCache.keys.first);
      _videoCache[uri] = bytes;
    }
    return bytes;
  }
}

class SafFileInfo {
  final String uri;
  final String? name;
  final String? mimeType;
  final DateTime? lastModified;
  final bool isDirectory;

  const SafFileInfo({
    required this.uri,
    this.name,
    this.mimeType,
    this.lastModified,
    required this.isDirectory,
  });

  factory SafFileInfo.fromMap(Map<String, dynamic> map) {
    final int? ms = map['lastModifiedMs'] as int?;
    return SafFileInfo(
      uri: map['uri'] as String,
      name: map['name'] as String?,
      mimeType: map['mimeType'] as String?,
      lastModified: ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null,
      isDirectory: map['isDirectory'] as bool? ?? false,
    );
  }
}
