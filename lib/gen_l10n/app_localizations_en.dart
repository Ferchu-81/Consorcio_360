// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get roleAdminConsorcio => 'Administrator';

  @override
  String get rolePropietario => 'Owner';

  @override
  String get roleOcupanteDefault => 'Tenant';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsInboxTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsLoadError => 'Error loading notifications.';

  @override
  String get notificationsRetry => 'Retry';

  @override
  String get notificationsEmpty => 'You don\'t have notifications yet.';

  @override
  String get notificationsNoDestination => 'Notification has no destination.';

  @override
  String get notificationsMissingReclamoId => 'Claim without id.';

  @override
  String get notificationsMissingExpensaId => 'Expense without id.';

  @override
  String get notificationsExpensaNotFound => 'Expense not found.';

  @override
  String get notificationsReservaUnavailable => 'Reservations not available.';

  @override
  String get notificationsPreferencesTitle => 'Preferences';

  @override
  String get notificationsPreferencesRoleTitle => 'This role';

  @override
  String get notificationsPreferencesRoleHint =>
      'Preferences for the current role.';

  @override
  String get notificationsPreferencesEventsTitle => 'Events';

  @override
  String get notificationsPreferencesApplyAllTitle => 'Apply to all my roles';

  @override
  String get notificationsPreferencesApplyAllSubtitle =>
      'Copy these preferences to my other roles in this consortium.';

  @override
  String get notificationsPreferencesSave => 'Save';

  @override
  String get notificationsPreferencesSaved => 'Preferences saved.';

  @override
  String get notificationsPreferencesLoadError => 'Error loading preferences.';

  @override
  String get notificationsPreferencesRetry => 'Retry';

  @override
  String get notificationsPreferencesNoContext =>
      'No context selected to configure notifications.';

  @override
  String get notificationsChannelInApp => 'In-app';

  @override
  String get notificationsChannelPush => 'Push';

  @override
  String get notificationsChannelsUpcoming =>
      'Email / WhatsApp / SMS: Coming soon';

  @override
  String get notificationsEventReclamoNuevo => 'Claim: new';

  @override
  String get notificationsEventReclamoRespuesta => 'Claim: reply';

  @override
  String get notificationsEventExpensaEmitida => 'Expense issued';

  @override
  String get notificationsEventExpensaVencida => 'Expense overdue';

  @override
  String get notificationsEventReservaConfirmada => 'Reservation confirmed';

  @override
  String get notificationsEventReservaCancelada => 'Reservation canceled';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleOccupantDefault => 'Occupant';

  @override
  String get roleAdmin_description => 'Role label: building administrator';

  @override
  String get roleOwner_description => 'Role label: owner';

  @override
  String get roleOccupantDefault_description =>
      'Role label: occupant (default)';

  @override
  String get neighbor => 'Neighbor';

  @override
  String get neighbor_description =>
      'Generic label when user\'s role is unknown';

  @override
  String get genericUser => 'User';

  @override
  String get selfLabel => 'Me';

  @override
  String get reclamoPdfTitle => 'Claim record';

  @override
  String get reclamoPdfConsorcio => 'Building';

  @override
  String get reclamoPdfUnidad => 'Unit';

  @override
  String get reclamoPdfTitulo => 'Title';

  @override
  String get reclamoPdfTipo => 'Type';

  @override
  String get reclamoPdfEstado => 'Status';

  @override
  String get reclamoPdfPrioridad => 'Priority';

  @override
  String get reclamoPdfFechaEmision => 'Issued date';

  @override
  String get reclamoPdfDescripcionInicial => 'Initial description:';

  @override
  String get reclamoPdfParticipantes => 'Claim participants';

  @override
  String get reclamoPdfConversacion => 'Claim conversation';

  @override
  String get reclamoPdfMensajesVacios => 'No messages recorded for this claim.';

  @override
  String get reclamoPdfColFechaHora => 'Date & time';

  @override
  String get reclamoPdfColEmisor => 'Sender';

  @override
  String get reclamoPdfColMensaje => 'Message';

  @override
  String get reclamoPdfAdjuntosTitulo => 'Attachments';

  @override
  String get reclamoPdfAdjuntosColNumero => 'No.';

  @override
  String get reclamoPdfAdjuntosColAutor => 'Author';

  @override
  String get reclamoPdfAdjuntosColTipo => 'Type';

  @override
  String get reclamoPdfAdjuntosColNombre => 'File';

  @override
  String get reclamoAdjuntoTipoPdf => 'PDF';

  @override
  String get reclamoAdjuntoTipoImagen => 'Image';

  @override
  String get reclamoAdjuntoTipoDesconocido => 'Unknown';

  @override
  String get roleTenant => 'Tenant';

  @override
  String get roleOccupant => 'Occupant';

  @override
  String get roleOwnerOrTenant => 'Owner / Tenant';

  @override
  String get isPrimaryOwner => 'Primary';

  @override
  String get occupiesUnit => 'Occupies';

  @override
  String get cfgAmenitiesOwnerNonOccupantTitle =>
      'Non-occupant owner: amenities access (use and booking)';

  @override
  String get cfgAmenitiesOwnerNonOccupantSubtitle =>
      'Allows the owner to use and reserve amenities even when not living in the unit.';

  @override
  String get cfgOwnerVoteWithoutOccupyingTitle =>
      'Owner voting without occupying';

  @override
  String get cfgOwnerVoteWithoutOccupyingSubtitle =>
      'Allows the owner to vote even if there is an occupant in the unit.';

  @override
  String get unitLabel => 'Unit';

  @override
  String get unit => 'Unit';

  @override
  String get settingsAppVersion => 'App version';
}
