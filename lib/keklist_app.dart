import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/onboarding_service.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:keklist/presentation/screens/tabs_container/tabs_container_screen.dart';
import 'package:keklist/l10n/app_localizations.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:logarte/logarte.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

final Logarte logarte = Logarte(
    password: null,
    ignorePassword: kDebugMode,
    onShare: (final String content) => SharePlus.instance.share(ShareParams(text: content)),
    disableDebugConsoleLogs: false);

final class KeklistApp extends StatefulWidget {
  const KeklistApp({super.key});

  @override
  State<KeklistApp> createState() => KeklistAppState();
}

final class KeklistAppState extends KekWidgetState<KeklistApp> {
  bool _isDarkMode = true;
  SupportedLanguage _currentLanguage = SupportedLanguage.english;
  bool _hasSeenOnboarding = false;
  bool _hasCreatedSampleMinds = false;

  @override
  void initState() {
    super.initState();

    subscribeToBloc<SettingsBloc>(
      onNewState: (state) {
        if (state is SettingsDataState) {
          setState(() {
            _isDarkMode = state.settings.isDarkMode;
            _currentLanguage = state.settings.language;
            _hasSeenOnboarding = state.settings.hasSeenOnboarding;
            SensitiveWidget.isProtected = !state.settings.isMindContentVisible;
          });
        }
      },
    )?.disposed(by: this);

    if (kDebugMode) {
      logarte.attach(
        context: context,
        visible: kDebugMode,
      );
    }
  }

  Future<void> _handleOnboardingComplete() async {
    if (!_hasCreatedSampleMinds) {
      final mindRepository = context.read<MindRepository>();
      final localizations = AppLocalizations.of(context)!;

      await OnboardingService.createSampleMinds(
        mindRepository: mindRepository,
        localizations: localizations,
      );

      setState(() {
        _hasCreatedSampleMinds = true;
        _hasSeenOnboarding = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'keklist',
      home: _hasSeenOnboarding
          ? const TabsContainerScreen()
          : OnboardingScreen(
              onComplete: _handleOnboardingComplete,
            ),
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
