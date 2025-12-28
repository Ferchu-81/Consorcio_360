import 'package:consorcio_360/bases_legales/ui/bases_legales_screen.dart';
import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/features/settings/presentation/consorcio_reglas_screen.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_preferences_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<CurrentContextNotifier>().current;

    if (ctx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuraci\u00f3n')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay un contexto seleccionado.\n\n'
              'Volv\u00e9 atr\u00e1s y eleg\u00ed Consorcio / Unidad / Rol.',
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
        title: const Text('Configuraci\u00f3n'),
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
            subtitle: const Text('Nombre, tel\u00e9fono, datos fiscales'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones'),
            subtitle: const Text('Preferencias'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationPreferencesScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Documentaci\u00f3n'),
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
                  const Text('mis declarados, tipo, ubicaci\u00f3n (pendiente)'),
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
              title: const Text('Configuraci\u00f3n del consorcio'),
              subtitle:
                  const Text('Tipo, ubicaci\u00f3n, UF, facturaci\u00f3n (pendiente)'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Pendiente: Configuraci\u00f3n global del consorcio'),
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
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context).settingsAppVersion),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('...');
                final p = snapshot.data!;
                return Text('${p.version} (${p.buildNumber})');
              },
            ),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Sesi\u00f3n'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesi\u00f3n'),
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
              '$consorcio - Unidad $unidad\nRol: $rol',
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




