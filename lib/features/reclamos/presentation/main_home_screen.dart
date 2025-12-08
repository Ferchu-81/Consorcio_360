import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/features/auth/presentation/login_screen.dart';
import 'package:consorcio_360/features/context/presentation/context_selection_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_tab.dart';
import 'package:consorcio_360/features/pagos/presentation/pagos_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'consorcio_reclamos_screen.dart';
import 'reclamos_tab.dart';

/// Home principal, con tabs Reclamos / Expensas / Pagos.
/// Si el rol actual es ADMIN_CONSORCIO, agrega acceso a "Reclamos del consorcio".
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _tituloSeccion() {
    switch (_selectedIndex) {
      case 0:
        return 'Reclamos';
      case 1:
        return 'Expensas';
      case 2:
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
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar sesion'),
            content: const Text(
              'Queres cerrar la sesion actual?\n'
              'Vas a tener que ingresar de nuevo para continuar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar sesion'),
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
    final shouldChange =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambiar de rol / unidad'),
            content: const Text(
              'Queres cambiar de consorcio, unidad o rol?\n'
              'Se cerrara el contexto actual.',
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
    final current = context.watch<CurrentContextNotifier>();
    final contexto = current.current;

    if (contexto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consorcio 360')),
        body: const Center(
          child: Text(
            'No hay contexto seleccionado. Volve a la pantalla anterior.',
          ),
        ),
      );
    }

    final bool esAdmin = contexto.rol == 'ADMIN_CONSORCIO';

    final Widget body;
    if (_selectedIndex == 0) {
      body = esAdmin
          ? const ConsorcioReclamosScreen()
          : const ReclamosTab(); // Reclamos (admin ve tablero general)
    } else if (_selectedIndex == 1) {
      body = const ExpensasTab();
    } else {
      body = const PagosTab();
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
            Text(tituloSeccion, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ActionChip(
              label: Text(contexto.rolLegible),
              avatar: const Icon(Icons.person_outline, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: _confirmChangeContext,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
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
