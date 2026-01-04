import 'dart:async';

import 'package:consorcio_360/core/services/context_storage.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/auth/presentation/login_screen.dart';
import 'package:consorcio_360/features/context/presentation/context_selection_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_tab.dart';
import 'package:consorcio_360/features/home/presentation/dashboard_tab.dart';
import 'package:consorcio_360/features/notifications/notifications_inbox_screen.dart';
import 'package:consorcio_360/features/pagos/presentation/pagos_tab.dart';
import 'package:consorcio_360/features/settings/presentation/settings_screen.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:consorcio_360/core/services/push_token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'consorcio_reclamos_screen.dart';
import 'reclamos_tab.dart';

/// Home principal, con tabs:
/// Inicio (dashboard) / Reclamos / Expensas / Pagos.
/// Si el rol actual es ADMIN_CONSORCIO, el tab de Reclamos
/// muestra el tablero general del consorcio.
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  static const String _prefHelpEnabledKey = 'ui_help_enabled';
  static bool _pushHandlersRegistered = false;

  int _selectedIndex = 0;
  int _unreadCount = 0;
  bool _loadingUnread = false;
  bool _helpEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHelpEnabled();
    _loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await PushTokenService.instance.ensureInitializedAndSync();
      } catch (_) {
        // si falla el push, NO debe romper la app
      }
      _setupPushOpenHandlers();
    });
  }

  Future<void> _loadHelpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefHelpEnabledKey);
    if (!mounted || value == null) return;
    setState(() => _helpEnabled = value);
  }

  void _setupPushOpenHandlers() {
    if (_pushHandlersRegistered) return;
    _pushHandlersRegistered = true;

    try {
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationOpen(message.data);
      });

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleNotificationOpen(message.data);
        }
      });
    } catch (e) {
      debugPrint('Push open handlers error: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _tituloSeccion() {
    switch (_selectedIndex) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Reclamos';
      case 2:
        return 'Expensas';
      case 3:
        return 'Pagos';
      default:
        return 'Consorcio 360';
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;

    context.read<CurrentContextNotifier>().clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text(
              '¿Querés cerrar la sesión actual?\n'
              'Vas a tener que ingresar de nuevo para continuar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;
    await _logout();
  }

  Future<void> _changeContext() async {
    context.read<CurrentContextNotifier>().clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ContextSelectionScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmChangeContext() async {
    final shouldChange = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambiar de rol / unidad'),
            content: const Text(
              '¿Querés cambiar de consorcio, unidad o rol?\n'
              'Se cerrará el contexto actual.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cambiar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldChange) return;
    await _changeContext();
  }

  Future<void> _openNotifications() async {
    await _openNotificationsWithSelection();
  }

  Future<void> _openNotificationsWithSelection({
    String? notificationId,
  }) async {
    final trimmedId = notificationId?.trim();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NotificationsInboxScreen(
          notificationId:
              trimmedId == null || trimmedId.isEmpty ? null : trimmedId,
        ),
      ),
    );
    if (!mounted) return;
    await _loadUnreadCount();
  }

  Future<void> _handleNotificationOpen(Map<String, dynamic> data) async {
    final payload = data.map(
      (k, v) => MapEntry(k, v == null ? '' : v.toString()),
    );

    final consorcioId = (payload['consorcio_id'] ?? '').trim();
    final unidadId = (payload['unidad_id'] ?? '').trim();
    final notificationId = (payload['notification_id'] ?? '').trim();

    if (consorcioId.isNotEmpty) {
      await _ensureContextForNotification(
        consorcioId: consorcioId,
        unidadId: unidadId.isEmpty ? null : unidadId,
      );
    }

    if (!mounted) return;
    await _openNotificationsWithSelection(
      notificationId: notificationId.isEmpty ? null : notificationId,
    );
  }

  Future<void> _ensureContextForNotification({
    required String consorcioId,
    String? unidadId,
  }) async {
    final notifier = context.read<CurrentContextNotifier>();
    final current = notifier.current;
    if (current != null &&
        current.consorcioId == consorcioId &&
        (unidadId == null || unidadId.isEmpty || current.unidadId == unidadId)) {
      return;
    }

    final ctx = await _findContext(consorcioId, unidadId);
    if (ctx == null) {
      debugPrint(
        'Push open: no access to context consorcio=$consorcioId unidad=$unidadId',
      );
      return;
    }

    if (!mounted) return;
    notifier.setContext(ctx);
    await ContextStorage.guardarContexto(ctx);
  }

  Future<UsuarioContexto?> _findContext(
    String consorcioId,
    String? unidadId,
  ) async {
    final contexts = await _loadUserContexts();
    if (unidadId != null && unidadId.isNotEmpty) {
      for (final ctx in contexts) {
        if (ctx.consorcioId != consorcioId) continue;
        if (ctx.unidadId != unidadId) continue;
        return ctx;
      }
      return null;
    }

    for (final ctx in contexts) {
      if (ctx.consorcioId != consorcioId) continue;
      if (ctx.rol != 'ADMIN_CONSORCIO') continue;
      return ctx;
    }
    debugPrint(
      'Push open: no admin context for consorcio=$consorcioId',
    );
    return null;
  }

  Future<List<UsuarioContexto>> _loadUserContexts() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('usuarios_unidades')
        .select('''
        id,
        rol,
        es_titular,
        ocupa,
        es_inquilino,
        activo,
        unidades (
          id,
          codigo,
          consorcio_id,
          consorcios (
            id,
            nombre
          )
        ),
        usuarios (
          nombre,
          apellido,
          email
        )
      ''')
        .eq('usuario_id', user.id);

    if (response.isEmpty) return [];

    final data = response as List<dynamic>;

    return data.map<UsuarioContexto>((row) {
      final unidad = row['unidades'] as Map<String, dynamic>;
      final consorcio = unidad['consorcios'] as Map<String, dynamic>;
      final usuario = row['usuarios'] as Map<String, dynamic>;

      final nombre = (usuario['nombre'] as String?)?.trim() ?? '';
      final apellido = (usuario['apellido'] as String?)?.trim() ?? '';
      final email = (usuario['email'] as String?) ?? '';

      final nombreCompleto = [
        if (nombre.isNotEmpty) nombre,
        if (apellido.isNotEmpty) apellido,
      ].join(' ').trim();

      return UsuarioContexto(
        usuarioUnidadId: row['id'] as String,
        consorcioId: unidad['consorcio_id'] as String,
        consorcioNombre: consorcio['nombre'] as String,
        unidadId: unidad['id'] as String,
        unidadCodigo: unidad['codigo'] as String,
        nombre: nombreCompleto.isNotEmpty ? nombreCompleto : email,
        rol: row['rol'] as String,
        esTitular: row['es_titular'] as bool? ?? false,
        ocupa: row['ocupa'] as bool? ?? false,
        esInquilino: row['es_inquilino'] as bool? ?? true,
        activo: row['activo'] as bool? ?? true,
      );
    }).toList();
  }

  Future<void> _loadUnreadCount() async {
    if (_loadingUnread) return;
    setState(() {
      _loadingUnread = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? '';
      if (userId.isEmpty) return;

      final ctx = context.read<CurrentContextNotifier>().current;
      final consorcioId = (ctx?.consorcioId ?? '').trim();
      final unidadId = (ctx?.unidadId ?? '').trim();

      var q = supabase
          .from('notificaciones')
          .count()
          .eq('usuario_id', userId)
          .filter('read_at', 'is', null);

      if (consorcioId.isNotEmpty) {
        q = q.eq('consorcio_id', consorcioId);
      }

      if (unidadId.isNotEmpty) {
        q = q.eq('unidad_id', unidadId);
      }

      final count = await q;

      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (e) {
      debugPrint('Unread count error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingUnread = false;
        });
      }
    }
  }

  Widget _buildNotificationsAction() {
    final count = _unreadCount;
    final label = count > 99 ? '99+' : '$count';
    final l10n = AppLocalizations.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: l10n.notificationsTitle,
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _openNotifications,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<CurrentContextNotifier>();
    final contexto = current.current;

    if (contexto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consorcio 360')),
        body: const Center(
          child: Text(
            'No hay contexto seleccionado.\n'
            'Volvé a la pantalla anterior.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final bool esAdmin = contexto.rol == 'ADMIN_CONSORCIO';

    // Selección de tab
    late final Widget body;
    if (_selectedIndex == 0) {
      body = DashboardTab(contexto: contexto);
    } else if (_selectedIndex == 1) {
      body = esAdmin ? ConsorcioReclamosScreen() : ReclamosTab();
    } else if (_selectedIndex == 2) {
      body = ExpensasTab(contexto: contexto);
    } else {
      body = PagosTab(contexto: contexto);
    }

    final tituloSeccion = _tituloSeccion();
    final headerTop = esAdmin
        ? '${contexto.consorcioNombre} - ${roleLabel(context, contexto.rol)}'
        : '${contexto.consorcioNombre} - Unidad ${contexto.unidadCodigo}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8EE),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerTop,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              tituloSeccion,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          _HelpListener(
            helpEnabled: _helpEnabled,
            helpText: 'Ver notificaciones y avisos.',
            child: _buildNotificationsAction(),
          ),
          _HelpListener(
            helpEnabled: _helpEnabled,
            helpText: 'Abrir configuraci\u00f3n de la app.',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _HelpListener(
              helpEnabled: _helpEnabled,
              helpText: 'Cambiar consorcio, unidad o rol.',
              child: ActionChip(
                label: Text(roleLabel(context, contexto.rol)),
                avatar: const Icon(Icons.person_outline, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: _confirmChangeContext,
              ),
            ),
          ),
          _HelpListener(
            helpEnabled: _helpEnabled,
            helpText: 'Cerrar sesi\u00f3n.',
            child: IconButton(
              tooltip: 'Cerrar sesi\u00f3n',
              icon: const Icon(Icons.logout),
              onPressed: _confirmLogout,
            ),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFF4F8EE),
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.black54,
        unselectedItemColor: Colors.black87,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_repair_service_outlined),
            label: 'Reclamos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Expensas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Pagos',
          ),
        ],
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



