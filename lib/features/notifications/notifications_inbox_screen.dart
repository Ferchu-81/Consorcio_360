import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
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

      debugPrint('NOTIFS _load: userId=$userId');

      final data = await supabase
          .from('notificaciones')
          .select(
            'id, title, body, created_at, read_at, event_type, data, consorcio_id, unidad_id',
          )
          .eq('usuario_id', userId)
          .order('created_at', ascending: false)
          .limit(80);

      setState(() {
        _items = List<Map<String, dynamic>>.from(data);
      });
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
      _items =
          _items.map((n) {
            if (n['id'] == id) return {...n, 'read_at': now};
            return n;
          }).toList();
    });
  }

  Future<void> _markAllRead() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final contexto = context.read<CurrentContextNotifier>().current;
    final consorcioId = (contexto?.consorcioId ?? '').trim();
    final now = DateTime.now().toUtc().toIso8601String();

    var q = supabase
        .from('notificaciones')
        .update({'read_at': now})
        .filter('read_at', 'is', null)
        .eq('usuario_id', userId);
    if (consorcioId.isNotEmpty) {
      q = q.eq('consorcio_id', consorcioId);
    }
    await q;

    setState(() {
      _items =
          _items
              .map(
                (n) => n['read_at'] == null ? {...n, 'read_at': now} : n,
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsInboxTitle),
        actions: [
          IconButton(
            tooltip: l10n.notificationsMarkAllRead,
            icon: const Icon(Icons.done_all),
            onPressed: _items.any((n) => n['read_at'] == null)
                ? _markAllRead
                : null,
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
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          final title = (n['title'] ?? '').toString();
                          final body = (n['body'] ?? '').toString();
                          final readAt = n['read_at'];
                          final isUnread = readAt == null;

                          return ListTile(
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
                            onTap: () async {
                              if (isUnread) {
                                await _markAsRead(n['id'].toString());
                              }
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
