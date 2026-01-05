import 'dart:async';

import 'package:consorcio_360/bases_legales/ui/bases_legales_screen.dart';
import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/features/settings/presentation/consorcio_reglas_screen.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_preferences_screen.dart';
import 'profile_screen.dart';

const String _gitBranch = String.fromEnvironment('GIT_BRANCH');
const String _gitSha = String.fromEnvironment('GIT_SHA');
const String _prefHelpEnabledKey = 'ui_help_enabled';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _helpEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHelpEnabled();
  }

  Future<void> _loadHelpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefHelpEnabledKey);
    if (!mounted || value == null) return;
    setState(() => _helpEnabled = value);
  }

  Future<void> _setHelpEnabled(bool value) async {
    setState(() => _helpEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefHelpEnabledKey, value);
  }

  Widget _buildHelpInfoCard() {
    final l10n = AppLocalizations.of(context);
    final label =
        _helpEnabled ? l10n.helpContextualDisable : l10n.helpContextualEnable;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.helpContextualTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(l10n.helpContextualDescription),
          TextButton(
            onPressed: () => _setHelpEnabled(!_helpEnabled),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<CurrentContextNotifier>().current;
    final l10n = AppLocalizations.of(context);

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
          const SizedBox(height: 12),
          _buildHelpInfoCard(),
          const SizedBox(height: 12),
          _SectionTitle(l10n.helpSectionTitle),
          SwitchListTile(
            value: _helpEnabled,
            onChanged: _setHelpEnabled,
            title: Text(l10n.helpContextualTitle),
            subtitle: Text(l10n.helpContextualSwitchSubtitle),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Cuenta'),
          _HelpableTile(
            helpEnabled: _helpEnabled,
            helpText: l10n.helpSettingsProfile,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Mi perfil'),
              subtitle: Text('Nombre, tel\u00e9fono, datos fiscales'),
            ),
          ),
          _HelpableTile(
            helpEnabled: _helpEnabled,
            helpText: l10n.helpSettingsNotifications,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationPreferencesScreen(),
              ),
            ),
            child: const ListTile(
              leading: Icon(Icons.notifications_outlined),
              title: Text('Notificaciones'),
              subtitle: Text('Preferencias'),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Documentaci\u00f3n'),
          _HelpableTile(
            helpEnabled: _helpEnabled,
            helpText: l10n.helpSettingsBasesLegales,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BasesLegalesScreen(
                  consorcioId: ctx.consorcioId,
                ),
              ),
            ),
            child: const ListTile(
              leading: Icon(Icons.library_books_outlined),
              title: Text('Bases legales'),
              subtitle: Text('Reglamentos, PDFs y normativa'),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Unidad'),
          if (isPropietario || isMorador || isAdmin)
            _HelpableTile(
              helpEnabled: _helpEnabled,
              helpText: l10n.helpSettingsUnidad,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pendiente: pantalla Datos de Unidad'),
                  ),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.home_outlined),
                title: Text('Datos de mi unidad'),
                subtitle:
                    Text('mis declarados, tipo, ubicaci\u00f3n (pendiente)'),
              ),
            ),
          const SizedBox(height: 12),
          const _SectionTitle('Consorcio'),
          if (isAdmin) ...[
            _HelpableTile(
              helpEnabled: _helpEnabled,
              helpText: l10n.helpSettingsReglasConsorcio,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ConsorcioReglasScreen(consorcioId: ctx.consorcioId),
                ),
              ),
              child: const ListTile(
                leading: Icon(Icons.rule_folder_outlined),
                title: Text('Reglas del consorcio'),
                subtitle: Text('Voto, amenities, propietario no ocupante'),
              ),
            ),
            _HelpableTile(
              helpEnabled: _helpEnabled,
              helpText: l10n.helpSettingsConsorcioConfig,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Pendiente: Configuraci\u00f3n global del consorcio'),
                  ),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.apartment_outlined),
                title: Text('Configuraci\u00f3n del consorcio'),
                subtitle: Text(
                  'Tipo, ubicaci\u00f3n, UF, facturaci\u00f3n (pendiente)',
                ),
              ),
            ),
            _HelpableTile(
              helpEnabled: _helpEnabled,
              helpText: l10n.helpSettingsAmenitiesAdmin,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pendiente: Admin de amenities y reservas'),
                  ),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.pool_outlined),
                title: Text('Amenities y reservas'),
                subtitle: Text(
                  'Crear amenities, reglas, horarios, tarifas (pendiente)',
                ),
              ),
            ),
          ] else ...[
            _HelpableTile(
              helpEnabled: _helpEnabled,
              helpText: l10n.helpSettingsAmenitiesUser,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Pendiente: reservas de amenities para usuarios'),
                  ),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.event_available_outlined),
                title: Text('Reservas'),
                subtitle: Text('Ver y reservar amenities (pendiente)'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _HelpableTile(
            helpEnabled: _helpEnabled,
            helpText: l10n.helpSettingsAppVersion,
            onTap: () {},
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(AppLocalizations.of(context).settingsAppVersion),
              subtitle: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('...');
                  final p = snapshot.data!;
                  final versionLabel = 'v${p.version} (build ${p.buildNumber})';
                  final extras = <String>[];
                  if (_gitBranch.isNotEmpty) {
                    extras.add('branch $_gitBranch');
                  }
                  if (_gitSha.isNotEmpty) {
                    extras.add('commit $_gitSha');
                  }
                  final label = extras.isEmpty
                      ? versionLabel
                      : '$versionLabel | ${extras.join(' | ')}';
                  return Text(label);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Sesi\u00f3n'),
          _HelpableTile(
            helpEnabled: _helpEnabled,
            helpText: l10n.helpSettingsLogout,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesi\u00f3n'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpableTile extends StatefulWidget {
  final bool helpEnabled;
  final String helpText;
  final Widget child;
  final VoidCallback? onTap;

  const _HelpableTile({
    required this.helpEnabled,
    required this.helpText,
    required this.child,
    this.onTap,
  });

  @override
  State<_HelpableTile> createState() => _HelpableTileState();
}

class _HelpableTileState extends State<_HelpableTile> {
  Timer? _timer;
  bool _helpShown = false;

  void _startTimer() {
    if (!widget.helpEnabled || widget.helpText.trim().isEmpty) return;
    _timer?.cancel();
    _helpShown = false;
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _helpShown = true;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(widget.helpText)),
      );
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleTap() {
    _cancelTimer();
    if (_helpShown) {
      _helpShown = false;
      return;
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: (_) => _startTimer(),
        onTapCancel: _cancelTimer,
        onTap: widget.onTap == null ? null : _handleTap,
        child: widget.child,
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




