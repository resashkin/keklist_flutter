import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

final class Themes {
  static final ThemeData light = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.grey,
    ),
    cardTheme: const CardThemeData(color: Colors.white),
    iconTheme: const IconThemeData(color: Colors.black),
    textTheme: ThemeData().textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
          decorationColor: Colors.black,
        ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.black),
      hintStyle: TextStyle(color: Color.fromARGB(255, 90, 77, 77)),
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      textTheme: CupertinoTextThemeData(), // This is required for Dialog Inputs
    ),
  );

  static final ThemeData dark = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.grey,
    ),
    cardTheme: const CardThemeData(color: Colors.black),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: ThemeData().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          decorationColor: Colors.white,
        ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white),
      hintStyle: TextStyle(color: Colors.grey),
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      textTheme: CupertinoTextThemeData(), // This is required for Dialog Inputs
    ),
  );
}

final class LayoutConstants {
  static double mindSide = 100.0;
}

final class DateFormatters {
  static DateFormat fullDateFormat = DateFormat('dd.MM.yyyy - EEEE');
}

final class PlatformConstants {
  static String iosGroupId = 'group.kekable';
  static String iosMindDayWidgetName = 'MindDayWidget';
}

final class FlutterConstants {
  static ScrollPhysics mobileOverscrollPhysics =
      const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics());
}

enum SupportedPlatform { iOS, android, web }

final class KeklistConstants {
  static String demoAccountEmail = dotenv.get('DEMO_ACCOUNT_EMAIL');
  static String termsOfUseURL = 'https://sashkyn.notion.site/Zenmode-Terms-of-Use-df179704b2d149b8a5a915296f5cb78f';
  static String whatsNewURL = 'https://sashkyn.notion.site/Rememoji-Mind-Tracker-8548383aede2406bbb8d26c7f58e769c';
  static String privacyURL = 'https://sashkyn.notion.site/Keklist-Privacy-Policy-1e183fccf71f80be899ad9eed309790a';
  static String feedbackEmail = 'sashkn2@gmail.com';
  static String sourceCodeURL = 'https://github.com/sashkyn/keklist_flutter';
  static String featureSuggestionsURL = 'https://insigh.to/b/keklist';
  static int foldersDayIndex = 0;

  static List<TabModel> availableTabModels = [
    TabModel(type: TabType.calendar),
    TabModel(type: TabType.insights),
    //TabModel(type: TabType.profile),
    TabModel(type: TabType.settings),
  ];

  static TabsSettings defaultTabSettings = TabsSettings(
    defaultSelectedTabIndex: 0,
    selectedTabModels: [
      TabModel(type: TabType.calendar),
      TabModel(type: TabType.insights),
      TabModel(type: TabType.settings),
    ],
  );
}
