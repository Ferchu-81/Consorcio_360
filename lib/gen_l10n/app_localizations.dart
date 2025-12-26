import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @roleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get roleAdmin;

  /// No description provided for @roleOwner.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get roleOwner;

  /// No description provided for @roleTenant.
  ///
  /// In es, this message translates to:
  /// **'Inquilino'**
  String get roleTenant;

  /// No description provided for @roleOccupant.
  ///
  /// In es, this message translates to:
  /// **'Ocupante'**
  String get roleOccupant;

  /// No description provided for @roleOwnerOrTenant.
  ///
  /// In es, this message translates to:
  /// **'Propietario / Inquilino'**
  String get roleOwnerOrTenant;

  /// No description provided for @isPrimaryOwner.
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get isPrimaryOwner;

  /// No description provided for @occupiesUnit.
  ///
  /// In es, this message translates to:
  /// **'Ocupa'**
  String get occupiesUnit;

  /// No description provided for @cfgAmenitiesOwnerNonOccupantTitle.
  ///
  /// In es, this message translates to:
  /// **'Propietario no ocupante: acceso a amenities (uso y reserva)'**
  String get cfgAmenitiesOwnerNonOccupantTitle;

  /// No description provided for @cfgAmenitiesOwnerNonOccupantSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Permite usar y reservar amenities aunque no viva en la unidad.'**
  String get cfgAmenitiesOwnerNonOccupantSubtitle;

  /// No description provided for @cfgOwnerVoteWithoutOccupyingTitle.
  ///
  /// In es, this message translates to:
  /// **'Voto del propietario sin ocupar'**
  String get cfgOwnerVoteWithoutOccupyingTitle;

  /// No description provided for @cfgOwnerVoteWithoutOccupyingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Permite votar al propietario aunque haya un ocupante en la unidad.'**
  String get cfgOwnerVoteWithoutOccupyingSubtitle;

  /// No description provided for @unit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get unit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
