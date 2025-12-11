import 'package:flutter/material.dart';

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
                'Resumen r\u00e1pido (en construcci\u00f3n):\n'
                '\u2022 Expensas pendientes / vencidas\n'
                '\u2022 \u00daltimos reclamos\n'
                '\u2022 Avisos del administrador',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
