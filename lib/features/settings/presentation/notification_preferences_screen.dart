import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final Map<String, _PreferenceState> _prefsByEvent = {};

  bool _loading = true;
  bool _saving = false;
  bool _available = true;
  bool _applyToAll = false;
  bool _hasError = false;

  static const List<String> _eventTypes = [
    'RECLAMO_NUEVO',
    'RECLAMO_RESPUESTA',
    'EXPENSA_EMITIDA',
    'EXPENSA_VENCIDA',
    'RESERVA_CONFIRMADA',
    'RESERVA_CANCELADA',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ctx = context.read<CurrentContextNotifier>().current;
    final user = _client.auth.currentUser;

    if (ctx == null || user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _available = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final defaults = {
        for (final eventType in _eventTypes) eventType: _PreferenceState(),
      };

      final rows = await _client
          .from('notificacion_preferencias')
          .select(
            'event_type, in_app_enabled, push_enabled, email_enabled, '
            'whatsapp_enabled, sms_enabled, aplicar_a_todos_roles',
          )
          .eq('usuario_id', user.id)
          .eq('consorcio_id', ctx.consorcioId)
          .eq('rol', ctx.rol);

      bool applyAll = false;
      for (final row in List<Map<String, dynamic>>.from(rows as List)) {
        final eventType = row['event_type']?.toString();
        if (eventType == null || !defaults.containsKey(eventType)) continue;

        defaults[eventType] = _PreferenceState(
          inApp: row['in_app_enabled'] as bool? ?? true,
          push: row['push_enabled'] as bool? ?? false,
          email: row['email_enabled'] as bool? ?? false,
          whatsapp: row['whatsapp_enabled'] as bool? ?? false,
          sms: row['sms_enabled'] as bool? ?? false,
        );

        if (row['aplicar_a_todos_roles'] == true) {
          applyAll = true;
        }
      }

      if (!mounted) return;
      setState(() {
        _prefsByEvent
          ..clear()
          ..addAll(defaults);
        _applyToAll = applyAll;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  _PreferenceState _stateFor(String eventType) {
    return _prefsByEvent.putIfAbsent(eventType, () => _PreferenceState());
  }

  Future<Set<String>> _fetchRolesForConsorcio({
    required String userId,
    required String consorcioId,
  }) async {
    final rows = await _client
        .from('usuarios_unidades')
        .select('rol, unidades(consorcio_id)')
        .eq('usuario_id', userId);

    final roles = <String>{};
    for (final row in List<Map<String, dynamic>>.from(rows as List)) {
      final rol = row['rol']?.toString();
      if (rol == null || rol.isEmpty) continue;
      final unidad = row['unidades'] as Map<String, dynamic>?;
      final rowConsorcioId = unidad?['consorcio_id']?.toString();
      if (rowConsorcioId == consorcioId) {
        roles.add(rol);
      }
    }

    return roles;
  }

  Future<void> _save() async {
    if (_saving) return;
    final ctx = context.read<CurrentContextNotifier>().current;
    final user = _client.auth.currentUser;
    if (ctx == null || user == null) return;

    setState(() => _saving = true);

    try {
      final roles = _applyToAll
          ? await _fetchRolesForConsorcio(
              userId: user.id,
              consorcioId: ctx.consorcioId,
            )
          : <String>{ctx.rol};

      if (roles.isEmpty) {
        roles.add(ctx.rol);
      }

      final now = DateTime.now().toIso8601String();
      final payload = <Map<String, dynamic>>[];

      for (final rol in roles) {
        for (final eventType in _eventTypes) {
          final state = _stateFor(eventType);
          payload.add({
            'usuario_id': user.id,
            'consorcio_id': ctx.consorcioId,
            'rol': rol,
            'event_type': eventType,
            'in_app_enabled': state.inApp,
            'push_enabled': state.push,
            'email_enabled': state.email,
            'whatsapp_enabled': state.whatsapp,
            'sms_enabled': state.sms,
            'aplicar_a_todos_roles': _applyToAll,
            'updated_at': now,
          });
        }
      }

      await _client
          .from('notificacion_preferencias')
          .upsert(payload, onConflict: 'usuario_id,consorcio_id,rol,event_type');

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationsPreferencesSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationsPreferencesLoadError)),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _eventLabel(String eventType, AppLocalizations l10n) {
    switch (eventType) {
      case 'RECLAMO_NUEVO':
        return l10n.notificationsEventReclamoNuevo;
      case 'RECLAMO_RESPUESTA':
        return l10n.notificationsEventReclamoRespuesta;
      case 'EXPENSA_EMITIDA':
        return l10n.notificationsEventExpensaEmitida;
      case 'EXPENSA_VENCIDA':
        return l10n.notificationsEventExpensaVencida;
      case 'RESERVA_CONFIRMADA':
        return l10n.notificationsEventReservaConfirmada;
      case 'RESERVA_CANCELADA':
        return l10n.notificationsEventReservaCancelada;
      default:
        return eventType;
    }
  }

  Widget _buildEventCard(
    AppLocalizations l10n,
    String eventType,
    _PreferenceState state,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _eventLabel(eventType, l10n),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.notificationsChannelInApp),
              value: state.inApp,
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                        _prefsByEvent[eventType] =
                            state.copyWith(inApp: value);
                      }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.notificationsChannelPush),
              value: state.push,
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                        _prefsByEvent[eventType] =
                            state.copyWith(push: value);
                      }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctx = context.watch<CurrentContextNotifier>().current;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notificationsPreferencesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_available || ctx == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notificationsPreferencesTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.notificationsPreferencesNoContext,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notificationsPreferencesTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.notificationsPreferencesLoadError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.notificationsPreferencesRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsPreferencesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.notificationsPreferencesRoleTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.notificationsPreferencesRoleHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${ctx.consorcioNombre} - ${ctx.unidadCodigo}\n'
                    '${roleLabel(context, ctx.rol)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.notificationsPreferencesEventsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final eventType in _eventTypes)
            _buildEventCard(
              l10n,
              eventType,
              _stateFor(eventType),
            ),
          const SizedBox(height: 4),
          Text(
            l10n.notificationsChannelsUpcoming,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(l10n.notificationsPreferencesApplyAllTitle),
            subtitle: Text(l10n.notificationsPreferencesApplyAllSubtitle),
            value: _applyToAll,
            onChanged: _saving
                ? null
                : (value) => setState(() => _applyToAll = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.notificationsPreferencesSave),
          ),
        ],
      ),
    );
  }
}

class _PreferenceState {
  final bool inApp;
  final bool push;
  final bool email;
  final bool whatsapp;
  final bool sms;

  const _PreferenceState({
    this.inApp = true,
    this.push = false,
    this.email = false,
    this.whatsapp = false,
    this.sms = false,
  });

  _PreferenceState copyWith({
    bool? inApp,
    bool? push,
    bool? email,
    bool? whatsapp,
    bool? sms,
  }) {
    return _PreferenceState(
      inApp: inApp ?? this.inApp,
      push: push ?? this.push,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
      sms: sms ?? this.sms,
    );
  }
}
