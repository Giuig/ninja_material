import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';

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
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
  ];

  /// No description provided for @welcomeToDecisioninja.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Decisioninja!'**
  String get welcomeToDecisioninja;

  /// No description provided for @welcomeToAuraninja.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Auraninja!'**
  String get welcomeToAuraninja;

  /// No description provided for @statsDisplayedHere.
  ///
  /// In en, this message translates to:
  /// **'Your stats will be displayed here'**
  String get statsDisplayedHere;

  /// No description provided for @decisionsMadeSoFar.
  ///
  /// In en, this message translates to:
  /// **'Decisions made so far:'**
  String get decisionsMadeSoFar;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @leftRight.
  ///
  /// In en, this message translates to:
  /// **'Left/Right'**
  String get leftRight;

  /// No description provided for @dice.
  ///
  /// In en, this message translates to:
  /// **'Dice'**
  String get dice;

  /// No description provided for @pointer.
  ///
  /// In en, this message translates to:
  /// **'Pointer'**
  String get pointer;

  /// No description provided for @ninja.
  ///
  /// In en, this message translates to:
  /// **'Ninja'**
  String get ninja;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @chooseLeftRight.
  ///
  /// In en, this message translates to:
  /// **'Choose left or right!'**
  String get chooseLeftRight;

  /// No description provided for @choosing.
  ///
  /// In en, this message translates to:
  /// **'Choosing...'**
  String get choosing;

  /// No description provided for @theResultIs.
  ///
  /// In en, this message translates to:
  /// **'The result is: {result}'**
  String theResultIs(Object result);

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get right;

  /// No description provided for @throwDie.
  ///
  /// In en, this message translates to:
  /// **'Throw the die!'**
  String get throwDie;

  /// No description provided for @throwDice.
  ///
  /// In en, this message translates to:
  /// **'Throw the dice!'**
  String get throwDice;

  /// No description provided for @throwing.
  ///
  /// In en, this message translates to:
  /// **'Throwing...'**
  String get throwing;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total score: '**
  String get totalScore;

  /// No description provided for @pointArrow.
  ///
  /// In en, this message translates to:
  /// **'Point the arrow!'**
  String get pointArrow;

  /// No description provided for @pointing.
  ///
  /// In en, this message translates to:
  /// **'Pointing...'**
  String get pointing;

  /// No description provided for @arrowResult.
  ///
  /// In en, this message translates to:
  /// **'The result is: there'**
  String get arrowResult;

  /// No description provided for @addFirstNinja.
  ///
  /// In en, this message translates to:
  /// **'Add options first!'**
  String get addFirstNinja;

  /// No description provided for @createNinja.
  ///
  /// In en, this message translates to:
  /// **'Create Option'**
  String get createNinja;

  /// No description provided for @chooseNinja.
  ///
  /// In en, this message translates to:
  /// **'Choose the option!'**
  String get chooseNinja;

  /// No description provided for @nameNinja.
  ///
  /// In en, this message translates to:
  /// **'Option Name'**
  String get nameNinja;

  /// No description provided for @chosenNinja.
  ///
  /// In en, this message translates to:
  /// **'Chosen option: '**
  String get chosenNinja;

  /// No description provided for @removeNinja.
  ///
  /// In en, this message translates to:
  /// **'Remove Option'**
  String get removeNinja;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get changeTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @resetCount.
  ///
  /// In en, this message translates to:
  /// **'Reset stats'**
  String get resetCount;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @resetCountDescription.
  ///
  /// In en, this message translates to:
  /// **'This will reset the stats of your decisions. Do you want to proceed?'**
  String get resetCountDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;
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
    'fr',
    'it',
    'ja',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
