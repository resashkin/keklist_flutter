// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settings => '設定';

  @override
  String get userData => 'ユーザーデータ';

  @override
  String get appearance => '外観';

  @override
  String get exportToCsv => 'CSVにエクスポート';

  @override
  String get exportData => 'データをエクスポート';

  @override
  String get importData => 'データをインポート';

  @override
  String get done => '完了';

  @override
  String get chatWithAI => 'AIとチャット';

  @override
  String get photosPerDay => '1日の写真数';

  @override
  String get extraActions => '追加アクション';

  @override
  String get mindOptions => 'メモのオプション';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get share => '共有';

  @override
  String get saveToFiles => 'ファイルに保存';

  @override
  String get switchDay => '日を切り替え';

  @override
  String get goToDate => '日付に移動';

  @override
  String get showDigest => '...の要約を表示';

  @override
  String get showAll => 'すべて表示';

  @override
  String get translateToEnglish => '英語に翻訳';

  @override
  String get convertToStandalone => 'スタンドアロンに変換';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get showDayDividers => '日の区切りを表示';

  @override
  String get tabsSettings => 'タブ設定';

  @override
  String get whatsNew => '新機能';

  @override
  String get releaseNotes => 'リリースノート';

  @override
  String get suggestFeature => '機能を提案';

  @override
  String get sendFeedback => 'フィードバックを送信';

  @override
  String get emailUs => 'メールを送る';

  @override
  String get clearOfflineDataWarning =>
      'オフラインデータはすべて削除されます。すでにエクスポート済みであることを確認してください。';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get termsOfUse => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get clearOnDeviceData => 'デバイス上のデータをクリア';

  @override
  String get setOpenAIToken => 'Open AIトークンを設定';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get mind => 'メモ';

  @override
  String get profile => 'プロフィール';

  @override
  String get insights => 'インサイト';

  @override
  String get calendar => 'カレンダー';

  @override
  String get debugMenu => 'デバッグメニュー';

  @override
  String get discussion => 'ディスカッション';

  @override
  String get about => 'について';

  @override
  String get dangerZone => '危険ゾーン';

  @override
  String get editMind => 'メモを編集';

  @override
  String get enterTokenHere => 'ここにトークンを入力';

  @override
  String get token => 'トークン';

  @override
  String get clearCache => 'キャッシュをクリア';

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
