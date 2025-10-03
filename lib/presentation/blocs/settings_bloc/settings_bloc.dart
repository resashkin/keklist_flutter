import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as dartUI;

import 'package:flutter/material.dart';
import 'package:keklist/domain/period.dart';
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
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
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
    on<SettingsExportMindsToEncryptedImage>(_exportToEncryptedImage);
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

  FutureOr<void> _exportToEncryptedImage(
    SettingsExportMindsToEncryptedImage event,
    Emitter<SettingsState> emit,
  ) async {
    final List<Mind> periodedUserMinds = MindUtils.findLast30DaysMinds(allMinds: _mindRepository.values.toList());
    final UserContent userContent = UserContent(minds: periodedUserMinds);
    final String userContentMessage = userContent.toBase64Message();

    try {
      final File tempImageFile = await createSolidSquareImageFileSkia(
        totalPixels: userContentMessage.length * 8,
        color: Colors.black,
      );

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

  Future<File> createSolidSquareImageFileSkia({
    required int totalPixels,
    required Color color,
    String filename = 'solid.png',
  }) async {
    final int side = math.sqrt(totalPixels).ceil();
    final dartUI.PictureRecorder recorder = dartUI.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
    );

    final Paint paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()), paint);

    final dartUI.Picture picture = recorder.endRecording();
    final dartUI.Image image = await picture.toImage(side, side);

    final ByteData? byteData = await image.toByteData(format: dartUI.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode PNG.');
    }

    final Uint8List bytes = byteData.buffer.asUint8List();
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
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
