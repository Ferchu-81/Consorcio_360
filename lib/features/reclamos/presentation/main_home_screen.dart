import 'package:consorcio_360/core/services/context_storage.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/auth/presentation/login_screen.dart';
import 'package:consorcio_360/features/context/presentation/context_selection_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_tab.dart';
import 'package:consorcio_360/features/home/presentation/dashboard_tab.dart';
import 'package:consorcio_360/features/pagos/presentation/pagos_tab.dart';
import 'package:consorcio_360/features/reclamos/presentation/consorcio_reclamos_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamos_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Home principal con tabs: Inicio / Reclamos / Expensas / Pagos.
class MainHomeScreen extends StatefulWidget {
  final UsuarioContexto contexto;

  const MainHomeScreen({super.key, required this.contexto});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  String _displayName(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Usuario';
    if (value.contains('@')) return 'Usuario';
    return value;
  }

  @override
  void initState() {
    super.initState();
    // Asegura que el notifier tenga el contexto actual.
    context.read<CurrentContextNotifier>().setContext(widget.contexto);

    final nombre = _displayName(widget.contexto.nombre);
    final rolDesc = widget.contexto.rolDescripcion;

    _tabs = [
      DashboardTab(nombre: nombre, rolDescripcion: rolDesc),
      const ReclamosTab(),
      const ExpensasTab(),
      const PagosTab(),
    ];
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await ContextStorage.limpiarContexto();
    if (!mounted) return;
    context.read<CurrentContextNotifier>().clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout =
        await showDialog<bool>(
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
    await ContextStorage.limpiarContexto();
    if (!mounted) return;
    context.read<CurrentContextNotifier>().clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ContextSelectionScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmChangeContext() async {
    final shouldChange =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambiar de rol / unidad'),
            content: const Text(
              '¿Querés cambiar de consorcio, unidad o rol?\n'
              'Se cerrará el contexto actual.',
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

  @override
  Widget build(BuildContext context) {
    final ctx = widget.contexto;
    final esAdmin = ctx.rol == 'ADMIN_CONSORCIO';

    // Si es admin y está en Reclamos, mostramos tablero general, si no la vista normal.
    final reclamosTab = esAdmin
        ? const ConsorcioReclamosScreen()
        : const ReclamosTab();

    final tabs = [_tabs[0], reclamosTab, _tabs[2], _tabs[3]];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ctx.consorcioNombre} - Unidad ${ctx.unidadCodigo}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(ctx.rolLegible, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar contexto',
            icon: const Icon(Icons.swap_horiz),
            onPressed: _confirmChangeContext,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF5F9F1),
        selectedItemColor: Colors.black54,
        unselectedItemColor: Colors.black87,
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
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
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Pagos',
          ),
        ],
      ),
    );
  }
}
