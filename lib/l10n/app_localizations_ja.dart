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
  String get suggestFeature => '機能を提案';

  @override
  String get sendFeedback => 'フィードバックを送信';

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
  String get developerModeEnabled =>
      '🔧 開発者モードが有効になりました！Debug Menuタブが利用可能になりました！';

  @override
  String get activeTabs => 'アクティブなタブ';

  @override
  String get hiddenTabs => '非表示のタブ';

  @override
  String get error => 'エラー';

  @override
  String get startDiscussion => 'ディスカッションを開始';

  @override
  String get send => '送信';

  @override
  String get translateContent => 'コンテンツを翻訳';

  @override
  String get sensitiveContent => '機密コンテンツ';

  @override
  String get updateYourNickname => 'ニックネームを更新';

  @override
  String get yourNickname => 'あなたのニックネーム';

  @override
  String get create => '作成';

  @override
  String get yourFolderName => 'フォルダ名';

  @override
  String get noMindsInSelectedPeriod => '選択した期間にメモがありません';

  @override
  String get noMindsForPeriod => 'この期間にメモがありません';

  @override
  String get selectPeriod => '期間を選択...';

  @override
  String get digest => 'ダイジェスト';

  @override
  String get minds => 'メモ';

  @override
  String get searchForYourNotes => 'メモを検索';

  @override
  String get searchYourEmoji => '絵文字を検索...';

  @override
  String get writeSomething => '何か書いてください...';

  @override
  String get topMinds => 'トップメモ';

  @override
  String get todayMinds => '今日のメモ';

  @override
  String get randomMind => 'ランダムメモ';

  @override
  String get spectrum => 'スペクトラム';

  @override
  String get youDidNotCollectAnyEntriesYet => 'まだエントリを収集していません';

  @override
  String get pleaseAuthenticateToShowContent => 'メモの内容を表示するには認証してください';

  @override
  String get areYouSure => '本当によろしいですか？';

  @override
  String get cannotRemoveMainScreen => 'メイン画面を削除することはできません。タブの設定オプションが失われます。';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get thisWeek => '今週';

  @override
  String get lastTwoWeeks => '過去2週間';

  @override
  String get thisMonth => '今月';

  @override
  String get thisYear => '今年';

  @override
  String get calendarDescription => 'エントリのカレンダーがあるメイン画面';

  @override
  String get insightsDescription => 'すべてのエントリの統計';

  @override
  String get settingsDescription => 'すべての設定画面（ダークモード、同期など）';

  @override
  String get profileDescription => 'プロフィール画面';

  @override
  String get todayDescription => '今日のメモのみ';

  @override
  String get debugMenuDescription => '実験的機能を切り替える開発者ツール';

  @override
  String get noMindsForThisDay => 'この日のメモはありません';

  @override
  String showMindsForPeriod(String period) {
    return '$periodのメモを表示';
  }

  @override
  String get week => '週';
}
