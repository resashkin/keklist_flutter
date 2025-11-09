import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:full_swipe_back_gesture/full_swipe_back_gesture.dart';
import 'package:gap/gap.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/settings/widgets/stories_widget.dart';
import 'package:keklist/presentation/screens/tabs_settings/tabs_settings_screen.dart';
import 'package:keklist/presentation/screens/web_page/web_page_screen.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/language_picker/language_picker_screen.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'dart:async';

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

    subscribeToBloc<SettingsBloc>(onNewState: (state) {
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
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        case SettingsLoadingState state:
          if (state.isLoading) {
            EasyLoading.show();
          } else {
            EasyLoading.dismiss();
          }
          break;
      }
    })?.disposed(by: this);
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
            tiles: [
              SettingsTile.navigation(
                title: Text('Our new features'),
                enabled: false,
                trailing: Gap(0),
              ),
              CustomSettingsTile(
                child: Container(
                  color: Color.fromRGBO(27, 27, 27, 1),
                  child: Column(
                    children: [
                      StoriesWidget(
                        stories: [
                          Story(id: '1', title: 'Voices', emoji: '🎙️'),
                          Story(id: '2', title: 'Whats new', emoji: '👨‍💻'),
                          Story(id: '3', title: 'PRO', emoji: '🤝'),
                          Story(id: '4', title: 'Supermind', emoji: '🧠'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SettingsTile.navigation(
                title: Text('Release notes'),
                leading: const Icon(Icons.new_releases, color: Color.fromARGB(255, 191, 188, 191)),
                onPressed: (BuildContext context) => _showWhatsNew(),
              ),
              SettingsTile.navigation(
                title: Text('keklist PRO'),
                leading: const Icon(Icons.handshake, color: Colors.yellowAccent),
                onPressed: (BuildContext context) => _openPaywall(),
              ),
              SettingsTile.navigation(
                title: Text('keklist news [Telegram] [RU]'),
                leading: const Icon(Icons.newspaper, color: Colors.blue),
                onPressed: (BuildContext context) => _openAppNews(),
              ),
              SettingsTile.navigation(
                title: Text(context.l10n.suggestFeature),
                leading: const Icon(Icons.handyman, color: Colors.green),
                onPressed: (BuildContext context) => _openSuggestFeature(),
              ),
              SettingsTile.navigation(
                title: Text('Problem detected'),
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
                onPressed: (BuildContext context) {
                  sendEventToBloc<SettingsBloc>(SettingsExport(type: SettingsExportType.csv));
                },
              ),
              SettingsTile(
                title: Text(context.l10n.importData),
                leading: const Icon(Icons.download, color: Colors.greenAccent),
                onPressed: (BuildContext context) {
                  sendEventToBloc<SettingsBloc>(SettingsImport(type: SettingsImportType.csv));
                },
              )
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
              )
            ],
          )
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    Navigator.of(context).push(
      BackSwipePageRoute(
        builder: (context) => const LanguagePickerScreen(),
      ),
    );
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
      await launchUrl(uri);
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
        builder: (BuildContext context) => WebPageScreen(
          title: context.l10n.whatsNew,
          initialUri: Uri.parse(KeklistConstants.whatsNewURL),
        ),
      ),
    );
  }

  void _showTabsSettings() {
    Navigator.of(context).push<void>(
      BackSwipePageRoute<void>(
        builder: (BuildContext context) => const TabsSettingsScreen(),
      ),
    );
  }

  Future<void> _clearCache() async {
    final OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: context.l10n.areYouSure,
      message: 'All your offline data will be deleted. Make sure that you have already exported it.',
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
}
