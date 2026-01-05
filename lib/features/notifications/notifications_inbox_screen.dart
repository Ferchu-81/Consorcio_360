import 'dart:async';

import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _prefHelpEnabledKey = 'ui_help_enabled';
const String _prefInboxShowAllKey = 'notif_inbox_show_all';

class NotificationsInboxScreen extends StatefulWidget {
  final String? notificationId;

  const NotificationsInboxScreen({super.key, this.notificationId});

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  static const double _estimatedTileExtent = 76;
  static const bool _forceShowAllDebug = true;

  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String? _highlightId;
  bool _helpEnabled = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _highlightId = widget.notificationId?.trim().isEmpty ?? true
        ? null
        : widget.notificationId?.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHelpEnabled();
      _loadInboxScope();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHelpEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_prefHelpEnabledKey);
      if (!mounted || value == null) return;
      setState(() => _helpEnabled = value);
    } catch (e, st) {
      debugPrint('NOTIFS _loadHelpEnabled error: $e\n$st');
    }
  }

  Future<void> _loadInboxScope() async {
    try {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      final l10n = AppLocalizations.of(context);
      final contexto = context.read<CurrentContextNotifier>().current;
      final isAdmin = contexto?.rol == 'ADMIN_CONSORCIO';
      final forceShowAll = _forceShowAllDebug;
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_prefInboxShowAllKey);
      if (!mounted) return;
      if (!isAdmin && !forceShowAll) {
        await prefs.setBool(_prefInboxShowAllKey, false);
        setState(() => _showAll = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          messenger?.showSnackBar(
            SnackBar(
              content: Text(l10n.helpInboxShowAllRestricted),
            ),
          );
        });
      } else if (forceShowAll) {
        setState(() => _showAll = true);
      } else if (value != null) {
        setState(() => _showAll = value);
      }
      await _load();
    } catch (e, st) {
      debugPrint('NOTIFS _loadInboxScope error: $e\n$st');
    }
  }

  Future<void> _toggleInboxScope() async {
    if (!mounted) return;
    if (_forceShowAllDebug) {
      debugPrint('NOTIFS toggle ignored: forceShowAllDebug enabled.');
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    final value = !_showAll;
    setState(() => _showAll = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefInboxShowAllKey, value);
    await _load();
    if (!mounted) return;
    final label = value
        ? l10n.helpInboxSnackShowAll
        : l10n.helpInboxSnackShowContext;
    messenger?.showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? '';
      if (userId.isEmpty) {
        setState(() {
          _error = 'No hay sesi\u00f3n activa (userId vac\u00edo).';
        });
        return;
      }

      final contexto = context.read<CurrentContextNotifier>().current;
      final consorcioId = (contexto?.consorcioId ?? '').trim();
      final unidadId = (contexto?.unidadId ?? '').trim();
      final isAdmin = contexto?.rol == 'ADMIN_CONSORCIO';
      debugPrint(
        'NOTIFS _load: userId=$userId consorcioId=$consorcioId unidadId=$unidadId',
      );
      debugPrint(
        'NOTIFS query: notificaciones.select(...).eq(usuario_id,$userId).order(created_at,desc).limit(80)',
      );

      var q = supabase
          .from('notificaciones')
          .select(
            'id, title, body, created_at, read_at, event_type, data, consorcio_id, unidad_id',
          )
          .eq('usuario_id', userId);

      final effectiveShowAll = _forceShowAllDebug || (_showAll && isAdmin);
      if (!effectiveShowAll) {
        if (consorcioId.isNotEmpty) {
          q = q.eq('consorcio_id', consorcioId);
        }
        if (unidadId.isNotEmpty) {
          q = q.eq('unidad_id', unidadId);
        }
      }

      final data = await q.order('created_at', ascending: false).limit(80);

      setState(() {
        _items = List<Map<String, dynamic>>.from(data);
      });
      _scrollToHighlightIfNeeded();
    } on PostgrestException catch (e) {
      debugPrint(
        'Postgrest error NOTIFS: message=${e.message} '
        'code=${e.code} details=${e.details} hint=${e.hint}',
      );
      setState(() {
        _error =
            'Supabase: ${e.message} (code=${e.code ?? '-'})\n'
            'details=${e.details ?? '-'}\n'
            'hint=${e.hint ?? '-'}';
      });
    } catch (e, st) {
      debugPrint('Error NOTIFS: $e\n$st');
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _scrollToHighlightIfNeeded() {
    final targetId = _highlightId;
    if (targetId == null || targetId.isEmpty) return;

    final index = _items.indexWhere((n) => n['id']?.toString() == targetId);
    if (index < 0) {
      debugPrint('NOTIFS highlight not found: id=$targetId');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final offset = (index * _estimatedTileExtent).clamp(0.0, max);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _markAsRead(String id) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();

    await supabase
        .from('notificaciones')
        .update({'read_at': now})
        .eq('id', id)
        .eq('usuario_id', userId);

    setState(() {
      _items = _items.map((n) {
        if (n['id'] == id) return {...n, 'read_at': now};
        return n;
      }).toList();
    });

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _markAllRead() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final contexto = context.read<CurrentContextNotifier>().current;
    final consorcioId = (contexto?.consorcioId ?? '').trim();
    final unidadId = (contexto?.unidadId ?? '').trim();
    final isAdmin = contexto?.rol == 'ADMIN_CONSORCIO';
    final now = DateTime.now().toUtc().toIso8601String();

    var q = supabase
        .from('notificaciones')
        .update({'read_at': now})
        .filter('read_at', 'is', null)
        .eq('usuario_id', userId);
    final effectiveShowAll = _showAll && isAdmin;
    if (!effectiveShowAll) {
      if (consorcioId.isNotEmpty) {
        q = q.eq('consorcio_id', consorcioId);
      }
      if (unidadId.isNotEmpty) {
        q = q.eq('unidad_id', unidadId);
      }
    }
    await q;

    setState(() {
      _items = _items
          .map((n) => n['read_at'] == null ? {...n, 'read_at': now} : n)
          .toList();
    });

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contexto = context.watch<CurrentContextNotifier>().current;
    final isAdmin = contexto?.rol == 'ADMIN_CONSORCIO';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsInboxTitle),
        actions: [
          if (isAdmin)
            _HelpListener(
              helpEnabled: _helpEnabled,
              helpText: _showAll
                  ? l10n.helpInboxToggleAllOn
                  : l10n.helpInboxToggleAllOff,
              child: IconButton(
                tooltip: _showAll
                    ? l10n.helpInboxShowContextTooltip
                    : l10n.helpInboxShowAllTooltip,
                icon: Icon(
                  _showAll ? Icons.filter_alt_off : Icons.filter_alt,
                ),
                onPressed: _toggleInboxScope,
              ),
            ),
          _HelpListener(
            helpEnabled: _helpEnabled,
            helpText: l10n.helpInboxMarkAllRead,
            child: IconButton(
              tooltip: l10n.notificationsMarkAllRead,
              icon: const Icon(Icons.done_all),
              onPressed: _items.any((n) => n['read_at'] == null)
                  ? _markAllRead
                  : null,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ),
                ],
              )
            : _items.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.notificationsEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = _items[i];
                  final title = (n['title'] ?? '').toString();
                  final body = (n['body'] ?? '').toString();
                  final readAt = n['read_at'];
                  final isUnread = readAt == null;
                  final isHighlighted =
                      _highlightId != null &&
                      _highlightId == n['id']?.toString();

                  return _HelpableTile(
                    helpEnabled: _helpEnabled,
                    helpText: isUnread
                        ? l10n.helpInboxMarkAsRead
                        : l10n.helpInboxAlreadyRead,
                    onTap: isUnread
                        ? () async {
                            await _markAsRead(n['id'].toString());
                          }
                        : null,
                    child: ListTile(
                      tileColor: isHighlighted
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08)
                          : null,
                      leading: Icon(
                        isUnread
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                      ),
                      title: Text(
                        title.isEmpty ? '(Sin t\u00edtulo)' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isUnread
                          ? const Icon(Icons.circle, size: 10)
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _HelpListener extends StatefulWidget {
  final bool helpEnabled;
  final String helpText;
  final Widget child;

  const _HelpListener({
    required this.helpEnabled,
    required this.helpText,
    required this.child,
  });

  @override
  State<_HelpListener> createState() => _HelpListenerState();
}

class _HelpListenerState extends State<_HelpListener> {
  Timer? _timer;

  void _startTimer() {
    if (!widget.helpEnabled || widget.helpText.trim().isEmpty) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(widget.helpText)),
      );
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _startTimer(),
      onPointerUp: (_) => _cancelTimer(),
      onPointerCancel: (_) => _cancelTimer(),
      child: widget.child,
    );
  }
}

class _HelpableTile extends StatefulWidget {
  final bool helpEnabled;
  final String helpText;
  final Widget child;
  final Future<void> Function()? onTap;

  const _HelpableTile({
    required this.helpEnabled,
    required this.helpText,
    required this.child,
    this.onTap,
  });

  @override
  State<_HelpableTile> createState() => _HelpableTileState();
}

class _HelpableTileState extends State<_HelpableTile> {
  Timer? _timer;
  bool _helpShown = false;

  void _startTimer() {
    if (!widget.helpEnabled || widget.helpText.trim().isEmpty) return;
    _timer?.cancel();
    _helpShown = false;
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _helpShown = true;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(widget.helpText)),
      );
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleTap() async {
    _cancelTimer();
    if (_helpShown) {
      _helpShown = false;
      return;
    }
    await widget.onTap?.call();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: (_) => _startTimer(),
        onTapCancel: _cancelTimer,
        onTap: widget.onTap == null ? null : _handleTap,
        child: widget.child,
      ),
    );
  }
}
