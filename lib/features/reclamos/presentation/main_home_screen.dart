import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/features/auth/presentation/login_screen.dart';
import 'package:consorcio_360/features/context/presentation/context_selection_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_tab.dart';
import 'package:consorcio_360/features/home/presentation/dashboard_tab.dart';
import 'package:consorcio_360/features/notifications/notifications_inbox_screen.dart';
import 'package:consorcio_360/features/pagos/presentation/pagos_tab.dart';
import 'package:consorcio_360/features/settings/presentation/settings_screen.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:consorcio_360/core/services/push_token_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int _selectedIndex = 0;
  int _unreadCount = 0;
  bool _loadingUnread = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await PushTokenService.instance.ensureInitializedAndSync();
      } catch (_) {
        // si falla el push, NO debe romper la app
      }
    });
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
    );
    if (!mounted) return;
    await _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_loadingUnread) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
      return;
    }

    setState(() {
      _loadingUnread = true;
    });

    try {
      final unread = await Supabase.instance.client
          .from('notificaciones')
          .count()
          .eq('usuario_id', user.id)
          .isFilter('read_at', null);

      if (mounted) {
        setState(() {
          _unreadCount = unread;
        });
      }
    } catch (_) {
      // Mantener el ultimo conteo en caso de error.
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
              '${contexto.consorcioNombre} - Unidad ${contexto.unidadCodigo}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              tituloSeccion,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          _buildNotificationsAction(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ActionChip(
              label: Text(roleLabel(context, contexto.rol)),
              avatar: const Icon(Icons.person_outline, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: _confirmChangeContext,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
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



