import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:keklist/keklist_app.dart';
import 'package:bloc/bloc.dart';
import 'package:csv/csv.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/entities/user_content.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:share_plus/share_plus.dart';
import 'package:steganograph/steganograph.dart';

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
    on<SettingsExportAllMindsToCSV>(_shareCSVFileWithMinds);
    on<SettingsChangeMindContentVisibility>(_changeMindContentVisibility);
    on<SettingsWhatsNewShown>(_disableShowingWhatsNewUntillNewVersion);
    on<SettingsGet>(_getSettings);
    on<SettingGetWhatsNew>(_sendWhatsNewIfNeeded);
    on<SettingsChangeIsDarkMode>(_changeSettingsDarkMode);
    on<SettingsChangeOpenAIKey>(_changeOpenAIKey);
    on<SettingsUpdateShouldShowTitlesMode>(_updateShouldShowTitlesMode);
    on<SettingsChangeLanguage>(_changeLanguage);
    on<SettingsExportAllMindsToEncryptedImage>(_exportToEncryptedImage);
    on<SettingsImportAllMindsFromEncryptedImage>(_importFromEncryptedImage);

    _repository.stream.listen((settings) => add(SettingsGet())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  FutureOr<void> _shareCSVFileWithMinds(event, emit) async {
    // Получение minds.
    final Iterable<Mind> minds = _mindRepository.values;
    // Конвертация в CSV и шаринг.
    final List<List<String>> csvEntryList = minds.map((entry) => entry.toCSVEntry()).toList(growable: false);
    final String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(csvEntryList);
    final Directory temporaryDirectory = await getTemporaryDirectory();
    final String formattedDateString = DateTime.now().toString().replaceAll('.', '-');
    final File csvFile = File('${temporaryDirectory.path}/keklist_backup_data_$formattedDateString.csv');
    await csvFile.writeAsString(csv);
    SharePlus.instance.share(ShareParams(
      files: [XFile(csvFile.path)],
    ));
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

  FutureOr<void> _changeOpenAIKey(SettingsChangeOpenAIKey event, Emitter<SettingsState> emit) {
    OpenAI.apiKey = event.openAIToken;
    _repository.updateOpenAIKey(event.openAIToken);
  }

  FutureOr<void> _updateShouldShowTitlesMode(
      SettingsUpdateShouldShowTitlesMode event, Emitter<SettingsState> emit) async {
    await _repository.updateShouldShowTitles(event.value);
  }

  FutureOr<void> _changeLanguage(SettingsChangeLanguage event, Emitter<SettingsState> emit) async {
    await _repository.updateLanguage(event.language);
  }

  // TODO: extract to another bloc?

  FutureOr<void> _exportToEncryptedImage(
    SettingsExportAllMindsToEncryptedImage event,
    Emitter<SettingsState> emit,
  ) async {
    final Iterable<Mind> allUserMinds = _mindRepository.values;
    final UserContent userContent = UserContent(minds: allUserMinds.toList());
    final String userContentMessage = userContent.toBase64Message();

    try {
      final Directory tempDirectory = await getTemporaryDirectory();
      final File tempImageFile = await _createRandomPngFile(
        outputPath: '${tempDirectory.path}/random_image_for_export.png',
        totalPixels: userContentMessage.length + 10000,
      );

      // final File tempImageFile = await Isolate.run(
      //   () async {
      //     final Directory tempDirectory = await getTemporaryDirectory();
      //     return _createRandomPngFile(
      //       outputPath: '${tempDirectory.path}/random_image_for_export.png',
      //       totalPixels: userContentMessage.length + 10000,
      //     );
      //   },
      // );

      final File? stegoImageFile = await Steganograph.cloak(
        image: tempImageFile,
        message: userContentMessage,
      );
      if (stegoImageFile == null) return;
      final params = ShareParams(
        files: [XFile(stegoImageFile.path)],
        sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      emit(
        SettingsShowMessage(
          title: 'Error',
          message: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<File> _createRandomPngFile({
    String? outputPath,
    int? width,
    int? height,
    int? totalPixels,
  }) async {
    // ---- pick dimensions ----
    late final int w;
    late final int h;

    if (width != null && height != null) {
      w = width;
      h = height;
    } else if (totalPixels != null) {
      final dims = _nearSquareDims(totalPixels);
      w = dims.$1;
      h = dims.$2;
    } else {
      throw ArgumentError('Provide width & height OR totalPixels.');
    }

    // ---- generate random RGBA bytes ----
    final rnd = Random();
    final Uint8List rgba = Uint8List(w * h * 4);
    for (int i = 0; i < rgba.length; i += 4) {
      logarte.log('progress = ${i / rgba.length * 100}');
      rgba[i] = rnd.nextInt(256); // R
      rgba[i + 1] = rnd.nextInt(256); // G
      rgba[i + 2] = rnd.nextInt(256); // B
      rgba[i + 3] = 255; // A
    }

    // ---- build an image off-screen ----
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: w,
      height: h,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    // ---- encode to PNG ----
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // ---- write to file ----
    final String path = outputPath ?? '${Directory.systemTemp.path}/random_$w x $h.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Find width/height close to a square for a given total pixel count.
  (int, int) _nearSquareDims(int total) {
    final s = sqrt(total).floor();
    for (int w = s; w >= 1; w--) {
      if (total % w == 0) return (w, total ~/ w);
    }
    // Fallback (shouldn’t happen): make it Wx1
    return (total, 1);
  }

  FutureOr<void> _importFromEncryptedImage(
    SettingsImportAllMindsFromEncryptedImage event,
    Emitter<SettingsState> emit,
  ) async {
    final ImagePicker picker = ImagePicker();
    return picker.pickImage(source: ImageSource.gallery).then(
      (XFile? image) async {
        if (image == null) return;
        final String? message = await Steganograph.uncloak(File(image.path));
        if (message == null) {
          emit(
            SettingsShowMessage(
              title: 'Error!',
              message: 'Failed to import',
            ),
          );
          return;
        }
        final UserContent userContent = UserContent.fromBase64Message(message);
        await _mindRepository.createMinds(minds: userContent.minds);
        emit(
          SettingsShowMessage(
            title: 'Success',
            message: 'Imported ${userContent.minds.length} minds',
          ),
        );
      },
    );
  }

  Future<File> _assetToTempFile(String assetPath, {String? filename}) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Directory tempDirectory = await getTemporaryDirectory();
    final String outPath = '${tempDirectory.path}/${filename ?? assetPath.split('/').last}';
    final File file = File(outPath);
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return file;
  }
}
