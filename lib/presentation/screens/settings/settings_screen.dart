import 'dart:async';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:full_swipe_back_gesture/full_swipe_back_gesture.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/services/export_import/models/import_result.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/language_picker/language_picker_screen.dart';
import 'package:keklist/presentation/screens/settings/widgets/password_input_bottom_sheet.dart';
import 'package:keklist/presentation/screens/settings/widgets/stories_widget.dart';
import 'package:keklist/presentation/screens/tabs_settings/tabs_settings_screen.dart';
import 'package:keklist/presentation/screens/web_page/web_page_screen.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: move methods from MindBloc to SettingsBloc
// TODO: darkmode: add system mode

final class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

final class SettingsScreenState extends KekWidgetState<SettingsScreen> {
  //bool _isSensitiveContentShowed = false;
  bool _isDarkMode = false;
  String? translateLanguageCode;

  @override
  void initState() {
    super.initState();

    subscribeToBloc<SettingsBloc>(
      onNewState: (state) {
        switch (state) {
          case SettingsDataState state:
            setState(() {
              _isDarkMode = state.settings.isDarkMode;
            });
            break;
          case SettingsShowMessage state:
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(state.title),
                content: Text(state.message),
                actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
              ),
            );
          case SettingsLoadingState state:
            if (state.isLoading) {
              EasyLoading.show();
            } else {
              EasyLoading.dismiss();
            }
            break;
          case SettingsExportSuccess state:
            _showSuccessMessage(
              context.l10n.exportSuccess,
              '${context.l10n.mindsExported}: ${state.mindsCount}\n'
              '${context.l10n.audioFilesExported}: ${state.audioFilesCount}',
            );
            break;
          case SettingsExportError state:
            _showErrorMessage(context.l10n.exportError, state.message);
            break;
          case SettingsImportSuccess state:
            _showSuccessMessage(
              context.l10n.importSuccess,
              '${context.l10n.mindsImported}: ${state.mindsCount}\n'
              '${context.l10n.audioFilesImported}: ${state.audioFilesCount}',
            );
            break;
          case SettingsImportError state:
            // For invalid password error, show retry dialog
            if (state.error == ImportError.invalidPassword) {
              _handleInvalidPasswordError();
            } else {
              _showErrorMessage(context.l10n.importError, state.message);
            }
            break;
        }
      },
    )?.disposed(by: this);
    sendEventToBloc<SettingsBloc>(SettingsGet());
  }

  @override
  Widget build(BuildContext context) {
    // final lightSettingsListBackground = Color.fromRGBO(242, 242, 247, 1);
    // final darkSettingsListBackground = CupertinoColors.black;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('APPLICATION'),
            tiles: [
              // SettingsTile.navigation(title: Text('Our new features'), enabled: false, trailing: SizedBox.shrink()),
              // CustomSettingsTile(
              //   child: Container(
              //     color: Color.fromRGBO(27, 27, 27, 1),
              //     child: Column(
              //       children: [
              //         StoriesWidget(
              //           stories: [
              //             Story(id: '1', title: 'Voices', emoji: '🎙️'),
              //             Story(id: '2', title: 'Whats new', emoji: '👨‍💻'),
              //             Story(id: '3', title: 'PRO', emoji: '🤝'),
              //             Story(id: '4', title: 'Supermind', emoji: '🧠'),
              //           ],
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              SettingsTile.navigation(
                title: Text('keklist PRO'),
                leading: const Icon(Icons.handshake, color: Colors.yellowAccent),
                onPressed: (BuildContext context) => _openPaywall(),
              ),
              SettingsTile.navigation(
                title: Text(context.l10n.releaseNotes),
                leading: const Icon(Icons.new_releases, color: Color.fromARGB(255, 191, 188, 191)),
                onPressed: (BuildContext context) => _showWhatsNew(),
              ),
              SettingsTile.navigation(
                title: Text('Dev Blog [Telegram] [RU]'),
                leading: const Icon(Icons.newspaper, color: Colors.blue),
                onPressed: (BuildContext context) => _openAppNews(),
              ),
              SettingsTile.navigation(
                title: Text(context.l10n.suggestFeature),
                leading: const Icon(Icons.handyman, color: Colors.green),
                onPressed: (BuildContext context) => _openSuggestFeature(),
              ),
              SettingsTile.navigation(
                title: Text(context.l10n.emailUs),
                leading: const Icon(Icons.feedback, color: Colors.blueGrey),
                onPressed: (BuildContext context) async => await _openEmailFeedbackForm(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(context.l10n.userData.toUpperCase()),
            tiles: [
              SettingsTile(
                title: Text(context.l10n.exportData),
                leading: const Icon(Icons.upload, color: Colors.redAccent),
                onPressed: (BuildContext context) => _handleExport(),
              ),
              SettingsTile(
                title: Text(context.l10n.importData),
                leading: const Icon(Icons.download, color: Colors.greenAccent),
                onPressed: (BuildContext context) => _handleImport(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(context.l10n.appearance.toUpperCase()),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.language),
                title: Text(context.l10n.language),
                onPressed: (_) => _showLanguagePicker(),
              ),
              SettingsTile.switchTile(
                initialValue: _isDarkMode,
                leading: const Icon(Icons.dark_mode, color: Colors.grey),
                title: Text(context.l10n.darkMode),
                onToggle: (bool value) => _switchDarkMode(value),
              ),
              // SettingsTile.switchTile(
              //   initialValue: _showTitles,
              //   leading: const Icon(Icons.title, color: Colors.grey),
              //   title: Text(context.l10n.showDayDividers),
              //   onToggle: (bool value) => _switchShowTitles(value),
              // ),
              // SettingsTile.switchTile(
              //   initialValue: !_isSensitiveContentShowed,
              //   leading: const Icon(Icons.visibility_off, color: Colors.grey),
              //   title: const Text('Hide sensitive content'),
              //   onToggle: (bool value) => _switchSensitiveContentVisibility(!value),
              // ),
              // SettingsTile.navigation(
              //   title: const Text('Feature flags'),
              //   leading: const Icon(Icons.flag, color: Colors.blue),
              //   onPressed: (BuildContext context) => _showFeatureFlags(),
              // ),
              SettingsTile.navigation(
                title: Text(context.l10n.tabsSettings),
                leading: const Icon(Icons.dashboard, color: Colors.blue),
                onPressed: (_) => _showTabsSettings(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(context.l10n.about.toUpperCase()),
            tiles: [
              SettingsTile.navigation(
                title: Text(context.l10n.sourceCode),
                leading: const Icon(Icons.code, color: Colors.yellow),
                onPressed: (BuildContext context) async => await _openSourceCode(),
              ),
              SettingsTile.navigation(
                title: Text(context.l10n.termsOfUse),
                leading: const Icon(Icons.verified_user, color: Colors.grey),
                onPressed: (BuildContext context) => _openTermsOfUse(),
              ),
              SettingsTile.navigation(
                title: Text(context.l10n.privacyPolicy),
                leading: const Icon(Icons.privacy_tip, color: Colors.grey),
                onPressed: (BuildContext context) => _openPrivacyPolicy(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(context.l10n.dangerZone.toUpperCase()),
            tiles: [
              SettingsTile(
                title: Text(context.l10n.clearOnDeviceData),
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: (BuildContext context) async => await _clearCache(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    Navigator.of(context).push(BackSwipePageRoute(builder: (context) => const LanguagePickerScreen()));
  }

  Future<void> _openEmailFeedbackForm() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: KeklistConstants.feedbackEmail,
      query: 'subject=Feedback about keklist',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openSourceCode() async {
    final Uri uri = Uri.parse(KeklistConstants.sourceCodeURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openSuggestFeature() async {
    final Uri uri = Uri.parse(KeklistConstants.featureSuggestionsURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final Uri uri = Uri.parse(KeklistConstants.privacyURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openTermsOfUse() async {
    final Uri uri = Uri.parse(KeklistConstants.termsOfUseURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openAppNews() async {
    final Uri uri = Uri.parse(KeklistConstants.newsTelegramChannelURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: .externalApplication);
    }
  }

  Future<void> _openPaywall() async {
    await RevenueCatUI.presentPaywall();
  }

  void _switchDarkMode(bool value) {
    sendEventToBloc<SettingsBloc>(SettingsChangeIsDarkMode(isDarkMode: value));
  }

  // void _switchShowTitles(bool value) {
  //   sendEventToBloc<SettingsBloc>(SettingsUpdateShouldShowTitlesMode(value: value));
  // }

  void _showWhatsNew() {
    Navigator.of(context).push<void>(
      BackSwipePageRoute<void>(
        builder: (BuildContext context) =>
            WebPageScreen(title: context.l10n.whatsNew, initialUri: Uri.parse(KeklistConstants.whatsNewURL)),
      ),
    );
  }

  void _showTabsSettings() {
    Navigator.of(
      context,
    ).push<void>(BackSwipePageRoute<void>(builder: (BuildContext context) => const TabsSettingsScreen()));
  }

  Future<void> _clearCache() async {
    final OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: context.l10n.areYouSure,
      message: context.l10n.clearOfflineDataWarning,
      cancelLabel: context.l10n.cancel,
      okLabel: context.l10n.clearCache,
      isDestructiveAction: true,
    );
    switch (result) {
      case OkCancelResult.ok:
        sendEventToBloc<MindBloc>(MindClearCache());
        break;
      case OkCancelResult.cancel:
        break;
    }
  }

  Future<void> _handleExport() async {
    // Show password input bottom sheet
    final password = await PasswordInputBottomSheet.show(
      context: context,
      title: context.l10n.exportPassword,
      isOptional: true,
    );

    if (password == null) return; // User cancelled

    // Export as ZIP with optional password
    sendEventToBloc<SettingsBloc>(
      SettingsExport(
        type: SettingsExportType.zip,
        password: password.isEmpty ? null : password,
      ),
    );
  }

  File? _lastImportFile;

  Future<void> _handleImport() async {
    // Show file picker for CSV and ZIP files
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'zip'],
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.single;
    if (pickedFile.path == null) return;

    final file = File(pickedFile.path!);
    _lastImportFile = file;

    // Check if file is encrypted by examining magic bytes
    // ZIP files start with "PK" (0x50 0x4B), encrypted files don't
    bool needsPassword = false;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 2) {
        final isZip = bytes[0] == 0x50 && bytes[1] == 0x4B;
        needsPassword = !isZip && !pickedFile.name.endsWith('.csv');
      }
    } catch (e) {
      // If we can't read the file, assume no password needed
      needsPassword = false;
    }

    String? password;
    if (needsPassword) {
      password = await PasswordInputBottomSheet.show(
        context: context,
        title: context.l10n.importPassword,
        isOptional: false,
      );

      if (password == null) return; // User cancelled
    }

    // Trigger import
    sendEventToBloc<SettingsBloc>(
      SettingsImport(
        file: file,
        password: password,
      ),
    );
  }

  Future<void> _handleInvalidPasswordError() async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: context.l10n.incorrectPassword,
      message: context.l10n.incorrectPasswordMessage,
      okLabel: context.l10n.retry,
      cancelLabel: context.l10n.cancel,
    );

    if (result == OkCancelResult.ok && _lastImportFile != null) {
      // Retry with new password
      final password = await PasswordInputBottomSheet.show(
        context: context,
        title: context.l10n.importPassword,
        isOptional: false,
      );

      if (password != null) {
        sendEventToBloc<SettingsBloc>(
          SettingsImport(
            file: _lastImportFile!,
            password: password,
          ),
        );
      }
    }
  }

  void _showSuccessMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(context.l10n.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(context.l10n.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
