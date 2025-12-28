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
  String get notificationsInboxTitle => 'Notificações';

  @override
  String get notificationsMarkAllRead => 'Marcar tudo como lido';

  @override
  String get notificationsLoadError => 'Erro ao carregar notificacoes.';

  @override
  String get notificationsRetry => 'Tentar novamente.';

  @override
  String get notificationsEmpty => 'Você ainda não tem notificações.';

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
  String get roleOccupantDefault => 'Morador';

  @override
  String get roleAdmin_description =>
      'Rótulo de função: administrador do condomínio';

  @override
  String get roleOwner_description => 'Rótulo de função: proprietário';

  @override
  String get roleOccupantDefault_description =>
      'Rótulo de função: ocupante (padrão)';

  @override
  String get neighbor => 'Vizinho';

  @override
  String get neighbor_description =>
      'Rótulo genérico quando o papel do usuário é desconhecido';

  @override
  String get genericUser => 'Usuário';

  @override
  String get selfLabel => 'Eu';

  @override
  String get reclamoPdfTitle => 'Registro de reclamação';

  @override
  String get reclamoPdfConsorcio => 'Condomínio';

  @override
  String get reclamoPdfUnidad => 'Unidade';

  @override
  String get reclamoPdfTitulo => 'Titulo';

  @override
  String get reclamoPdfTipo => 'Tipo';

  @override
  String get reclamoPdfEstado => 'Status';

  @override
  String get reclamoPdfPrioridad => 'Prioridade';

  @override
  String get reclamoPdfFechaEmision => 'Data de emissão';

  @override
  String get reclamoPdfDescripcionInicial => 'Descrição inicial:';

  @override
  String get reclamoPdfParticipantes => 'Participantes da reclamação';

  @override
  String get reclamoPdfConversacion => 'Conversa da reclamação';

  @override
  String get reclamoPdfMensajesVacios =>
      'Nenhuma mensagem registrada para esta reclamação.';

  @override
  String get reclamoPdfColFechaHora => 'Data e hora';

  @override
  String get reclamoPdfColEmisor => 'Remetente';

  @override
  String get reclamoPdfColMensaje => 'Mensagem';

  @override
  String get reclamoPdfAdjuntosTitulo => 'Anexos';

  @override
  String get reclamoPdfAdjuntosColNumero => 'Nº';

  @override
  String get reclamoPdfAdjuntosColAutor => 'Autor';

  @override
  String get reclamoPdfAdjuntosColTipo => 'Tipo';

  @override
  String get reclamoPdfAdjuntosColNombre => 'Arquivo';

  @override
  String get reclamoAdjuntoTipoPdf => 'PDF';

  @override
  String get reclamoAdjuntoTipoImagen => 'Imagem';

  @override
  String get reclamoAdjuntoTipoDesconocido => 'Desconhecido';

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
  String get unitLabel => 'Unidade';

  @override
  String get unit => 'Unidade';

  @override
  String get settingsAppVersion => 'Versão do app';
}
