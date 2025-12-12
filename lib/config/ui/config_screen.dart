import 'package:flutter/material.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Configuración del consorcio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'En esta sección, el administrador va a poder definir:\n'
              '• Datos de cobro (cuenta de Mercado Pago u otros medios).\n'
              '• Parámetros generales de expensas y avisos.\n'
              '• Otras opciones avanzadas de administración.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Cuenta de cobro de expensas'),
              subtitle: const Text(
                'Funcionalidad en desarrollo. Hoy se usa una cuenta de prueba '
                'de Mercado Pago para validar la integración.',
              ),
              onTap: () {},
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings_suggest_outlined),
              title: const Text('Otras configuraciones'),
              subtitle: const Text(
                'Esta sección se ampliará en futuras versiones de la app.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
