import 'package:flutter/material.dart';

/// Pantalla placeholder para Expensas / Pagos (en desarrollo)
class PlaceholderFeatureScreen extends StatelessWidget {
  final String titulo;

  const PlaceholderFeatureScreen({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(titulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Esta seccion aun no esta disponible en esta version.\n'
              'Forma parte del alcance futuro del proyecto.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
