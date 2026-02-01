// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settings => 'Einstellungen';

  @override
  String get userData => 'Benutzerdaten';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get exportToCsv => 'In CSV exportieren';

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get importData => 'Daten importieren';

  @override
  String get done => 'FERTIG';

  @override
  String get chatWithAI => 'Mit KI chatten';

  @override
  String get photosPerDay => 'Fotos pro Tag';

  @override
  String get extraActions => 'Zusätzliche Aktionen';

  @override
  String get mindOptions => 'Notiz-Optionen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get share => 'Teilen';

  @override
  String get saveToFiles => 'In Dateien speichern';

  @override
  String get switchDay => 'Tag wechseln';

  @override
  String get goToDate => 'Zu Datum gehen';

  @override
  String get showDigest => 'Zusammenfassung anzeigen für ...';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get translateToEnglish => 'Ins Englische übersetzen';

  @override
  String get convertToStandalone => 'In eigenständig konvertieren';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get darkMode => 'Dunkler Modus';

  @override
  String get showDayDividers => 'Tages-Trennlinien anzeigen';

  @override
  String get tabsSettings => 'Tab-Einstellungen';

  @override
  String get whatsNew => 'Was ist neu?';

  @override
  String get releaseNotes => 'Versionshinweise';

  @override
  String get suggestFeature => 'Funktion vorschlagen';

  @override
  String get sendFeedback => 'Feedback senden';

  @override
  String get emailUs => 'Schreib uns eine E-Mail';

  @override
  String get clearOfflineDataWarning =>
      'Alle deine Offline-Daten werden gelöscht. Stelle sicher, dass du sie bereits exportiert hast.';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get termsOfUse => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get clearOnDeviceData => 'Gerätedaten löschen';

  @override
  String get setOpenAIToken => 'Open AI Token setzen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get mind => 'Notiz';

  @override
  String get profile => 'Profil';

  @override
  String get insights => 'Einblicke';

  @override
  String get calendar => 'Kalender';

  @override
  String get debugMenu => 'Debug-Menü';

  @override
  String get discussion => 'Diskussion';

  @override
  String get about => 'Über';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get editMind => 'Notiz bearbeiten';

  @override
  String get enterTokenHere => 'Token hier eingeben';

  @override
  String get token => 'Token';

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get activeTabs => 'Active tabs';

  @override
  String get hiddenTabs => 'Hidden tabs';

  @override
  String get error => 'Error';

  @override
  String get startDiscussion => 'Start discussion';

  @override
  String get send => 'SEND';

  @override
  String get updateYourNickname => 'Update your nickname';

  @override
  String get yourNickname => 'Your nickname';

  @override
  String get create => 'Write';

  @override
  String get yourFolderName => 'Your folder name';

  @override
  String get noMindsInSelectedPeriod => 'No minds in selected period';

  @override
  String get noMindsForPeriod => 'No minds for this period';

  @override
  String get selectPeriod => 'Select period ...';

  @override
  String get digest => 'Digest';

  @override
  String get minds => 'Minds';

  @override
  String get searchForYourNotes => 'Search for your notes';

  @override
  String get searchYourEmoji => 'Search your emoji...';

  @override
  String get writeSomething => 'Write something...';

  @override
  String get topMinds => 'Top minds';

  @override
  String get todayMinds => 'Today minds';

  @override
  String get randomMind => 'Random mind';

  @override
  String get spectrum => 'Spectrum';

  @override
  String get youDidNotCollectAnyEntriesYet =>
      'You did not collect any entries yet';

  @override
  String get pleaseAuthenticateToShowContent =>
      'Please authenticate to show content of your mind';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get cannotRemoveMainScreen =>
      'Cannot remove main screen. You will loose option to setup tabs.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This week';

  @override
  String get lastTwoWeeks => 'Last 2 weeks';

  @override
  String get thisMonth => 'This month';

  @override
  String get thisYear => 'This year';

  @override
  String get calendarDescription => 'Main screen with Calendar of entries';

  @override
  String get insightsDescription => 'Statistics all yours entries';

  @override
  String get settingsDescription =>
      'Screen with all settings (dark mode, sync and etc.)';

  @override
  String get profileDescription => 'Screen with your profile';

  @override
  String get todayDescription => 'Only today minds';

  @override
  String get debugMenuDescription =>
      'Developer tools for toggling experimental features';

  @override
  String get noMindsForThisDay => 'No minds for this day';

  @override
  String showMindsForPeriod(String period) {
    return 'Show minds for $period';
  }

  @override
  String get week => 'Week';

  @override
  String get password => 'Password';

  @override
  String get archivePassword => 'Archive password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get reenterPassword => 'Re-enter password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get exportPassword => 'Export to ZIP';

  @override
  String get exportPasswordDescription =>
      'Add a password to encrypt your export. You can skip this for unencrypted export.';

  @override
  String get importPassword => 'Enter password';

  @override
  String get importPasswordDescription =>
      'This file is password-protected. Please enter the password to decrypt.';

  @override
  String get skipPassword => 'Skip (no password)';

  @override
  String get continue_ => 'Continue';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get incorrectPasswordMessage =>
      'The password you entered is incorrect. Please try again.';

  @override
  String get corruptedFile => 'Corrupted file';

  @override
  String get invalidFormat => 'Invalid format';

  @override
  String get missingAudioFiles => 'Some audio files are missing';

  @override
  String get insufficientStorage => 'Insufficient storage';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get exportError => 'Export failed';

  @override
  String get importSuccess => 'Import successful';

  @override
  String get importError => 'Import failed';

  @override
  String get mindsToExport => 'Minds';

  @override
  String get audioFilesToExport => 'Audio files';

  @override
  String get mindsExported => 'Minds exported';

  @override
  String get audioFilesExported => 'Audio files exported';

  @override
  String get mindsImported => 'Minds imported';

  @override
  String get audioFilesImported => 'Audio files imported';

  @override
  String get onboardingMind1 => 'Hello!';

  @override
  String get onboardingMind2 =>
      'I\'m keklist - a personal diary of short notes';

  @override
  String get onboardingMind2Comment1 => 'Notes can be commented on';

  @override
  String get onboardingMind2Comment2 => 'To open a note, tap on it';

  @override
  String get onboardingMind3 =>
      'In the \'Calendar\' tab, all notes are displayed by days, weeks, and months';

  @override
  String get onboardingMind4 =>
      'The \'Analytics\' tab shows brief statistics of your entries';

  @override
  String get onboardingMind5 => 'All notes are stored only on your phone';

  @override
  String get onboardingMind5Comment1 =>
      'When changing phones, use the Import/Export feature';

  @override
  String get deleteOnboardingMindsTitle => 'Delete tutorial notes?';

  @override
  String get deleteOnboardingMindsMessage =>
      'You\'ve created your first mind! Would you like to delete the tutorial notes?';

  @override
  String get keepTutorial => 'Keep';

  @override
  String get deleteTutorial => 'Delete';
}
