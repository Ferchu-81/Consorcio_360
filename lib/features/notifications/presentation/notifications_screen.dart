import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensa_detail_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamo_detail_screen.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final ExpensasRepository _expensasRepository = ExpensasRepository();
  late Future<List<_NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadNotifications();
  }

  Future<List<_NotificationItem>> _loadNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('notificaciones')
        .select('id, title, body, created_at, read_at, deep_link')
        .eq('usuario_id', user.id)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(_NotificationItem.fromMap).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadNotifications();
    });
    await _future;
  }

  Future<void> _handleTap(_NotificationItem item) async {
    if (item.id.isEmpty) return;

    if (item.readAt == null) {
      await _markAsRead(item.id);
    }

    if (!mounted) return;

    await _navigateDeepLink(item.deepLink);

    if (!mounted) return;
    setState(() {
      _future = _loadNotifications();
    });
  }

  Future<void> _markAsRead(String id) async {
    await _client
        .from('notificaciones')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> _navigateDeepLink(String? deepLink) async {
    final l10n = AppLocalizations.of(context);

    if (deepLink == null || deepLink.trim().isEmpty) {
      _showSnack(l10n.notificationsNoDestination);
      return;
    }

    final parsed = _parseDeepLink(deepLink);
    final tipo = parsed.type.toLowerCase();

    if (tipo == 'reclamo') {
      if (!parsed.hasId) {
        _showSnack(l10n.notificationsMissingReclamoId);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReclamoDetailScreen(reclamoId: parsed.id!),
        ),
      );
      return;
    }

    if (tipo == 'expensa') {
      if (!parsed.hasId) {
        _showSnack(l10n.notificationsMissingExpensaId);
        return;
      }
      final expensa = await _expensasRepository.fetchExpensaPorId(parsed.id!);
      if (expensa == null) {
        _showSnack(l10n.notificationsExpensaNotFound);
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ExpensaDetailScreen(expensa: expensa)),
      );
      return;
    }

    if (tipo == 'reserva') {
      _showSnack(l10n.notificationsReservaUnavailable);
      return;
    }

    _showSnack(l10n.notificationsNoDestination);
  }

  _ParsedLink _parseDeepLink(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      if (uri.scheme.isNotEmpty && uri.host.isNotEmpty) {
        return _ParsedLink(uri.scheme, uri.host);
      }
      if (uri.scheme.isNotEmpty && uri.path.isNotEmpty) {
        return _ParsedLink(uri.scheme, uri.pathSegments.first);
      }
      if (uri.pathSegments.isNotEmpty) {
        final id = uri.pathSegments.length > 1
            ? uri.pathSegments[1]
            : uri.queryParameters['id'];
        return _ParsedLink(uri.pathSegments.first, id);
      }
    }

    final parts = trimmed.split(RegExp('[:/]'));
    if (parts.length >= 2) {
      return _ParsedLink(parts.first, parts[1]);
    }

    return _ParsedLink(trimmed, null);
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return '';
    final now = DateTime.now();
    if (value.year == now.year &&
        value.month == now.month &&
        value.day == now.day) {
      final hh = value.hour.toString().padLeft(2, '0');
      final mm = value.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8EE),
        elevation: 0,
        title: Text(l10n.notificationsTitle),
      ),
      body: FutureBuilder<List<_NotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.notificationsLoadError,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.notificationsRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n.notificationsEmpty,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final isUnread = item.readAt == null;
                final titleStyle = theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                );
                final timestampStyle = theme.textTheme.bodySmall?.copyWith(
                  color: isUnread ? Colors.green : Colors.grey,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                );

                return InkWell(
                  onTap: () => _handleTap(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isUnread ? Colors.green : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: titleStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimestamp(item.createdAt),
                                    style: timestampStyle,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String? deepLink;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.readAt,
    required this.deepLink,
  });

  bool get isUnread => readAt == null;

  factory _NotificationItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    final rawTitle = map['title'] ?? map['titulo'];
    final rawBody = map['body'] ?? map['cuerpo'] ?? map['mensaje'];
    final rawDeepLink = map['deep_link'] ?? map['deepLink'] ?? map['link'];

    return _NotificationItem(
      id: map['id']?.toString() ?? '',
      title: rawTitle?.toString() ?? '',
      body: rawBody?.toString() ?? '',
      createdAt: parseDate(map['created_at']),
      readAt: parseDate(map['read_at']),
      deepLink: rawDeepLink?.toString(),
    );
  }
}

class _ParsedLink {
  final String type;
  final String? id;

  const _ParsedLink(this.type, this.id);

  bool get hasId => id != null && id!.isNotEmpty;
}
