import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
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

import 'dart:async';
import 'dart:developer';

import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
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
  // String _openAiKey = '';
  String? translateLanguageCode;

  @override
  void initState() {
    super.initState();

    subscribeToBloc<SettingsBloc>(onNewState: (state) {
      switch (state) {
        case SettingsDataState state:
          setState(() {
            // _isSensitiveContentShowed = state.settings.isMindContentVisible;
            _isDarkMode = state.settings.isDarkMode;
            // _openAiKey = state.settings.openAIKey ?? '';
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
    const stories = [
      Story(id: '1', title: 'Planner'),
      Story(id: '2', title: 'Focus'),
      Story(id: '3', title: 'Sync'),
      Story(id: '4', title: 'Cache'),
      Story(id: '5', title: 'Notes'),
    ];

    // final lightSettingsListBackground = Color.fromRGBO(242, 242, 247, 1);
    // final darkSettingsListBackground = CupertinoColors.black;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Developer block'),
            tiles: [
              SettingsTile.navigation(
                title: Text('Last features'),
                enabled: false,
                trailing: Gap(0),
              ),
              CustomSettingsTile(
                child: Container(
                  color: Color.fromRGBO(27, 27, 27, 1),
                  child: Column(
                    children: [
                      StoriesWidget(stories: stories),
                    ],
                  ),
                ),
              ),
              SettingsTile.navigation(
                title: Text('keklist PRO'),
                leading: const Icon(Icons.handshake, color: Colors.yellowAccent),
                onPressed: (BuildContext context) => openPaywall(),
              ),
              SettingsTile.navigation(
                title: Text('Chat with developer'),
                leading: const Icon(Icons.chat, color: Colors.blue),
                onPressed: (BuildContext context) => openPaywall(),
              ),
              SettingsTile.navigation(
                title: Text(context.l10n.suggestFeature),
                leading: const Icon(Icons.handyman, color: Colors.green),
                onPressed: (BuildContext context) => _openFeatureSuggestion(),
              ),
              SettingsTile.navigation(
                title: Text('Send feedback email'),
                leading: const Icon(Icons.feedback, color: Colors.blueGrey),
                onPressed: (BuildContext context) async => await _openEmailFeedbackForm(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(context.l10n.userData.toUpperCase()),
            tiles: [
              // NOTE: Open AI is temporary disabled.
              // SettingsTile(
              //   title: const Text('Setup OpenAI Token'),
              //   leading: const Icon(Icons.chat, color: Colors.greenAccent),
              //   onPressed: (BuildContext context) async {
              //     await _showOpenAITokenChanger();
              //   },
              // ),
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
                title: Text(context.l10n.whatsNew),
                leading: const Icon(Icons.new_releases, color: Colors.purple),
                onPressed: (BuildContext context) => _showWhatsNew(),
              ),
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

  Future<void> _openFeatureSuggestion() async {
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

  void openPaywall() async {
    final paywallResult = await RevenueCatUI.presentPaywall();
    //log('Paywall result: $paywallResult');
  }

  // Future<void> _showOpenAITokenChanger() async {
  //   String openAiToken = '';

  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(context.l10n.setOpenAIToken),
  //         content: TextField(
  //           onChanged: (value) => openAiToken = value,
  //           decoration: const InputDecoration(
  //             hintText: 'Enter token here',
  //             labelText: 'Token',
  //           ),
  //           controller: TextEditingController(text: _openAiKey),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text(context.l10n.cancel),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               _openAiKey = openAiToken;
  //               Navigator.of(context).pop();
  //               sendEventToBloc<SettingsBloc>(SettingsChangeOpenAIKey(openAIToken: openAiToken));
  //             },
  //             child: Text(context.l10n.save),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
