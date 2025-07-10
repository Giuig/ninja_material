// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get welcomeToDecisioninja => 'Decisioninja ti dà il benvenuto!';

  @override
  String get welcomeToAuraninja => 'Auraninja ti dà il benvenuto!';

  @override
  String get statsDisplayedHere => 'Le tue statistiche saranno mostrate qui';

  @override
  String get decisionsMadeSoFar => 'Decisioni prese fino ad ora:';

  @override
  String get home => 'Home';

  @override
  String get leftRight => 'SX/DX';

  @override
  String get dice => 'Dadi';

  @override
  String get pointer => 'Puntatore';

  @override
  String get ninja => 'Ninja';

  @override
  String get settings => 'Impostaz.';

  @override
  String get chooseLeftRight => 'Scegli destra o sinistra!';

  @override
  String get choosing => 'Sto scegliendo...';

  @override
  String theResultIs(Object result) {
    return 'Il risultato è: $result';
  }

  @override
  String get left => 'sinistra';

  @override
  String get right => 'destra';

  @override
  String get throwDie => 'Lancia il dado!';

  @override
  String get throwDice => 'Lancia i dadi!';

  @override
  String get throwing => 'Sto lanciando...';

  @override
  String get totalScore => 'Totale: ';

  @override
  String get pointArrow => 'Punta la freccia!';

  @override
  String get pointing => 'Sto puntando...';

  @override
  String get arrowResult => 'Il risultato è: lì';

  @override
  String get addFirstNinja => 'Aggiungi opzioni!';

  @override
  String get createNinja => 'Crea Opzione';

  @override
  String get chooseNinja => 'Scegli opzione!';

  @override
  String get nameNinja => 'Nome Opzione';

  @override
  String get chosenNinja => 'Opzione scelta: ';

  @override
  String get removeNinja => 'Rimuovi opzione';

  @override
  String get changeTheme => 'Cambia tema';

  @override
  String get language => 'Lingua';

  @override
  String get resetCount => 'Resetta statistiche';

  @override
  String get areYouSure => 'Sei sicuro/a?';

  @override
  String get resetCountDescription =>
      'Procedendo azzererai le statistiche delle tue decisioni. Vuoi procedere?';

  @override
  String get cancel => 'Cancella';

  @override
  String get reset => 'Resetta';

  @override
  String get version => 'Versione';

  @override
  String get darkTheme => 'Dark Theme';
}
