import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Lightweight repository responsible for managing app-specific file storage.
/// Keeps all user generated assets inside a dedicated folder under the app
/// documents directory to simplify clean up and backup.
final class AppFileRepository {
  const AppFileRepository();

  static const String _userRootFolderName = 'user_files';
  static const String _audioFolderName = 'audio';

  /// Returns the absolute path to the user root folder, creating it on demand.
  Future<Directory> _ensureUserRoot() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final Directory userDirectory = Directory('${documentsDirectory.path}/$_userRootFolderName');
    if (!await userDirectory.exists()) {
      await userDirectory.create(recursive: true);
    }
    return userDirectory;
  }

  /// Returns the audio recordings directory inside the user root.
  Future<Directory> _ensureAudioDirectory() async {
    final Directory userRoot = await _ensureUserRoot();
    final Directory audioDirectory = Directory('${userRoot.path}/$_audioFolderName');
    if (!await audioDirectory.exists()) {
      await audioDirectory.create(recursive: true);
    }
    return audioDirectory;
  }

  /// Creates (but does not write to) a unique audio file and returns both the
  /// `File` handle and an app-relative path that can be persisted inside notes.
  Future<AppFileHandle> createAudioFile({String extension = 'm4a'}) async {
    final Directory audioDirectory = await _ensureAudioDirectory();
    final String fileName = '${const Uuid().v4()}.$extension';
    final File file = File('${audioDirectory.path}/$fileName');
    return AppFileHandle(
      file: file,
      relativePath: '$_audioFolderName/$fileName',
    );
  }

  /// Resolves an app-relative path (obtained from [AppFileHandle.relativePath])
  /// into an absolute on-disk path.
  Future<String> resolveAbsolutePath(String relativePath) async {
    final Directory root = await _ensureUserRoot();
    return '${root.path}/$relativePath';
  }
}

/// Represents a file created inside the user storage area.
final class AppFileHandle {
  final File file;
  final String relativePath;

  const AppFileHandle({
    required this.file,
    required this.relativePath,
  });
}
