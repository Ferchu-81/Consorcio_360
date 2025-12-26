// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get roleAdminConsorcio => 'Sindico';

  @override
  String get rolePropietario => 'Proprietario';

  @override
  String get roleOcupanteDefault => 'Inquilino';

  @override
  String get notificationsTitle => 'Notificacoes';

  @override
  String get notificationsLoadError => 'Erro ao carregar notificacoes.';

  @override
  String get notificationsRetry => 'Tentar novamente.';

  @override
  String get notificationsEmpty => 'Sem notificacoes por enquanto.';

  @override
  String get notificationsNoDestination => 'Notificacao sem destino.';

  @override
  String get notificationsMissingReclamoId => 'Reclamacao sem id.';

  @override
  String get notificationsMissingExpensaId => 'Expensa sem id.';

  @override
  String get notificationsExpensaNotFound => 'Expensa nao encontrada.';

  @override
  String get notificationsReservaUnavailable => 'Reservas nao disponivel.';

  @override
  String get notificationsPreferencesTitle => 'Preferencias';

  @override
  String get notificationsPreferencesRoleTitle => 'Este papel';

  @override
  String get notificationsPreferencesRoleHint =>
      'Preferencias para o papel atual.';

  @override
  String get notificationsPreferencesEventsTitle => 'Eventos';

  @override
  String get notificationsPreferencesApplyAllTitle =>
      'Aplicar a todos os meus papeis';

  @override
  String get notificationsPreferencesApplyAllSubtitle =>
      'Copiar estas preferencias para os meus outros papeis neste consorcio.';

  @override
  String get notificationsPreferencesSave => 'Salvar';

  @override
  String get notificationsPreferencesSaved => 'Preferencias salvas.';

  @override
  String get notificationsPreferencesLoadError =>
      'Erro ao carregar preferencias.';

  @override
  String get notificationsPreferencesRetry => 'Tentar novamente';

  @override
  String get notificationsPreferencesNoContext =>
      'Nenhum contexto selecionado para configurar notificacoes.';

  @override
  String get notificationsChannelInApp => 'In-app';

  @override
  String get notificationsChannelPush => 'Push';

  @override
  String get notificationsChannelsUpcoming =>
      'Email / WhatsApp / SMS: Em breve';

  @override
  String get notificationsEventReclamoNuevo => 'Reclamacao nova';

  @override
  String get notificationsEventReclamoRespuesta => 'Reclamacao: resposta';

  @override
  String get notificationsEventExpensaEmitida => 'Expensa emitida';

  @override
  String get notificationsEventExpensaVencida => 'Expensa vencida';

  @override
  String get notificationsEventReservaConfirmada => 'Reserva confirmada';

  @override
  String get notificationsEventReservaCancelada => 'Reserva cancelada';

  @override
  String get roleAdmin => 'Síndico';

  @override
  String get roleOwner => 'Proprietário';

  @override
  String get roleTenant => 'Inquilino';

  @override
  String get roleOccupant => 'Morador';

  @override
  String get roleOwnerOrTenant => 'Proprietário / Inquilino';

  @override
  String get isPrimaryOwner => 'Titular';

  @override
  String get occupiesUnit => 'Ocupa';

  @override
  String get cfgAmenitiesOwnerNonOccupantTitle =>
      'Proprietário não residente: acesso às áreas comuns (uso e reserva)';

  @override
  String get cfgAmenitiesOwnerNonOccupantSubtitle =>
      'Permite usar e reservar áreas comuns mesmo sem morar na unidade.';

  @override
  String get cfgOwnerVoteWithoutOccupyingTitle =>
      'Voto do proprietário sem residir';

  @override
  String get cfgOwnerVoteWithoutOccupyingSubtitle =>
      'Permite que o proprietário vote mesmo com um residente na unidade.';

  @override
  String get unit => 'Unidade';
}
