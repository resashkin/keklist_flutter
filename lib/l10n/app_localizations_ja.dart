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
  String get updateYourNickname => 'ニックネームを更新';

  @override
  String get yourNickname => 'あなたのニックネーム';

  @override
  String get create => '書く';

  @override
  String get yourFolderName => 'あなたのフォルダー名';

  @override
  String get noMindsInSelectedPeriod => '選択した期間にメモはありません';

  @override
  String get noMindsForPeriod => 'この期間のメモはありません';

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
  String get randomMind => 'ランダムなメモ';

  @override
  String get spectrum => 'スペクトラム';

  @override
  String get youDidNotCollectAnyEntriesYet => 'まだエントリーを収集していません';

  @override
  String get pleaseAuthenticateToShowContent => 'メモの内容を表示するには認証してください';

  @override
  String get areYouSure => 'よろしいですか？';

  @override
  String get cannotRemoveMainScreen => 'メイン画面は削除できません。タブを設定するオプションが失われます。';

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
  String get calendarDescription => 'エントリーのカレンダーがあるメイン画面';

  @override
  String get insightsDescription => 'すべてのエントリーの統計';

  @override
  String get settingsDescription => 'すべての設定の画面（ダークモード、同期など）';

  @override
  String get profileDescription => 'あなたのプロフィールの画面';

  @override
  String get todayDescription => '今日のメモのみ';

  @override
  String get debugMenuDescription => '実験的な機能を切り替えるための開発者ツール';

  @override
  String get noMindsForThisDay => 'この日のメモはありません';

  @override
  String showMindsForPeriod(String period) {
    return '$periodのメモを表示';
  }

  @override
  String get week => '週';

  @override
  String get password => 'パスワード';

  @override
  String get archivePassword => 'アーカイブパスワード';

  @override
  String get enterPassword => 'パスワードを入力';

  @override
  String get confirmPassword => 'パスワードを確認';

  @override
  String get reenterPassword => 'パスワードを再入力';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get exportPassword => 'ZIPにエクスポート';

  @override
  String get exportPasswordDescription =>
      'エクスポートを暗号化するためにパスワードを追加します。暗号化しない場合はスキップできます。';

  @override
  String get importPassword => 'パスワードを入力';

  @override
  String get importPasswordDescription =>
      'このファイルはパスワードで保護されています。復号化するためにパスワードを入力してください。';

  @override
  String get skipPassword => 'スキップ（パスワードなし）';

  @override
  String get continue_ => '続ける';

  @override
  String get incorrectPassword => 'パスワードが正しくありません';

  @override
  String get incorrectPasswordMessage => '入力されたパスワードが正しくありません。もう一度お試しください。';

  @override
  String get corruptedFile => '破損したファイル';

  @override
  String get invalidFormat => '無効な形式';

  @override
  String get missingAudioFiles => '一部の音声ファイルが見つかりません';

  @override
  String get insufficientStorage => 'ストレージ容量が不足しています';

  @override
  String get unknownError => '不明なエラー';

  @override
  String get retry => '再試行';

  @override
  String get ok => 'OK';

  @override
  String get exportSuccess => 'エクスポートに成功しました';

  @override
  String get exportError => 'エクスポートに失敗しました';

  @override
  String get importSuccess => 'インポートに成功しました';

  @override
  String get importError => 'インポートに失敗しました';

  @override
  String get mindsToExport => 'メモ';

  @override
  String get audioFilesToExport => '音声ファイル';

  @override
  String get mindsExported => 'メモをエクスポートしました';

  @override
  String get audioFilesExported => '音声ファイルをエクスポートしました';

  @override
  String get mindsImported => 'メモをインポートしました';

  @override
  String get audioFilesImported => '音声ファイルをインポートしました';

  @override
  String get onboardingMind1 => 'こんにちは！';

  @override
  String get onboardingMind2 => '私はkeklist - 短いメモの個人日記です';

  @override
  String get onboardingMind2Comment1 => 'メモにはコメントを付けることができます';

  @override
  String get onboardingMind2Comment2 => 'メモを開くには、タップしてください';

  @override
  String get onboardingMind3 => '「カレンダー」タブでは、すべてのメモが日、週、月ごとに表示されます';

  @override
  String get onboardingMind4 => '「分析」タブでは、エントリーの簡単な統計が表示されます';

  @override
  String get onboardingMind5 => 'すべてのメモはあなたのスマートフォンにのみ保存されます';

  @override
  String get onboardingMind6 => '新しいメモを作成するには、\'書く\'をタップしてください';

  @override
  String get viewPhotos => '写真を見る';

  @override
  String get noPhotosForDay => 'この日の写真が見つかりません';

  @override
  String photosFromDay(String date) {
    return '$dateの写真';
  }
}
