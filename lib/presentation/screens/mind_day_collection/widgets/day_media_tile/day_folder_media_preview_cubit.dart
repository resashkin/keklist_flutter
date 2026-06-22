import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:keklist/native/android/media_folder_channel.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart' as kek_date;
import 'package:keklist/presentation/screens/date_gallery/folder_media_item.dart';

sealed class DayFolderMediaPreviewState {}

class DayFolderMediaPreviewLoading extends DayFolderMediaPreviewState {}

class DayFolderMediaPreviewEmpty extends DayFolderMediaPreviewState {}

class DayFolderMediaPreviewData extends DayFolderMediaPreviewState {
  final List<FolderMediaItem> files;
  final int totalCount;

  DayFolderMediaPreviewData({required this.files, required this.totalCount});
}

final class DayFolderMediaPreviewCubit extends Cubit<DayFolderMediaPreviewState> {
  DayFolderMediaPreviewCubit() : super(DayFolderMediaPreviewLoading());

  Future<void> load(int dayIndex, String folderPath, {bool recursive = false}) async {
    emit(DayFolderMediaPreviewLoading());

    final DateTime dayDate = kek_date.DateUtils.getDateFromDayIndex(dayIndex);
    final DateTime startOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final List<FolderMediaItem> items;
    if (Platform.isAndroid) {
      items = await _loadSafItems(folderPath, startOfDay, endOfDay, recursive: recursive);
    } else {
      items = _loadFileItems(folderPath, startOfDay, endOfDay, recursive: recursive);
    }

    if (items.isEmpty) {
      emit(DayFolderMediaPreviewEmpty());
      return;
    }

    emit(DayFolderMediaPreviewData(
      files: items.take(5).toList(),
      totalCount: items.length,
    ));
  }

  List<FolderMediaItem> _loadFileItems(
    String folderPath,
    DateTime startOfDay,
    DateTime endOfDay, {
    bool recursive = false,
  }) {
    final Directory dir = Directory(folderPath);
    if (!dir.existsSync()) return [];

    final List<File> files = dir
        .listSync(recursive: recursive)
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

  Future<List<FolderMediaItem>> _loadSafItems(
    String treeUriStr,
    DateTime startOfDay,
    DateTime endOfDay, {
    bool recursive = false,
  }) async {
    try {
      final List<SafFileInfo> all = await MediaFolderChannel.listFiles(treeUriStr, recursive: recursive);
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
}
