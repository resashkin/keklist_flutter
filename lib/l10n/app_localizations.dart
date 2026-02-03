import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('it'),
    Locale('ja'),
    Locale('kk'),
    Locale('ky'),
    Locale('ru'),
    Locale('sr'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
    Locale('uz'),
    Locale('zh'),
  ];

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// User data section title
  ///
  /// In en, this message translates to:
  /// **'User Data'**
  String get userData;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Export to CSV button
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCsv;

  /// Export data button
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// Import data button
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done;

  /// Chat with AI action
  ///
  /// In en, this message translates to:
  /// **'Chat with AI'**
  String get chatWithAI;

  /// Photos per day action
  ///
  /// In en, this message translates to:
  /// **'Photos per day'**
  String get photosPerDay;

  /// Extra actions menu
  ///
  /// In en, this message translates to:
  /// **'Extra actions'**
  String get extraActions;

  /// Mind options menu
  ///
  /// In en, this message translates to:
  /// **'Mind options'**
  String get mindOptions;

  /// Edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Save to files action
  ///
  /// In en, this message translates to:
  /// **'Save to files'**
  String get saveToFiles;

  /// Switch day action
  ///
  /// In en, this message translates to:
  /// **'Switch day'**
  String get switchDay;

  /// Go to date action
  ///
  /// In en, this message translates to:
  /// **'Go to date'**
  String get goToDate;

  /// Show digest action
  ///
  /// In en, this message translates to:
  /// **'Show digest for ...'**
  String get showDigest;

  /// Show all action
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// Translate to English action
  ///
  /// In en, this message translates to:
  /// **'Translate to English'**
  String get translateToEnglish;

  /// Convert to standalone action
  ///
  /// In en, this message translates to:
  /// **'Convert to standalone'**
  String get convertToStandalone;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// Show day dividers setting
  ///
  /// In en, this message translates to:
  /// **'Show day dividers'**
  String get showDayDividers;

  /// Tabs settings navigation
  ///
  /// In en, this message translates to:
  /// **'Tabs settings'**
  String get tabsSettings;

  /// What's new navigation
  ///
  /// In en, this message translates to:
  /// **'What\'s new?'**
  String get whatsNew;

  /// Release notes navigation
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get releaseNotes;

  /// Suggest feature navigation
  ///
  /// In en, this message translates to:
  /// **'Suggest a feature'**
  String get suggestFeature;

  /// Send feedback navigation
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// Email us navigation
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get emailUs;

  /// Warning when clearing offline data
  ///
  /// In en, this message translates to:
  /// **'All your offline data will be deleted. Make sure that you have already exported it.'**
  String get clearOfflineDataWarning;

  /// Source code navigation
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// Terms of use navigation
  ///
  /// In en, this message translates to:
  /// **'Terms Of Use'**
  String get termsOfUse;

  /// Privacy policy navigation
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Clear data navigation
  ///
  /// In en, this message translates to:
  /// **'Clear on-device data'**
  String get clearOnDeviceData;

  /// OpenAI token dialog title
  ///
  /// In en, this message translates to:
  /// **'Set Open AI Token'**
  String get setOpenAIToken;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Mind screen title
  ///
  /// In en, this message translates to:
  /// **'Mind'**
  String get mind;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Insights screen title
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// Calendar title
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Debug menu title
  ///
  /// In en, this message translates to:
  /// **'Debug Menu'**
  String get debugMenu;

  /// Discussion screen title
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Danger zone section title
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// Edit mind dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit mind'**
  String get editMind;

  /// Token input hint
  ///
  /// In en, this message translates to:
  /// **'Enter token here'**
  String get enterTokenHere;

  /// Token input label
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get token;

  /// Clear cache button
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// Active tabs section header
  ///
  /// In en, this message translates to:
  /// **'Active tabs'**
  String get activeTabs;

  /// Hidden tabs section header
  ///
  /// In en, this message translates to:
  /// **'Hidden tabs'**
  String get hiddenTabs;

  /// Error dialog title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Start discussion button
  ///
  /// In en, this message translates to:
  /// **'Start discussion'**
  String get startDiscussion;

  /// Send button
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get send;

  /// Update nickname dialog title
  ///
  /// In en, this message translates to:
  /// **'Update your nickname'**
  String get updateYourNickname;

  /// Nickname input hint
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get yourNickname;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get create;

  /// Folder name input hint
  ///
  /// In en, this message translates to:
  /// **'Your folder name'**
  String get yourFolderName;

  /// No minds in period message
  ///
  /// In en, this message translates to:
  /// **'No minds in selected period'**
  String get noMindsInSelectedPeriod;

  /// No minds for period message
  ///
  /// In en, this message translates to:
  /// **'No minds for this period'**
  String get noMindsForPeriod;

  /// Select period action
  ///
  /// In en, this message translates to:
  /// **'Select period ...'**
  String get selectPeriod;

  /// Digest title
  ///
  /// In en, this message translates to:
  /// **'Digest'**
  String get digest;

  /// Minds title
  ///
  /// In en, this message translates to:
  /// **'Minds'**
  String get minds;

  /// Search notes hint
  ///
  /// In en, this message translates to:
  /// **'Search for your notes'**
  String get searchForYourNotes;

  /// Search emoji hint
  ///
  /// In en, this message translates to:
  /// **'Search your emoji...'**
  String get searchYourEmoji;

  /// Write something hint
  ///
  /// In en, this message translates to:
  /// **'Write something...'**
  String get writeSomething;

  /// Top minds title
  ///
  /// In en, this message translates to:
  /// **'Top minds'**
  String get topMinds;

  /// Today minds title
  ///
  /// In en, this message translates to:
  /// **'Today minds'**
  String get todayMinds;

  /// Random mind title
  ///
  /// In en, this message translates to:
  /// **'Random mind'**
  String get randomMind;

  /// Spectrum title
  ///
  /// In en, this message translates to:
  /// **'Spectrum'**
  String get spectrum;

  /// No entries collected message
  ///
  /// In en, this message translates to:
  /// **'You did not collect any entries yet'**
  String get youDidNotCollectAnyEntriesYet;

  /// Authentication required message
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to show content of your mind'**
  String get pleaseAuthenticateToShowContent;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// Cannot remove main screen error message
  ///
  /// In en, this message translates to:
  /// **'Cannot remove main screen. You will loose option to setup tabs.'**
  String get cannotRemoveMainScreen;

  /// Today period title
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Yesterday period title
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// This week period title
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// Last 2 weeks period title
  ///
  /// In en, this message translates to:
  /// **'Last 2 weeks'**
  String get lastTwoWeeks;

  /// This month period title
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// This year period title
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// Calendar tab description
  ///
  /// In en, this message translates to:
  /// **'Main screen with Calendar of entries'**
  String get calendarDescription;

  /// Insights tab description
  ///
  /// In en, this message translates to:
  /// **'Statistics all yours entries'**
  String get insightsDescription;

  /// Settings tab description
  ///
  /// In en, this message translates to:
  /// **'Screen with all settings (dark mode, sync and etc.)'**
  String get settingsDescription;

  /// Profile tab description
  ///
  /// In en, this message translates to:
  /// **'Screen with your profile'**
  String get profileDescription;

  /// Today tab description
  ///
  /// In en, this message translates to:
  /// **'Only today minds'**
  String get todayDescription;

  /// Debug Menu tab description
  ///
  /// In en, this message translates to:
  /// **'Developer tools for toggling experimental features'**
  String get debugMenuDescription;

  /// No minds for this day message
  ///
  /// In en, this message translates to:
  /// **'No minds for this day'**
  String get noMindsForThisDay;

  /// Show minds for period message
  ///
  /// In en, this message translates to:
  /// **'Show minds for {period}'**
  String showMindsForPeriod(String period);

  /// Week label
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Archive password label for export
  ///
  /// In en, this message translates to:
  /// **'Archive password'**
  String get archivePassword;

  /// Enter password placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Re-enter password placeholder
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reenterPassword;

  /// Passwords do not match error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Export password dialog title
  ///
  /// In en, this message translates to:
  /// **'Export to ZIP'**
  String get exportPassword;

  /// Export password description
  ///
  /// In en, this message translates to:
  /// **'Add a password to encrypt your export. You can skip this for unencrypted export.'**
  String get exportPasswordDescription;

  /// Import password dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get importPassword;

  /// Import password description
  ///
  /// In en, this message translates to:
  /// **'This file is password-protected. Please enter the password to decrypt.'**
  String get importPasswordDescription;

  /// Skip password button
  ///
  /// In en, this message translates to:
  /// **'Skip (no password)'**
  String get skipPassword;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// Incorrect password error title
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// Incorrect password error message
  ///
  /// In en, this message translates to:
  /// **'The password you entered is incorrect. Please try again.'**
  String get incorrectPasswordMessage;

  /// Corrupted file error
  ///
  /// In en, this message translates to:
  /// **'Corrupted file'**
  String get corruptedFile;

  /// Invalid format error
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get invalidFormat;

  /// Missing audio files warning
  ///
  /// In en, this message translates to:
  /// **'Some audio files are missing'**
  String get missingAudioFiles;

  /// Insufficient storage error
  ///
  /// In en, this message translates to:
  /// **'Insufficient storage'**
  String get insufficientStorage;

  /// Unknown error
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Export success message title
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get exportSuccess;

  /// Export error message title
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportError;

  /// Import success message title
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get importSuccess;

  /// Import error message title
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importError;

  /// Minds count label for export
  ///
  /// In en, this message translates to:
  /// **'Minds'**
  String get mindsToExport;

  /// Audio files count label for export
  ///
  /// In en, this message translates to:
  /// **'Audio files'**
  String get audioFilesToExport;

  /// Minds exported count
  ///
  /// In en, this message translates to:
  /// **'Minds exported'**
  String get mindsExported;

  /// Audio files exported count
  ///
  /// In en, this message translates to:
  /// **'Audio files exported'**
  String get audioFilesExported;

  /// Minds imported count
  ///
  /// In en, this message translates to:
  /// **'Minds imported'**
  String get mindsImported;

  /// Audio files imported count
  ///
  /// In en, this message translates to:
  /// **'Audio files imported'**
  String get audioFilesImported;

  /// First onboarding mind greeting
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get onboardingMind1;

  /// Explanation of what keklist is
  ///
  /// In en, this message translates to:
  /// **'I\'m keklist - a personal diary of short notes'**
  String get onboardingMind2;

  /// Comment explaining commenting feature
  ///
  /// In en, this message translates to:
  /// **'Notes can be commented on'**
  String get onboardingMind2Comment1;

  /// Comment explaining how to open notes
  ///
  /// In en, this message translates to:
  /// **'To open a note, tap on it'**
  String get onboardingMind2Comment2;

  /// Explanation of Calendar tab
  ///
  /// In en, this message translates to:
  /// **'In the \'Calendar\' tab, all notes are displayed by days, weeks, and months'**
  String get onboardingMind3;

  /// Explanation of Analytics tab
  ///
  /// In en, this message translates to:
  /// **'The \'Analytics\' tab shows brief statistics of your entries'**
  String get onboardingMind4;

  /// Privacy explanation
  ///
  /// In en, this message translates to:
  /// **'All notes are stored only on your phone'**
  String get onboardingMind5;

  /// Instruction to create new note
  ///
  /// In en, this message translates to:
  /// **'To create new note tap \'Write\''**
  String get onboardingMind6;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'it',
    'ja',
    'kk',
    'ky',
    'ru',
    'sr',
    'uz',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'sr':
      {
        switch (locale.scriptCode) {
          case 'Latn':
            return AppLocalizationsSrLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'kk':
      return AppLocalizationsKk();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
    case 'sr':
      return AppLocalizationsSr();
    case 'uz':
      return AppLocalizationsUz();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
