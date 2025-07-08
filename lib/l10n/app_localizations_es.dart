// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcomeToDecisioninja => '¡Decisioninja te da la bienvenida!';

  @override
  String get welcomeToAuraninja => '¡Auraninja te da la bienvenida!';

  @override
  String get statsDisplayedHere => 'Tus estadísticas se mostrarán aquí';

  @override
  String get decisionsMadeSoFar => 'Decisiones tomadas hasta ahora:';

  @override
  String get home => 'Home';

  @override
  String get leftRight => 'Izq./Der.';

  @override
  String get dice => 'Dados';

  @override
  String get pointer => 'Puntero';

  @override
  String get ninja => 'Ninja';

  @override
  String get settings => 'Config.';

  @override
  String get chooseLeftRight => '¡Elige izquierda o derecha!';

  @override
  String get choosing => 'Estoy eligiendo...';

  @override
  String theResultIs(Object result) {
    return 'El resultado es: $result';
  }

  @override
  String get left => 'izquierda';

  @override
  String get right => 'derecha';

  @override
  String get throwDie => '¡Tira el dado!';

  @override
  String get throwDice => '¡Tira los dados!';

  @override
  String get throwing => 'Estoy tirando...';

  @override
  String get totalScore => 'Total: ';

  @override
  String get pointArrow => '¡Apunta la flecha!';

  @override
  String get pointing => 'Estoy apuntando...';

  @override
  String get arrowResult => 'El resultado es: allí';

  @override
  String get addFirstNinja => '¡Añadir opciones!';

  @override
  String get createNinja => 'Crear opción';

  @override
  String get chooseNinja => '¡Elige una opción!';

  @override
  String get nameNinja => 'nombre de la opción';

  @override
  String get chosenNinja => 'Opción elegida: ';

  @override
  String get removeNinja => 'Quitar opción';

  @override
  String get changeTheme => 'Cambiar tema';

  @override
  String get language => 'Idioma';

  @override
  String get resetCount => 'Restablecer estadísticas';

  @override
  String get areYouSure => '¿Estás seguro/a?';

  @override
  String get resetCountDescription =>
      'Al continuar, restablecerás las estadísticas de tus decisiones. ¿Quieres continuar?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get reset => 'Restablecer';

  @override
  String get version => 'Versión';

  @override
  String get sounds => 'Sonidos';

  @override
  String get nature => 'Naturaleza';

  @override
  String get rain => 'Lluvia';

  @override
  String get wind => 'Viento';

  @override
  String get waves => 'Olas';

  @override
  String get fire => 'Fuego';

  @override
  String get binaural => 'Binaural';

  @override
  String get creativeFlow => 'Flujo Creativo';

  @override
  String get deepCalm => 'Calma Profunda';

  @override
  String get deepSleep => 'Sueño Profundo';

  @override
  String get laserFocus => 'Concentración';

  @override
  String get theDeepestSleep => 'El Sueño Más Profundo';

  @override
  String get zenCalm => 'Calma Zen';

  @override
  String get credits => 'Créditos';

  @override
  String get birds => 'Aves';
}
