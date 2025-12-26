import 'package:consorcio_360/bases_legales/ui/bases_legales_screen.dart';
import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/features/settings/presentation/consorcio_reglas_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_settings_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<CurrentContextNotifier>().current;

    if (ctx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay un contexto seleccionado.\n\n'
              'Volvé atrás y elegí Consorcio / Unidad / Rol.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isAdmin = ctx.rol == 'ADMIN_CONSORCIO';
    final isPropietario = ctx.rol == 'PROPIETARIO';
    final isMorador = ctx.rol == 'MORADOR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContextHeader(
            consorcio: ctx.consorcioNombre,
            unidad: ctx.unidadCodigo,
            rol: roleLabel(context, ctx.rol),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Cuenta'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi perfil'),
            subtitle: const Text('Nombre, teléfono, datos fiscales'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones'),
            subtitle: const Text('Preferencias por rol/contexto'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Documentación'),
          ListTile(
            leading: const Icon(Icons.library_books_outlined),
            title: const Text('Bases legales'),
            subtitle: const Text('Reglamentos, PDFs y normativa'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BasesLegalesScreen(
                  consorcioId: ctx.consorcioId,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Unidad'),
          if (isPropietario || isMorador || isAdmin)
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Datos de mi unidad'),
              subtitle:
                  const Text('m² declarados, tipo, ubicación (pendiente)'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pendiente: pantalla Datos de Unidad'),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          const _SectionTitle('Consorcio'),
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.rule_folder_outlined),
              title: const Text('Reglas del consorcio'),
              subtitle: const Text('Voto, amenities, propietario no ocupante'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ConsorcioReglasScreen(consorcioId: ctx.consorcioId),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.apartment_outlined),
              title: const Text('Configuración del consorcio'),
              subtitle:
                  const Text('Tipo, ubicación, UF, facturación (pendiente)'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Pendiente: Configuración global del consorcio'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pool_outlined),
              title: const Text('Amenities y reservas'),
              subtitle: const Text(
                'Crear amenities, reglas, horarios, tarifas (pendiente)',
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pendiente: Admin de amenities y reservas'),
                  ),
                );
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Reservas'),
              subtitle: const Text('Ver y reservar amenities (pendiente)'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Pendiente: reservas de amenities para usuarios'),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          const _SectionTitle('Sesión'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ContextHeader extends StatelessWidget {
  final String consorcio;
  final String unidad;
  final String rol;

  const _ContextHeader({
    required this.consorcio,
    required this.unidad,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$consorcio · Unidad $unidad\nRol: $rol',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}




