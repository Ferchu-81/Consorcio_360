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
  String get notificationsInboxTitle => 'Notificaciones';

  @override
  String get notificationsMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsLoadError => 'Error al cargar notificaciones.';

  @override
  String get notificationsRetry => 'Reintentar';

  @override
  String get notificationsEmpty => 'No tenés notificaciones todavía.';

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
  String get roleOccupantDefault => 'Inquilino';

  @override
  String get roleAdmin_description =>
      'Label de rol: administrador del consorcio';

  @override
  String get roleOwner_description => 'Label de rol: propietario';

  @override
  String get roleOccupantDefault_description =>
      'Label de rol: ocupante (por defecto AR: Inquilino)';

  @override
  String get neighbor => 'Vecino';

  @override
  String get neighbor_description =>
      'Label genérico para un usuario cuando no se conoce su rol';

  @override
  String get genericUser => 'Usuario';

  @override
  String get selfLabel => 'Yo';

  @override
  String get reclamoPdfTitle => 'Expediente de reclamo';

  @override
  String get reclamoPdfConsorcio => 'Consorcio';

  @override
  String get reclamoPdfUnidad => 'Unidad';

  @override
  String get reclamoPdfTitulo => 'Titulo';

  @override
  String get reclamoPdfTipo => 'Tipo';

  @override
  String get reclamoPdfEstado => 'Estado';

  @override
  String get reclamoPdfPrioridad => 'Prioridad';

  @override
  String get reclamoPdfFechaEmision => 'Fecha emision';

  @override
  String get reclamoPdfDescripcionInicial => 'Descripcion inicial:';

  @override
  String get reclamoPdfParticipantes => 'Participantes del reclamo';

  @override
  String get reclamoPdfConversacion => 'Conversacion del reclamo';

  @override
  String get reclamoPdfMensajesVacios =>
      'No hay mensajes registrados para este reclamo.';

  @override
  String get reclamoPdfColFechaHora => 'Fecha y hora';

  @override
  String get reclamoPdfColEmisor => 'Emisor';

  @override
  String get reclamoPdfColMensaje => 'Mensaje';

  @override
  String get reclamoPdfAdjuntosTitulo => 'Adjuntos';

  @override
  String get reclamoPdfAdjuntosColNumero => 'N°';

  @override
  String get reclamoPdfAdjuntosColAutor => 'Autor';

  @override
  String get reclamoPdfAdjuntosColTipo => 'Tipo';

  @override
  String get reclamoPdfAdjuntosColNombre => 'Archivo';

  @override
  String get reclamoAdjuntoTipoPdf => 'PDF';

  @override
  String get reclamoAdjuntoTipoImagen => 'Imagen';

  @override
  String get reclamoAdjuntoTipoDesconocido => 'Desconocido';

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
  String get unitLabel => 'Unidad';

  @override
  String get unit => 'Unidad';

  @override
  String get settingsAppVersion => 'Versión de la app';

  @override
  String get helpContextualTitle => 'Ayudas contextuales';

  @override
  String get helpContextualDescription =>
      'Mantené presionado 1 segundo para ver una ayuda rápida. Podés desactivarlas cuando quieras.';

  @override
  String get helpContextualEnable => 'Activar ayudas';

  @override
  String get helpContextualDisable => 'Desactivar ayudas';

  @override
  String get helpSectionTitle => 'Ayudas';

  @override
  String get helpContextualSwitchSubtitle =>
      'Pulsación larga (1s) para ver explicaciones';

  @override
  String get helpMainNotifications => 'Ver notificaciones y avisos.';

  @override
  String get helpMainSettings => 'Abrir configuración de la app.';

  @override
  String get helpMainChangeContext => 'Cambiar consorcio, unidad o rol.';

  @override
  String get helpMainLogout => 'Cerrar sesión.';

  @override
  String get helpDashboardExpensasSummary =>
      'Resumen de expensas del último año.';

  @override
  String get helpDashboardReclamosSummary =>
      'Resumen de reclamos activos y resueltos.';

  @override
  String get helpDashboardBasesLegales => 'Abrir bases legales del consorcio.';

  @override
  String get helpSettingsProfile => 'Ver y editar tus datos personales.';

  @override
  String get helpSettingsNotifications => 'Elegí qué avisos querés recibir.';

  @override
  String get helpSettingsBasesLegales => 'Accedé a reglamentos y normativa.';

  @override
  String get helpSettingsUnidad => 'Información declarada de tu unidad.';

  @override
  String get helpSettingsReglasConsorcio =>
      'Reglas y votaciones del consorcio.';

  @override
  String get helpSettingsConsorcioConfig => 'Ajustes globales del consorcio.';

  @override
  String get helpSettingsAmenitiesAdmin => 'Administrar amenities y reservas.';

  @override
  String get helpSettingsAmenitiesUser => 'Ver y reservar amenities.';

  @override
  String get helpSettingsAppVersion => 'Versión instalada de la app.';

  @override
  String get helpSettingsLogout => 'Salir de tu cuenta.';

  @override
  String get helpReclamoNew => 'Crear un nuevo reclamo.';

  @override
  String get helpReclamoDetail => 'Abrir detalle del reclamo.';

  @override
  String get helpReclamoReloadConsorcio =>
      'Volver a cargar reclamos del consorcio.';

  @override
  String get helpExpensaNew => 'Crear una nueva expensa.';

  @override
  String get helpExpensaDetail => 'Abrir detalle de la expensa.';

  @override
  String get helpExpensaReload => 'Volver a cargar expensas.';

  @override
  String get helpExpensaDateFrom => 'Seleccioná periodo DESDE';

  @override
  String get helpExpensaDateTo => 'Seleccioná periodo HASTA';

  @override
  String get helpPagoDetail => 'Detalle de pago registrado.';

  @override
  String get helpInboxToggleAllOn => 'Mostrar solo este contexto';

  @override
  String get helpInboxToggleAllOff => 'Mostrar todos mis contextos';

  @override
  String get helpInboxShowAllTooltip => 'Ver todo';

  @override
  String get helpInboxShowContextTooltip => 'Ver contexto';

  @override
  String get helpInboxMarkAllRead => 'Marcar todo como leído.';

  @override
  String get helpInboxMarkAsRead => 'Marcar como leído.';

  @override
  String get helpInboxAlreadyRead => 'Ya está leída.';

  @override
  String get helpInboxSnackShowAll => 'Mostrando todas las notificaciones.';

  @override
  String get helpInboxSnackShowContext => 'Mostrando solo el contexto actual.';

  @override
  String get helpInboxShowAllRestricted =>
      'Solo administradores pueden ver todo.';
}
