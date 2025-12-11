import 'package:flutter/material.dart';

import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/home/presentation/dashboard_tab.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamos_tab.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_tab.dart';
import 'package:consorcio_360/features/pagos/presentation/pagos_tab.dart';

class MainHomeScreen extends StatefulWidget {
  final UsuarioContexto contexto;

  const MainHomeScreen({
    super.key,
    required this.contexto,
  });

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    // Buscamos primero nombre/apellido; si no hay, usamos un fallback.
    final rawNombre = widget.contexto.nombre?.trim();
    final nombre = (rawNombre != null &&
            rawNombre.isNotEmpty &&
            !rawNombre.contains('@'))
        ? rawNombre
        : 'Usuario';

    final rolDescripcion = widget.contexto.rolDescripcion;

    _tabs = [
      DashboardTab(
        nombre: nombre,
        rolDescripcion: rolDescripcion,
      ),
      ReclamosTab(
        contexto: widget.contexto,
      ),
      ExpensasTab(
        contexto: widget.contexto,
      ),
      PagosTab(
        contexto: widget.contexto,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Este AppBar es el que ya tenias con consorcio / unidad / rol
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contexto.consorcioNombre),
            Text(
              'Unidad ${widget.contexto.unidadCodigo}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        // si tenias acciones (cambiar contexto, etc.), las podes volver a agregar aca
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.black,
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
