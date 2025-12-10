import 'package:flutter/material.dart';

/// Ajustá estos dos String según tu modelo de contexto.
class DashboardTab extends StatelessWidget {
  final String nombre;
  final String rolDescripcion;

  const DashboardTab({
    super.key,
    required this.nombre,
    required this.rolDescripcion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $nombre',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rolDescripcion,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Resumen rápido (en construcción):\n'
                '• Expensas pendientes / vencidas\n'
                '• Últimos reclamos\n'
                '• Avisos del administrador',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
