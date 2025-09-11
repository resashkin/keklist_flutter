import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:keklist/presentation/blocs/mind_bloc/mind_bloc.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/screens/tabs_settings/tabs_settings_screen.dart';
import 'package:keklist/presentation/screens/web_page/web_page_screen.dart';
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
  bool _showTitles = true;
  bool _clearCacheVisible = true;
  String _openAiKey = '';
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
            _openAiKey = state.settings.openAIKey ?? '';
            _showTitles = state.settings.shouldShowTitles;
          });
          break;
        case SettingsLoadingState state:
          if (state.isLoading) {
            EasyLoading.show();
          } else {
            EasyLoading.dismiss();
          }
          break;
        // Offline mode removed - no upload states needed
      }
    })?.disposed(by: this);
    sendEventToBloc<SettingsBloc>(SettingsGet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('USER DATA'.toUpperCase()),
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
                title: const Text('Export to CSV'),
                leading: const Icon(Icons.file_download, color: Colors.brown),
                onPressed: (BuildContext context) {
                  // TODO: Add loading
                  sendEventToBloc<SettingsBloc>(SettingsExportAllMindsToCSV());
                },
              )
            ],
          ),
          SettingsSection(
            title: Text('Appearance'.toUpperCase()),
            tiles: [
              SettingsTile.switchTile(
                initialValue: _isDarkMode,
                leading: const Icon(Icons.dark_mode, color: Colors.grey),
                title: const Text('Dark mode'),
                onToggle: (bool value) => _switchDarkMode(value),
              ),
              SettingsTile.switchTile(
                initialValue: _showTitles,
                leading: const Icon(Icons.title, color: Colors.grey),
                title: const Text('Show day dividers'),
                onToggle: (bool value) => _switchShowTitles(value),
              ),
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
                title: const Text('Tabs settings'),
                leading: const Icon(Icons.dashboard, color: Colors.blue),
                onPressed: (BuildContext context) => _showTabsSettings(),
              ),
            ],
          ),
          SettingsSection(
            title: Text('About'.toUpperCase()),
            tiles: [
              SettingsTile.navigation(
                title: const Text('Whats new?'),
                leading: const Icon(Icons.new_releases, color: Colors.purple),
                onPressed: (BuildContext context) {
                  _showWhatsNew();
                },
              ),
              SettingsTile.navigation(
                title: const Text('Suggest a feature'),
                leading: const Icon(Icons.handyman, color: Colors.yellow),
                onPressed: (BuildContext context) {
                  _openFeatureSuggestion();
                },
              ),
              SettingsTile.navigation(
                title: const Text('Send feedback'),
                leading: const Icon(Icons.feedback, color: Colors.blue),
                onPressed: (BuildContext context) async {
                  await _openEmailFeedbackForm();
                },
              ),
              SettingsTile.navigation(
                title: const Text('Source code'),
                leading: const Icon(Icons.code, color: Colors.yellow),
                onPressed: (BuildContext context) async {
                  await _openSourceCode();
                },
              ),
              SettingsTile.navigation(
                title: const Text('Terms Of Use'),
                leading: const Icon(Icons.verified_user, color: Colors.grey),
                onPressed: (BuildContext context) => _openTermsOfUse(),
              ),
              SettingsTile.navigation(
                title: const Text('Privacy Policy'),
                leading: const Icon(Icons.privacy_tip, color: Colors.grey),
                onPressed: (BuildContext context) => _openPrivacyPolicy(),
              ),
            ],
          ),
          SettingsSection(
            title: Text('DANGER ZONE'.toUpperCase()),
            tiles: [
              if (_clearCacheVisible) ...{
                SettingsTile(
                  title: const Text('Clear on-device data'),
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: (BuildContext context) async => await _clearCache(),
                )
              },
            ],
          )
        ],
      ),
    );
  }

  Future<void> _openEmailFeedbackForm() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: KeklistConstants.feedbackEmail,
      query: 'subject=Feedback about Keklist',
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

  Future<void> _showOpenAITokenChanger() async {
    String openAiToken = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Open AI Token'),
          content: TextField(
            onChanged: (value) => openAiToken = value,
            decoration: const InputDecoration(
              hintText: 'Enter token here',
              labelText: 'Token',
            ),
            controller: TextEditingController(text: _openAiKey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _openAiKey = openAiToken;
                Navigator.of(context).pop();
                sendEventToBloc<SettingsBloc>(SettingsChangeOpenAIKey(openAIToken: openAiToken));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _switchSensitiveContentVisibility(bool value) {
    sendEventToBloc<SettingsBloc>(SettingsChangeMindContentVisibility(isVisible: value));
  }

  void _switchDarkMode(bool value) {
    sendEventToBloc<SettingsBloc>(SettingsChangeIsDarkMode(isDarkMode: value));
  }

  void _switchShowTitles(bool value) {
    sendEventToBloc<SettingsBloc>(SettingsUpdateShouldShowTitlesMode(value: value));
  }

  void _showWhatsNew() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WebPageScreen(
          title: 'Whats new?',
          initialUri: Uri.parse(KeklistConstants.whatsNewURL),
        ),
      ),
    );
  }

  // void _showFeatureFlags() {
  //   Navigator.of(context).push<void>(
  //     MaterialPageRoute<void>(
  //       builder: (BuildContext context) => const FeatureFlagScreen(),
  //     ),
  //   );
  // }

  void _showTabsSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const TabsSettingsScreen(),
      ),
    );
  }

  Future<void> _clearCache() async {
    final OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: 'Are you sure?',
      message: 'All your offline data will be deleted. Make sure that you have already exported it.',
      cancelLabel: 'Cancel',
      okLabel: 'Clear cache',
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
