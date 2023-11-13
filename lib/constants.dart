import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Palette {
  static const MaterialColor swatch = MaterialColor(
    0xff000000, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch.
    <int, Color>{
      50: Color(0xff333333), //10%
      100: Color(0xff4d4d4d), //20%
      200: Color(0xff666666), //30%
      300: Color(0xff808080), //40%
      400: Color(0xff999999), //50%
      500: Color(0xffb3b3b3), //60%
      600: Color(0xffcccccc), //70%
      700: Color(0xffe6e6e6), //80%
      800: Color(0xffffffff), //90%
      900: Color(0xff000000), //100%
    },
  );
}

class LayoutConstants {
  static double mindSide = 100.0;
}

class DateFormatters {
  static DateFormat fullDateFormat = DateFormat('dd.MM.yyyy - EEEE');
}

class PlatformConstants {
  static String iosGroupId = 'group.kekable';
  static String iosMindDayWidgetName = 'MindDayWidget';
}

class KeklistConstants {
  static String demoAccountEmail = 'zenmode-demo-account@mailinator.com';
  static String termsOfUseURL = 'https://sashkyn.notion.site/Zenmode-Terms-of-Use-df179704b2d149b8a5a915296f5cb78f';
  static String whatsNewURL = 'https://sashkyn.notion.site/Rememoji-Mind-Tracker-8548383aede2406bbb8d26c7f58e769c';
  static String feedbackEmail = 'sashkn2@gmail.com';

  static List<String> demoModeEmodjiList = [
    '🤔',
    '🚿',
    '💪',
    '💩',
    '☕',
    '💦',
    '👱‍♀️',
    '🇬🇧',
    '🚀',
    '🍚',
    '🍳',
    '🚗',
    '👷🏿',
    '🤙',
    '🧘',
    '🙂',
    '🍵',
    '🥱',
    '🎮',
    '🎬',
    '💻',
    '😡',
    '🥳',
    '🥗',
    '🍝',
    '🍜',
    '🥟',
    '🚶',
    '💡',
    '☺️',
    '🍕',
    '💸',
    '🧟‍♂️',
    '🍣',
    '🥙',
    '🍔',
    '🍑',
    '🥞',
    '👩🏻',
    '😴',
    '🧹',
    '🍫',
    '❌',
    '🤒',
    '🥣',
    '🥔',
    '⚽',
    '🦷',
    '🎁',
    '🎾',
    '🙃',
    '🦈',
    '📚',
    '🇷🇺',
    '🇺🇦',
    '🇷🇸',
    '🍏',
    '😂',
    '🥤',
    '🏃',
    '🛍️',
    '🏂',
    '👧🏻',
    '💊',
    '🍌',
    '🦄',
    '👩',
    '🛬',
    '🛫',
    '💇',
    '🥛',
    '💧',
    '📱',
    '🍐',
    '🥫',
    '🕶️',
    '🥚',
    '🧼',
    '🎧',
    '💵',
    '🍰',
    '👕',
    '😀',
    '🍊',
    '📰',
    '🥲',
    '🥶',
    '🤕',
    '🥪',
    '🍗',
    '📞',
    '🍺',
    '🎄',
    '🌞',
    '😔',
    '😌',
    '💨',
    '🥩',
    '😒',
    '😫',
    '🏨',
    '🚖',
    '🗞️',
    '🏠',
    '🗣️',
    '🚌',
    '🤯',
    '🏋',
    '🚇',
    '🏡',
    '🪒',
    '👨‍🍳',
    '😥',
    '🛒',
    '👀',
    '👨🏻‍🦲',
    '🎥',
    '🤢',
    '🚊',
    '👮',
    '🎵',
    '🎂',
    '😕',
    '🚴',
    '🤧',
    '👁️',
    '🕺',
    '🧀',
    '🏥',
    '🥰',
    '🤣',
    '🌭',
    '👨🏻‍💻',
    '🧘‍♂️',
    '🛁',
    '🧳',
    '👩‍👦',
    '📜',
    '🥐',
    '🍟',
    '🧽',
    '💬',
    '🍷',
    '📲',
    '🍲',
    '🖥️',
    '🤨',
    '💋',
    '🧁',
  ];
}
