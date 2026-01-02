import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _available = true;

  bool email = true;
  bool whatsapp = false;
  bool sms = false;
  bool push = true;

  bool vencimientos = true;
  bool mensajes = true;
  bool reclamos = true;

  bool aplicarATodos = false;

  String _keyBase = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ctx = context.read<CurrentContextNotifier>().current;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (ctx == null || userId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _available = false;
        });
      }
      return;
    }

    _keyBase = 'notif_${userId}_${ctx.consorcioId}_${ctx.unidadId}_${ctx.rol}';
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      email = prefs.getBool('${_keyBase}_email') ?? true;
      whatsapp = prefs.getBool('${_keyBase}_whatsapp') ?? false;
      sms = prefs.getBool('${_keyBase}_sms') ?? false;
      push = prefs.getBool('${_keyBase}_push') ?? true;

      vencimientos = prefs.getBool('${_keyBase}_venc') ?? true;
      mensajes = prefs.getBool('${_keyBase}_msg') ?? true;
      reclamos = prefs.getBool('${_keyBase}_recl') ?? true;

      aplicarATodos = prefs.getBool('${_keyBase}_all') ?? false;

      _loading = false;
      _available = true;
    });
  }

  Future<void> _save() async {
    if (_keyBase.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('${_keyBase}_email', email);
    await prefs.setBool('${_keyBase}_whatsapp', whatsapp);
    await prefs.setBool('${_keyBase}_sms', sms);
    await prefs.setBool('${_keyBase}_push', push);

    await prefs.setBool('${_keyBase}_venc', vencimientos);
    await prefs.setBool('${_keyBase}_msg', mensajes);
    await prefs.setBool('${_keyBase}_recl', reclamos);

    await prefs.setBool('${_keyBase}_all', aplicarATodos);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferencias guardadas')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<CurrentContextNotifier>().current;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Notificaciones')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_available || ctx == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Notificaciones')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay un contexto seleccionado para configurar notificaciones.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Estas preferencias aplican a:\n${ctx.descripcionLarga}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Text('Canales', style: TextStyle(fontWeight: FontWeight.w700)),
          SwitchListTile(
            title: const Text('Email'),
            value: email,
            onChanged: (v) => setState(() => email = v),
          ),
          SwitchListTile(
            title: const Text('WhatsApp'),
            value: whatsapp,
            onChanged: (v) => setState(() => whatsapp = v),
          ),
          SwitchListTile(
            title: const Text('SMS'),
            value: sms,
            onChanged: (v) => setState(() => sms = v),
          ),
          SwitchListTile(
            title: const Text('Push en la app'),
            value: push,
            onChanged: (v) => setState(() => push = v),
          ),
          const SizedBox(height: 12),
          const Text('Eventos', style: TextStyle(fontWeight: FontWeight.w700)),
          SwitchListTile(
            title: const Text('Vencimientos de expensas'),
            value: vencimientos,
            onChanged: (v) => setState(() => vencimientos = v),
          ),
          SwitchListTile(
            title: const Text('Mensajes'),
            value: mensajes,
            onChanged: (v) => setState(() => mensajes = v),
          ),
          SwitchListTile(
            title: const Text('Novedades de reclamos'),
            value: reclamos,
            onChanged: (v) => setState(() => reclamos = v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Aplicar esta configuración a todos mis roles'),
            subtitle: const Text(
              'Copia estas preferencias a otros contextos/roles (próxima '
              'iteración: sincronizar en Supabase).',
            ),
            value: aplicarATodos,
            onChanged: (v) => setState(() => aplicarATodos = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
