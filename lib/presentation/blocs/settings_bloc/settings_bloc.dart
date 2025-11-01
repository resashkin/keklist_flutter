import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:share_plus/share_plus.dart';

part 'settings_event.dart';
part 'settings_state.dart';

final class SettingsBloc extends Bloc<SettingsEvent, SettingsState> with DisposeBag {
  final SettingsRepository _repository;
  final MindRepository _mindRepository;

  SettingsBloc({
    required SettingsRepository repository,
    required MindRepository mindRepository,
  })  : _repository = repository,
        _mindRepository = mindRepository,
        super(
          SettingsDataState(
            settings: KeklistSettings.initial(),
          ),
        ) {
    on<SettingsExport>(_export);
    on<SettingsImport>(_import);
    on<SettingsChangeMindContentVisibility>(_changeMindContentVisibility);
    on<SettingsWhatsNewShown>(_disableShowingWhatsNewUntillNewVersion);
    on<SettingsGet>(_getSettings);
    on<SettingGetWhatsNew>(_sendWhatsNewIfNeeded);
    on<SettingsChangeIsDarkMode>(_changeSettingsDarkMode);
    on<SettingsUpdateShouldShowTitlesMode>(_updateShouldShowTitlesMode);
    on<SettingsChangeLanguage>(_changeLanguage);

    _repository.stream.listen((settings) => add(SettingsGet())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  FutureOr<void> _export(SettingsExport event, Emitter<SettingsState> emit) async {
    switch (event.type) {
      case SettingsExportType.csv:
        await _shareCSVFileWithMinds();
        break;
    }
  }

  FutureOr<void> _import(SettingsImport event, Emitter<SettingsState> emit) async {
    switch (event.type) {
      case SettingsImportType.csv:
        await _importCSVFileWithMinds();
        break;
    }
  }

  FutureOr<void> _shareCSVFileWithMinds() async {
    // Получение minds.
    final Iterable<Mind> minds = _mindRepository.values;
    // Конвертация в CSV и шаринг.
    final List<List<String>> csvEntryList = minds.map((entry) => entry.toCSVEntry()).toList(growable: false);
    final String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(csvEntryList);
    final Directory temporaryDirectory = await getTemporaryDirectory();
    final String formattedDateString = DateTime.now().toString().replaceAll('.', '-');
    final File csvFile = File('${temporaryDirectory.path}/keklist_minds_$formattedDateString.csv');
    await csvFile.writeAsString(csv);
    SharePlus.instance.share(ShareParams(
      files: [XFile(csvFile.path)],
      sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
    ));
  }

  // TODO: add parsing one row to init of Mind

  FutureOr<void> _importCSVFileWithMinds() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile pickedFile = result.files.single;
    String? csvContent;

    if (pickedFile.bytes != null) {
      csvContent = utf8.decode(pickedFile.bytes!);
    } else if (pickedFile.path != null) {
      csvContent = await File(pickedFile.path!).readAsString();
    }

    if (csvContent == null || csvContent.trim().isEmpty) {
      return;
    }

    final List<List<dynamic>> rawRows = const CsvToListConverter(
      fieldDelimiter: ';',
      shouldParseNumbers: false,
    ).convert(csvContent);

    if (rawRows.isEmpty) {
      return;
    }

    final List<Mind> mindsToImport = [];

    for (final List<dynamic> row in rawRows) {
      if (row.length < 7) {
        continue;
      }

      try {
        final String id = row[0].toString();
        final String emoji = row[1].toString();
        final String note = row[2].toString();
        final int dayIndex = int.parse(row[3].toString());
        final int sortIndex = int.parse(row[4].toString());
        final DateTime creationDate = DateTime.parse(row[5].toString());
        final String? rootIdRaw = row[6]?.toString();
        final String? rootId = (rootIdRaw == null || rootIdRaw.isEmpty || rootIdRaw == 'null') ? null : rootIdRaw;

        mindsToImport.add(
          Mind(
            id: id,
            emoji: emoji,
            note: note,
            dayIndex: dayIndex,
            creationDate: creationDate,
            sortIndex: sortIndex,
            rootId: rootId,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    if (mindsToImport.isEmpty) {
      return;
    }

    await _mindRepository.createMinds(minds: mindsToImport);
  }

  FutureOr _getSettings(SettingsGet event, Emitter<SettingsState> emit) async {
    emit(
      SettingsDataState(
        settings: _repository.value,
      ),
    );
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
      SettingsUpdateShouldShowTitlesMode event, Emitter<SettingsState> emit) async {
    await _repository.updateShouldShowTitles(event.value);
  }

  FutureOr<void> _changeLanguage(SettingsChangeLanguage event, Emitter<SettingsState> emit) async {
    await _repository.updateLanguage(event.language);
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
