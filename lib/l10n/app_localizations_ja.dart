// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get welcomeToDecisioninja => 'Decisioninjaへようこそ！';

  @override
  String get welcomeToAuraninja => 'Auraninjaへようこそ！';

  @override
  String get statsDisplayedHere => 'ここにあなたの統計が表示されます';

  @override
  String get decisionsMadeSoFar => 'これまでの意思決定：';

  @override
  String get home => 'ホーム';

  @override
  String get leftRight => '左/右';

  @override
  String get dice => 'サイコロ';

  @override
  String get pointer => 'ポインター';

  @override
  String get ninja => '忍者';

  @override
  String get settings => '設定';

  @override
  String get chooseLeftRight => '右か左を選ぶ！';

  @override
  String get choosing => '選んでいます...';

  @override
  String theResultIs(Object result) {
    return '結果は：$result';
  }

  @override
  String get left => '左';

  @override
  String get right => '右';

  @override
  String get throwDie => 'サイコロを投げる！';

  @override
  String get throwDice => 'サイコロを投げる！';

  @override
  String get throwing => '投げています...';

  @override
  String get totalScore => '合計：';

  @override
  String get pointArrow => '矢を指して！';

  @override
  String get pointing => '指しています...';

  @override
  String get arrowResult => '結果は：ここ';

  @override
  String get addFirstNinja => 'オプションを追加!';

  @override
  String get createNinja => 'オプションを作成';

  @override
  String get chooseNinja => 'オプションを選択！';

  @override
  String get nameNinja => 'オプションの名前';

  @override
  String get chosenNinja => '選ばれたオプション：';

  @override
  String get removeNinja => 'オプションを削除';

  @override
  String get changeTheme => 'テーマを変える';

  @override
  String get language => '言語';

  @override
  String get resetCount => '統計をリセット';

  @override
  String get areYouSure => '本当によろしいですか？';

  @override
  String get resetCountDescription => '続行すると、あなたの意思決定の統計がリセットされます。続行しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get reset => 'リセット';

  @override
  String get version => 'バージョン';

  @override
  String get sounds => 'サウンド';

  @override
  String get nature => '自然';

  @override
  String get rain => '雨';

  @override
  String get wind => '風';

  @override
  String get waves => '波';

  @override
  String get fire => '火';

  @override
  String get binaural => 'バイノーラル';

  @override
  String get creativeFlow => 'クリエイティブな流れ';

  @override
  String get deepCalm => '深い静けさ';

  @override
  String get deepSleep => '深い眠り';

  @override
  String get laserFocus => '集中';

  @override
  String get theDeepestSleep => '最も深い眠り';

  @override
  String get zenCalm => '禅の静けさ';

  @override
  String get credits => 'クレジット';
}
