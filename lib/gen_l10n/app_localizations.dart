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

  /// No description provided for @roleAdminConsorcio.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get roleAdminConsorcio;

  /// No description provided for @rolePropietario.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get rolePropietario;

  /// No description provided for @roleOcupanteDefault.
  ///
  /// In es, this message translates to:
  /// **'Inquilino'**
  String get roleOcupanteDefault;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar notificaciones.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get notificationsRetry;

  /// No description provided for @notificationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay notificaciones por ahora.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsNoDestination.
  ///
  /// In es, this message translates to:
  /// **'Notificacion sin destino.'**
  String get notificationsNoDestination;

  /// No description provided for @notificationsMissingReclamoId.
  ///
  /// In es, this message translates to:
  /// **'Reclamo sin id.'**
  String get notificationsMissingReclamoId;

  /// No description provided for @notificationsMissingExpensaId.
  ///
  /// In es, this message translates to:
  /// **'Expensa sin id.'**
  String get notificationsMissingExpensaId;

  /// No description provided for @notificationsExpensaNotFound.
  ///
  /// In es, this message translates to:
  /// **'Expensa no encontrada.'**
  String get notificationsExpensaNotFound;

  /// No description provided for @notificationsReservaUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Reservas no disponible.'**
  String get notificationsReservaUnavailable;

  /// No description provided for @notificationsPreferencesTitle.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get notificationsPreferencesTitle;

  /// No description provided for @notificationsPreferencesRoleTitle.
  ///
  /// In es, this message translates to:
  /// **'Este rol'**
  String get notificationsPreferencesRoleTitle;

  /// No description provided for @notificationsPreferencesRoleHint.
  ///
  /// In es, this message translates to:
  /// **'Preferencias para el rol actual.'**
  String get notificationsPreferencesRoleHint;

  /// No description provided for @notificationsPreferencesEventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get notificationsPreferencesEventsTitle;

  /// No description provided for @notificationsPreferencesApplyAllTitle.
  ///
  /// In es, this message translates to:
  /// **'Aplicar a todos mis roles'**
  String get notificationsPreferencesApplyAllTitle;

  /// No description provided for @notificationsPreferencesApplyAllSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Copia estas preferencias a mis otros roles en este consorcio.'**
  String get notificationsPreferencesApplyAllSubtitle;

  /// No description provided for @notificationsPreferencesSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get notificationsPreferencesSave;

  /// No description provided for @notificationsPreferencesSaved.
  ///
  /// In es, this message translates to:
  /// **'Preferencias guardadas.'**
  String get notificationsPreferencesSaved;

  /// No description provided for @notificationsPreferencesLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar preferencias.'**
  String get notificationsPreferencesLoadError;

  /// No description provided for @notificationsPreferencesRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get notificationsPreferencesRetry;

  /// No description provided for @notificationsPreferencesNoContext.
  ///
  /// In es, this message translates to:
  /// **'No hay un contexto seleccionado para configurar notificaciones.'**
  String get notificationsPreferencesNoContext;

  /// No description provided for @notificationsChannelInApp.
  ///
  /// In es, this message translates to:
  /// **'In-app'**
  String get notificationsChannelInApp;

  /// No description provided for @notificationsChannelPush.
  ///
  /// In es, this message translates to:
  /// **'Push'**
  String get notificationsChannelPush;

  /// No description provided for @notificationsChannelsUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Email / WhatsApp / SMS: Proximamente'**
  String get notificationsChannelsUpcoming;

  /// No description provided for @notificationsEventReclamoNuevo.
  ///
  /// In es, this message translates to:
  /// **'Reclamo nuevo'**
  String get notificationsEventReclamoNuevo;

  /// No description provided for @notificationsEventReclamoRespuesta.
  ///
  /// In es, this message translates to:
  /// **'Reclamo: respuesta'**
  String get notificationsEventReclamoRespuesta;

  /// No description provided for @notificationsEventExpensaEmitida.
  ///
  /// In es, this message translates to:
  /// **'Expensa emitida'**
  String get notificationsEventExpensaEmitida;

  /// No description provided for @notificationsEventExpensaVencida.
  ///
  /// In es, this message translates to:
  /// **'Expensa vencida'**
  String get notificationsEventExpensaVencida;

  /// No description provided for @notificationsEventReservaConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada'**
  String get notificationsEventReservaConfirmada;

  /// No description provided for @notificationsEventReservaCancelada.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get notificationsEventReservaCancelada;

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
