import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/screens/tabs_container/tabs_container_screen.dart';
import 'package:keklist/l10n/app_localizations.dart';
import 'package:keklist/domain/services/language_manager.dart';

final class KeklistApp extends StatefulWidget {
  const KeklistApp({super.key});

  @override
  State<KeklistApp> createState() => KeklistAppState();
}

final class KeklistAppState extends KekWidgetState<KeklistApp> {
  bool _isDarkMode = true;
  SupportedLanguage _currentLanguage = SupportedLanguage.english;

  @override
  void initState() {
    super.initState();

    subscribeToBloc<SettingsBloc>(
      onNewState: (state) {
        if (state is SettingsDataState) {
          if (state.settings.openAIKey != null) {
            OpenAI.apiKey = state.settings.openAIKey!;
          }
          setState(() {
            _isDarkMode = state.settings.isDarkMode;
            _currentLanguage = state.settings.language;
            SensitiveWidget.isProtected = !state.settings.isMindContentVisible;
          });
        }
      },
    )?.disposed(by: this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keklist',
      home: const TabsContainerScreen(),
      theme: _isDarkMode ? Themes.dark : Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeMode.light,
      locale: _currentLanguage.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: EasyLoading.init(),
    );
  }
}
