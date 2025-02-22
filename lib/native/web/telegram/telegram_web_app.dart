// @JS("Telegram.WebApp")
// library;

// import 'dart:js_interop';

// /// All the properties and methods of the Telegram Web JS API
// /// https://core.telegram.org/bots/webapps
// ///
// /// [isDarkMode] is reliable only if used inside Telegram web
// bool get isDarkMode => colorScheme == "dark";

// /// [isSupported] will return true only if opened inside Telegram web
// bool get isSupported => platform.toLowerCase() != "unknown";

// /// Getters for properties
// ///
// external String get initData;
// external String get version;
// external String get platform;
// external String get colorScheme;
// external String get headerColor;
// external String get backgroundColor;
// external bool get isClosingConfirmationEnabled;
// external bool get isExpanded;
// external double? get viewportHeight;
// external double? get viewportStableHeight;

// /// Getters for classes and objects
// ///
// // external ThemeParams get themeParams;
// // external TelegramBackButton get BackButton;
// // external TelegramMainButton get MainButton;
// // external WebAppInitData get initDataUnsafe;
// // external TelegramHapticFeedback get HapticFeedback;

// /// Functions
// ///
// external Future<void> ready();
// external Future<void> expand();
// external Future<void> close();
// external Future<void> enableClosingConfirmation();
// external Future<void> disableClosingConfirmation();
// external Future<void> sendData(dynamic data);
// external Future<void> isVersionAtLeast(version);
// external Future<void> setHeaderColor(String color);
// external Future<void> setBackgroundColor(String color);
// // external Future<void> switchInlineQuery(query, [choose_chat_types]);
// external Future<void> openLink(url, [options]);
// external Future<void> openTelegramLink(String url);
// external Future<void> enableVerticalSwipes();
// external Future<void> disableVerticalSwipes();
// // external Future<void> openInvoice(String url, [JsCallback]);
// // external Future<void> readTextFromClipboard(JsCallback);
