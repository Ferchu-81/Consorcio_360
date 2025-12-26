// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get roleAdminConsorcio => 'Administrador';

  @override
  String get rolePropietario => 'Propietario';

  @override
  String get roleOcupanteDefault => 'Inquilino';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsLoadError => 'Error al cargar notificaciones.';

  @override
  String get notificationsRetry => 'Reintentar';

  @override
  String get notificationsEmpty => 'No hay notificaciones por ahora.';

  @override
  String get notificationsNoDestination => 'Notificacion sin destino.';

  @override
  String get notificationsMissingReclamoId => 'Reclamo sin id.';

  @override
  String get notificationsMissingExpensaId => 'Expensa sin id.';

  @override
  String get notificationsExpensaNotFound => 'Expensa no encontrada.';

  @override
  String get notificationsReservaUnavailable => 'Reservas no disponible.';

  @override
  String get notificationsPreferencesTitle => 'Preferencias';

  @override
  String get notificationsPreferencesRoleTitle => 'Este rol';

  @override
  String get notificationsPreferencesRoleHint =>
      'Preferencias para el rol actual.';

  @override
  String get notificationsPreferencesEventsTitle => 'Eventos';

  @override
  String get notificationsPreferencesApplyAllTitle =>
      'Aplicar a todos mis roles';

  @override
  String get notificationsPreferencesApplyAllSubtitle =>
      'Copia estas preferencias a mis otros roles en este consorcio.';

  @override
  String get notificationsPreferencesSave => 'Guardar';

  @override
  String get notificationsPreferencesSaved => 'Preferencias guardadas.';

  @override
  String get notificationsPreferencesLoadError =>
      'Error al cargar preferencias.';

  @override
  String get notificationsPreferencesRetry => 'Reintentar';

  @override
  String get notificationsPreferencesNoContext =>
      'No hay un contexto seleccionado para configurar notificaciones.';

  @override
  String get notificationsChannelInApp => 'In-app';

  @override
  String get notificationsChannelPush => 'Push';

  @override
  String get notificationsChannelsUpcoming =>
      'Email / WhatsApp / SMS: Proximamente';

  @override
  String get notificationsEventReclamoNuevo => 'Reclamo nuevo';

  @override
  String get notificationsEventReclamoRespuesta => 'Reclamo: respuesta';

  @override
  String get notificationsEventExpensaEmitida => 'Expensa emitida';

  @override
  String get notificationsEventExpensaVencida => 'Expensa vencida';

  @override
  String get notificationsEventReservaConfirmada => 'Reserva confirmada';

  @override
  String get notificationsEventReservaCancelada => 'Reserva cancelada';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleTenant => 'Inquilino';

  @override
  String get roleOccupant => 'Ocupante';

  @override
  String get roleOwnerOrTenant => 'Propietario / Inquilino';

  @override
  String get isPrimaryOwner => 'Titular';

  @override
  String get occupiesUnit => 'Ocupa';

  @override
  String get cfgAmenitiesOwnerNonOccupantTitle =>
      'Propietario no ocupante: acceso a amenities (uso y reserva)';

  @override
  String get cfgAmenitiesOwnerNonOccupantSubtitle =>
      'Permite usar y reservar amenities aunque no viva en la unidad.';

  @override
  String get cfgOwnerVoteWithoutOccupyingTitle =>
      'Voto del propietario sin ocupar';

  @override
  String get cfgOwnerVoteWithoutOccupyingSubtitle =>
      'Permite votar al propietario aunque haya un ocupante en la unidad.';

  @override
  String get unit => 'Unidad';
}
