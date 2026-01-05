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

  /// No description provided for @notificationsInboxTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsInboxTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get notificationsMarkAllRead;

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
  /// **'No tenés notificaciones todavía.'**
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

  /// No description provided for @roleOccupantDefault.
  ///
  /// In es, this message translates to:
  /// **'Inquilino'**
  String get roleOccupantDefault;

  /// No description provided for @roleAdmin_description.
  ///
  /// In es, this message translates to:
  /// **'Label de rol: administrador del consorcio'**
  String get roleAdmin_description;

  /// No description provided for @roleOwner_description.
  ///
  /// In es, this message translates to:
  /// **'Label de rol: propietario'**
  String get roleOwner_description;

  /// No description provided for @roleOccupantDefault_description.
  ///
  /// In es, this message translates to:
  /// **'Label de rol: ocupante (por defecto AR: Inquilino)'**
  String get roleOccupantDefault_description;

  /// No description provided for @neighbor.
  ///
  /// In es, this message translates to:
  /// **'Vecino'**
  String get neighbor;

  /// No description provided for @neighbor_description.
  ///
  /// In es, this message translates to:
  /// **'Label genérico para un usuario cuando no se conoce su rol'**
  String get neighbor_description;

  /// No description provided for @genericUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get genericUser;

  /// No description provided for @selfLabel.
  ///
  /// In es, this message translates to:
  /// **'Yo'**
  String get selfLabel;

  /// No description provided for @reclamoPdfTitle.
  ///
  /// In es, this message translates to:
  /// **'Expediente de reclamo'**
  String get reclamoPdfTitle;

  /// No description provided for @reclamoPdfConsorcio.
  ///
  /// In es, this message translates to:
  /// **'Consorcio'**
  String get reclamoPdfConsorcio;

  /// No description provided for @reclamoPdfUnidad.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get reclamoPdfUnidad;

  /// No description provided for @reclamoPdfTitulo.
  ///
  /// In es, this message translates to:
  /// **'Titulo'**
  String get reclamoPdfTitulo;

  /// No description provided for @reclamoPdfTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get reclamoPdfTipo;

  /// No description provided for @reclamoPdfEstado.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get reclamoPdfEstado;

  /// No description provided for @reclamoPdfPrioridad.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get reclamoPdfPrioridad;

  /// No description provided for @reclamoPdfFechaEmision.
  ///
  /// In es, this message translates to:
  /// **'Fecha emision'**
  String get reclamoPdfFechaEmision;

  /// No description provided for @reclamoPdfDescripcionInicial.
  ///
  /// In es, this message translates to:
  /// **'Descripcion inicial:'**
  String get reclamoPdfDescripcionInicial;

  /// No description provided for @reclamoPdfParticipantes.
  ///
  /// In es, this message translates to:
  /// **'Participantes del reclamo'**
  String get reclamoPdfParticipantes;

  /// No description provided for @reclamoPdfConversacion.
  ///
  /// In es, this message translates to:
  /// **'Conversacion del reclamo'**
  String get reclamoPdfConversacion;

  /// No description provided for @reclamoPdfMensajesVacios.
  ///
  /// In es, this message translates to:
  /// **'No hay mensajes registrados para este reclamo.'**
  String get reclamoPdfMensajesVacios;

  /// No description provided for @reclamoPdfColFechaHora.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get reclamoPdfColFechaHora;

  /// No description provided for @reclamoPdfColEmisor.
  ///
  /// In es, this message translates to:
  /// **'Emisor'**
  String get reclamoPdfColEmisor;

  /// No description provided for @reclamoPdfColMensaje.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get reclamoPdfColMensaje;

  /// No description provided for @reclamoPdfAdjuntosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Adjuntos'**
  String get reclamoPdfAdjuntosTitulo;

  /// No description provided for @reclamoPdfAdjuntosColNumero.
  ///
  /// In es, this message translates to:
  /// **'N°'**
  String get reclamoPdfAdjuntosColNumero;

  /// No description provided for @reclamoPdfAdjuntosColAutor.
  ///
  /// In es, this message translates to:
  /// **'Autor'**
  String get reclamoPdfAdjuntosColAutor;

  /// No description provided for @reclamoPdfAdjuntosColTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get reclamoPdfAdjuntosColTipo;

  /// No description provided for @reclamoPdfAdjuntosColNombre.
  ///
  /// In es, this message translates to:
  /// **'Archivo'**
  String get reclamoPdfAdjuntosColNombre;

  /// No description provided for @reclamoAdjuntoTipoPdf.
  ///
  /// In es, this message translates to:
  /// **'PDF'**
  String get reclamoAdjuntoTipoPdf;

  /// No description provided for @reclamoAdjuntoTipoImagen.
  ///
  /// In es, this message translates to:
  /// **'Imagen'**
  String get reclamoAdjuntoTipoImagen;

  /// No description provided for @reclamoAdjuntoTipoDesconocido.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get reclamoAdjuntoTipoDesconocido;

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

  /// No description provided for @unitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get unitLabel;

  /// No description provided for @unit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get unit;

  /// No description provided for @settingsAppVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión de la app'**
  String get settingsAppVersion;

  /// No description provided for @helpContextualTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayudas contextuales'**
  String get helpContextualTitle;

  /// No description provided for @helpContextualDescription.
  ///
  /// In es, this message translates to:
  /// **'Mantené presionado 1 segundo para ver una ayuda rápida. Podés desactivarlas cuando quieras.'**
  String get helpContextualDescription;

  /// No description provided for @helpContextualEnable.
  ///
  /// In es, this message translates to:
  /// **'Activar ayudas'**
  String get helpContextualEnable;

  /// No description provided for @helpContextualDisable.
  ///
  /// In es, this message translates to:
  /// **'Desactivar ayudas'**
  String get helpContextualDisable;

  /// No description provided for @helpSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayudas'**
  String get helpSectionTitle;

  /// No description provided for @helpContextualSwitchSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pulsación larga (1s) para ver explicaciones'**
  String get helpContextualSwitchSubtitle;

  /// No description provided for @helpMainNotifications.
  ///
  /// In es, this message translates to:
  /// **'Ver notificaciones y avisos.'**
  String get helpMainNotifications;

  /// No description provided for @helpMainSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración de la app.'**
  String get helpMainSettings;

  /// No description provided for @helpMainChangeContext.
  ///
  /// In es, this message translates to:
  /// **'Cambiar consorcio, unidad o rol.'**
  String get helpMainChangeContext;

  /// No description provided for @helpMainLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión.'**
  String get helpMainLogout;

  /// No description provided for @helpDashboardExpensasSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de expensas del último año.'**
  String get helpDashboardExpensasSummary;

  /// No description provided for @helpDashboardReclamosSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de reclamos activos y resueltos.'**
  String get helpDashboardReclamosSummary;

  /// No description provided for @helpDashboardBasesLegales.
  ///
  /// In es, this message translates to:
  /// **'Abrir bases legales del consorcio.'**
  String get helpDashboardBasesLegales;

  /// No description provided for @helpSettingsProfile.
  ///
  /// In es, this message translates to:
  /// **'Ver y editar tus datos personales.'**
  String get helpSettingsProfile;

  /// No description provided for @helpSettingsNotifications.
  ///
  /// In es, this message translates to:
  /// **'Elegí qué avisos querés recibir.'**
  String get helpSettingsNotifications;

  /// No description provided for @helpSettingsBasesLegales.
  ///
  /// In es, this message translates to:
  /// **'Accedé a reglamentos y normativa.'**
  String get helpSettingsBasesLegales;

  /// No description provided for @helpSettingsUnidad.
  ///
  /// In es, this message translates to:
  /// **'Información declarada de tu unidad.'**
  String get helpSettingsUnidad;

  /// No description provided for @helpSettingsReglasConsorcio.
  ///
  /// In es, this message translates to:
  /// **'Reglas y votaciones del consorcio.'**
  String get helpSettingsReglasConsorcio;

  /// No description provided for @helpSettingsConsorcioConfig.
  ///
  /// In es, this message translates to:
  /// **'Ajustes globales del consorcio.'**
  String get helpSettingsConsorcioConfig;

  /// No description provided for @helpSettingsAmenitiesAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrar amenities y reservas.'**
  String get helpSettingsAmenitiesAdmin;

  /// No description provided for @helpSettingsAmenitiesUser.
  ///
  /// In es, this message translates to:
  /// **'Ver y reservar amenities.'**
  String get helpSettingsAmenitiesUser;

  /// No description provided for @helpSettingsAppVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión instalada de la app.'**
  String get helpSettingsAppVersion;

  /// No description provided for @helpSettingsLogout.
  ///
  /// In es, this message translates to:
  /// **'Salir de tu cuenta.'**
  String get helpSettingsLogout;

  /// No description provided for @helpReclamoNew.
  ///
  /// In es, this message translates to:
  /// **'Crear un nuevo reclamo.'**
  String get helpReclamoNew;

  /// No description provided for @helpReclamoDetail.
  ///
  /// In es, this message translates to:
  /// **'Abrir detalle del reclamo.'**
  String get helpReclamoDetail;

  /// No description provided for @helpReclamoReloadConsorcio.
  ///
  /// In es, this message translates to:
  /// **'Volver a cargar reclamos del consorcio.'**
  String get helpReclamoReloadConsorcio;

  /// No description provided for @helpExpensaNew.
  ///
  /// In es, this message translates to:
  /// **'Crear una nueva expensa.'**
  String get helpExpensaNew;

  /// No description provided for @helpExpensaDetail.
  ///
  /// In es, this message translates to:
  /// **'Abrir detalle de la expensa.'**
  String get helpExpensaDetail;

  /// No description provided for @helpExpensaReload.
  ///
  /// In es, this message translates to:
  /// **'Volver a cargar expensas.'**
  String get helpExpensaReload;

  /// No description provided for @helpExpensaDateFrom.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná periodo DESDE'**
  String get helpExpensaDateFrom;

  /// No description provided for @helpExpensaDateTo.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná periodo HASTA'**
  String get helpExpensaDateTo;

  /// No description provided for @helpPagoDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de pago registrado.'**
  String get helpPagoDetail;

  /// No description provided for @helpInboxToggleAllOn.
  ///
  /// In es, this message translates to:
  /// **'Mostrar solo este contexto'**
  String get helpInboxToggleAllOn;

  /// No description provided for @helpInboxToggleAllOff.
  ///
  /// In es, this message translates to:
  /// **'Mostrar todos mis contextos'**
  String get helpInboxToggleAllOff;

  /// No description provided for @helpInboxShowAllTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get helpInboxShowAllTooltip;

  /// No description provided for @helpInboxShowContextTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ver contexto'**
  String get helpInboxShowContextTooltip;

  /// No description provided for @helpInboxMarkAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído.'**
  String get helpInboxMarkAllRead;

  /// No description provided for @helpInboxMarkAsRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar como leído.'**
  String get helpInboxMarkAsRead;

  /// No description provided for @helpInboxAlreadyRead.
  ///
  /// In es, this message translates to:
  /// **'Ya está leída.'**
  String get helpInboxAlreadyRead;

  /// No description provided for @helpInboxSnackShowAll.
  ///
  /// In es, this message translates to:
  /// **'Mostrando todas las notificaciones.'**
  String get helpInboxSnackShowAll;

  /// No description provided for @helpInboxSnackShowContext.
  ///
  /// In es, this message translates to:
  /// **'Mostrando solo el contexto actual.'**
  String get helpInboxSnackShowContext;

  /// No description provided for @helpInboxShowAllRestricted.
  ///
  /// In es, this message translates to:
  /// **'Solo administradores pueden ver todo.'**
  String get helpInboxShowAllRestricted;
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
