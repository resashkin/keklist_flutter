import 'package:material_ui/material_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:keklist/domain/repositories/settings/keklist_theme_mode.dart';
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
  KeklistThemeMode _themePreference = KeklistThemeMode.system;
  SupportedLanguage _currentLanguage = SupportedLanguage.english;

  @override
  void initState() {
    super.initState();

    subscribeToBloc<SettingsBloc>(
      onNewState: (state) {
        if (state is SettingsDataState) {
          setState(() {
            _themePreference = state.settings.themePreference;
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
      debugShowCheckedModeBanner: false,
      title: 'keklist',
      home: const TabsContainerScreen(),
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: switch (_themePreference) {
        KeklistThemeMode.light => ThemeMode.light,
        KeklistThemeMode.dark => ThemeMode.dark,
        KeklistThemeMode.system => ThemeMode.system,
      },
      locale: _currentLanguage.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: EasyLoading.init(),
    );
  }
}
