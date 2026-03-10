import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/export_import/export_import_service.dart';
import 'package:keklist/domain/services/export_import/models/export_result.dart';
import 'package:keklist/domain/services/export_import/models/import_result.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

part 'settings_event.dart';
part 'settings_state.dart';

final class SettingsBloc extends Bloc<SettingsEvent, SettingsState> with DisposeBag {
  final SettingsRepository _repository;
  final ExportImportService _exportImportService;

  SettingsBloc({required SettingsRepository repository, required ExportImportService exportImportService})
    : _repository = repository,
      _exportImportService = exportImportService,
      super(SettingsDataState(settings: KeklistSettings.initial())) {
    on<SettingsExport>(_export);
    on<SettingsImport>(_import);
    on<SettingsChangeMindContentVisibility>(_changeMindContentVisibility);
    on<SettingsWhatsNewShown>(_disableShowingWhatsNewUntillNewVersion);
    on<SettingsGet>(_getSettings);
    on<SettingGetWhatsNew>(_sendWhatsNewIfNeeded);
    on<SettingsChangeIsDarkMode>(_changeSettingsDarkMode);
    on<SettingsUpdateShouldShowTitlesMode>(_updateShouldShowTitlesMode);
    on<SettingsChangeLanguage>(_changeLanguage);
    on<SettingsEnableDebugMenu>(_enableDebugMenu);
    on<SettingsTogglePhotoVideoSource>(_togglePhotoVideoSource);
    on<SettingsToggleWeatherSource>(_toggleWeatherSource);
    on<SettingsUpdateWeatherLocation>(_updateWeatherLocation);
    on<SettingsUpdateMediaFolderSource>(_updateMediaFolderSource);

    _repository.stream.listen((settings) => add(SettingsGet())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  FutureOr<void> _export(SettingsExport event, Emitter<SettingsState> emit) async {
    emit(SettingsLoadingState(true));

    try {
      final ExportResult result;

      switch (event.type) {
        case SettingsExportType.csv:
          result = await _exportImportService.exportToCSV();
          break;
        case SettingsExportType.zip:
          result = await _exportImportService.exportToZIP(password: event.password);
          break;
      }

      emit(SettingsLoadingState(false));

      switch (result) {
        case ExportSuccess success:
          // Handle based on export action
          if (event.action == SettingsExportAction.saveToFiles) {
            // Save to file system using file picker
            final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
            final suggestedName = 'keklist_export_$timestamp.zip';

            // Read the bytes from the temp file
            final tempFile = File(success.file.path);
            final bytes = await tempFile.readAsBytes();

            final outputPath = await FilePicker.platform.saveFile(
              dialogTitle: 'Save export file',
              fileName: suggestedName,
              type: FileType.custom,
              allowedExtensions: ['zip'],
              bytes: bytes,
            );

            if (outputPath != null) {
              emit(
                SettingsExportSuccess(
                  mindsCount: success.mindsCount,
                  audioFilesCount: success.audioFilesCount,
                  isEncrypted: success.isEncrypted,
                ),
              );
            } else {
              // User cancelled the save dialog
              emit(SettingsLoadingState(false));
            }
          } else {
            // Share the exported file with explicit MIME type
            // Use application/zip for both .zip and .encrypted files
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(success.file.path, mimeType: 'application/zip')],
                sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
              ),
            );

            emit(
              SettingsExportSuccess(
                mindsCount: success.mindsCount,
                audioFilesCount: success.audioFilesCount,
                isEncrypted: success.isEncrypted,
              ),
            );
          }
          break;

        case ExportFailure failure:
          emit(SettingsExportError(message: failure.message));
          break;
      }
    } catch (e) {
      emit(SettingsLoadingState(false));
      emit(SettingsExportError(message: 'Export failed: $e'));
    }
  }

  FutureOr<void> _import(SettingsImport event, Emitter<SettingsState> emit) async {
    emit(SettingsLoadingState(true));

    try {
      final result = await _exportImportService.importFromFile(event.file, password: event.password);

      emit(SettingsLoadingState(false));

      switch (result) {
        case ImportSuccess success:
          emit(SettingsImportSuccess(mindsCount: success.mindsCount, audioFilesCount: success.audioFilesCount));
          break;

        case ImportFailure failure:
          emit(SettingsImportError(error: failure.error, message: failure.message));
          break;
      }
    } catch (e) {
      emit(SettingsLoadingState(false));
      emit(SettingsImportError(error: ImportError.unknownError, message: 'Import failed: $e'));
    }
  }

  FutureOr _getSettings(SettingsGet event, Emitter<SettingsState> emit) async {
    emit(SettingsDataState(settings: _repository.value));
  }

  FutureOr<void> _disableShowingWhatsNewUntillNewVersion(
    SettingsWhatsNewShown event,
    Emitter<SettingsState> emit,
  ) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appVersion = '${packageInfo.version} ${packageInfo.buildNumber}';

    await _repository.updatePreviousAppVersion(appVersion);
  }

  FutureOr<void> _changeMindContentVisibility(
    SettingsChangeMindContentVisibility event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateMindContentVisibility(event.isVisible);
  }

  FutureOr<void> _changeSettingsDarkMode(SettingsChangeIsDarkMode event, Emitter<SettingsState> emit) async {
    await _repository.updateDarkMode(event.isDarkMode);
  }

  FutureOr<void> _sendWhatsNewIfNeeded(SettingGetWhatsNew event, Emitter<SettingsState> emit) async {
    // Cбор и отправка стейта Whats new.
    final String? previousAppVersion = _repository.value.previousAppVersion;
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appVersion = '${packageInfo.version} ${packageInfo.buildNumber}';
    final bool needToShowWhatsNewOnStart = previousAppVersion != appVersion;
    if (needToShowWhatsNewOnStart) {
      emit(SettingsShowWhatsNew());
    }
  }

  FutureOr<void> _updateShouldShowTitlesMode(
    SettingsUpdateShouldShowTitlesMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateShouldShowTitles(event.value);
  }

  FutureOr<void> _changeLanguage(SettingsChangeLanguage event, Emitter<SettingsState> emit) async {
    await _repository.updateLanguage(event.language);
  }

  FutureOr<void> _enableDebugMenu(SettingsEnableDebugMenu event, Emitter<SettingsState> emit) async {
    final currentSettings = _repository.value;
    final updatedSettings = KeklistSettings(
      isMindContentVisible: currentSettings.isMindContentVisible,
      previousAppVersion: currentSettings.previousAppVersion,
      isDarkMode: currentSettings.isDarkMode,
      shouldShowTitles: currentSettings.shouldShowTitles,
      userName: currentSettings.userName,
      language: currentSettings.language,
      dataSchemaVersion: currentSettings.dataSchemaVersion,
      hasSeenLazyOnboarding: currentSettings.hasSeenLazyOnboarding,
      isDebugMenuVisible: true,
      isPhotoVideoSourceEnabled: currentSettings.isPhotoVideoSourceEnabled,
      isWeatherSourceEnabled: currentSettings.isWeatherSourceEnabled,
      weatherLatitude: currentSettings.weatherLatitude,
      weatherLongitude: currentSettings.weatherLongitude,
      isMediaFolderSourceEnabled: currentSettings.isMediaFolderSourceEnabled,
      mediaFolderPath: currentSettings.mediaFolderPath,
      isMediaFolderRecursive: currentSettings.isMediaFolderRecursive,
    );
    await _repository.updateSettings(updatedSettings);
  }

  FutureOr<void> _togglePhotoVideoSource(SettingsTogglePhotoVideoSource event, Emitter<SettingsState> emit) async {
    await _repository.updateIsPhotoVideoSourceEnabled(event.isEnabled);
  }

  FutureOr<void> _toggleWeatherSource(SettingsToggleWeatherSource event, Emitter<SettingsState> emit) async {
    await _repository.updateWeatherSettings(isEnabled: event.isEnabled);
  }

  FutureOr<void> _updateWeatherLocation(SettingsUpdateWeatherLocation event, Emitter<SettingsState> emit) async {
    await _repository.updateWeatherSettings(latitude: event.latitude, longitude: event.longitude);
  }

  FutureOr<void> _updateMediaFolderSource(SettingsUpdateMediaFolderSource event, Emitter<SettingsState> emit) async {
    await _repository.updateMediaFolderSource(
      isEnabled: event.isEnabled,
      folderPath: event.folderPath,
      isRecursive: event.isRecursive,
    );
  }

  // FutureOr<void> _exportToEncryptedImage(
  //   SettingsExportMindsToEncryptedImage event,
  //   Emitter<SettingsState> emit,
  // ) async {
  //   final List<Mind> periodedUserMinds = MindUtils.findLast30DaysMinds(allMinds: _mindRepository.values.toList());
  //   final UserContent userContent = UserContent(minds: periodedUserMinds);
  //   final String userContentMessage = userContent.toBase64Message();

  //   try {
  //     final File tempImageFile = await createSolidSquareImageFileSkia(
  //       totalPixels: userContentMessage.length * 8,
  //       color: Colors.black,
  //     );

  //     final File? stegoImageFile = await Steganograph.cloak(
  //       image: tempImageFile,
  //       message: userContentMessage,
  //     );
  //     if (stegoImageFile == null) return;
  //     final params = ShareParams(
  //       files: [XFile(stegoImageFile.path)],
  //       sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
  //     );
  //     await SharePlus.instance.share(params);
  //   } catch (e) {
  //     emit(
  //       SettingsShowMessage(
  //         title: 'Error',
  //         message: e.toString(),
  //       ),
  //     );
  //     rethrow;
  //   }
  // }

  // Future<File> createSolidSquareImageFileSkia({
  //   required int totalPixels,
  //   required Color color,
  //   String filename = 'solid.png',
  // }) async {
  //   final int side = math.sqrt(totalPixels).ceil();
  //   final dartUI.PictureRecorder recorder = dartUI.PictureRecorder();
  //   final Canvas canvas = Canvas(
  //     recorder,
  //     Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
  //   );

  //   final Paint paint = Paint()..color = color;
  //   canvas.drawRect(Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()), paint);

  //   final dartUI.Picture picture = recorder.endRecording();
  //   final dartUI.Image image = await picture.toImage(side, side);

  //   final ByteData? byteData = await image.toByteData(format: dartUI.ImageByteFormat.png);
  //   if (byteData == null) {
  //     throw StateError('Failed to encode PNG.');
  //   }

  //   final Uint8List bytes = byteData.buffer.asUint8List();
  //   final Directory dir = await getTemporaryDirectory();
  //   final File file = File('${dir.path}/$filename');
  //   await file.writeAsBytes(bytes, flush: true);
  //   return file;
  // }

  // FutureOr<void> _importFromEncryptedImage(
  //   SettingsImportAllMindsFromEncryptedImage event,
  //   Emitter<SettingsState> emit,
  // ) async {
  //   final ImagePicker picker = ImagePicker();
  //   return picker.pickImage(source: ImageSource.gallery).then(
  //     (XFile? image) async {
  //       if (image == null) return;
  //       final String? message = await Steganograph.uncloak(File(image.path));
  //       if (message == null) {
  //         emit(
  //           SettingsShowMessage(
  //             title: 'Error!',
  //             message: 'Failed to import',
  //           ),
  //         );
  //         return;
  //       }
  //       final UserContent userContent = UserContent.fromBase64Message(message);
  //       await _mindRepository.createMinds(minds: userContent.minds);
  //       emit(
  //         SettingsShowMessage(
  //           title: 'Success',
  //           message: 'Imported ${userContent.minds.length} minds',
  //         ),
  //       );
  //     },
  //   );
  // }

  // Future<File> _assetToTempFile(String assetPath, {String? filename}) async {
  //   final ByteData data = await rootBundle.load(assetPath);
  //   final Directory tempDirectory = await getTemporaryDirectory();
  //   final String outPath = '${tempDirectory.path}/${filename ?? assetPath.split('/').last}';
  //   final File file = File(outPath);
  //   await file.writeAsBytes(
  //     data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  //     flush: true,
  //   );
  //   return file;
  // }
}
