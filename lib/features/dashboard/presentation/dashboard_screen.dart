import 'package:consorcio_360/core/services/context_storage.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/context/presentation/context_selection_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/main_home_screen.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final UsuarioContexto contexto;

  const DashboardScreen({super.key, required this.contexto});

  Future<void> _cambiarContexto(BuildContext context) async {
    await ContextStorage.limpiarContexto();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const ContextSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawNombre = contexto.nombre?.trim();
    final nombre = (rawNombre != null &&
            rawNombre.isNotEmpty &&
            !rawNombre.contains('@'))
        ? rawNombre
        : 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: Text('Consorcio 360 - ${contexto.consorcioNombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar contexto',
            onPressed: () => _cambiarContexto(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hola, $nombre',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${contexto.rolLegible} · Unidad ${contexto.unidadCodigo} - ${contexto.consorcioNombre}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximos pasos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Accedé a tus expensas, reclamos y pagos desde el home.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MainHomeScreen(contexto: contexto),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard_customize),
                    label: const Text('Ir al home'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}
