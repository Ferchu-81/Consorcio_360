import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _dniCuit = TextEditingController();
  final _domFiscal = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _dniCuit.dispose();
    _domFiscal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final row =
        await client.from('usuarios').select().eq('id', user.id).maybeSingle();
    if (row != null) {
      _nombre.text = (row['nombre'] ?? '') as String;
      _apellido.text = (row['apellido'] ?? '') as String;
      _telefono.text = (row['telefono'] ?? '') as String;
      _dniCuit.text = (row['dni_cuit'] ?? '') as String;
      _domFiscal.text = (row['domicilio_fiscal'] ?? '') as String;
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    await client.from('usuarios').update({
      'nombre': _nombre.text.trim().isEmpty ? null : _nombre.text.trim(),
      'apellido': _apellido.text.trim().isEmpty ? null : _apellido.text.trim(),
      'telefono': _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
      'dni_cuit': _dniCuit.text.trim().isEmpty ? null : _dniCuit.text.trim(),
      'domicilio_fiscal':
          _domFiscal.text.trim().isEmpty ? null : _domFiscal.text.trim(),
    }).eq('id', user.id);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _apellido,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _telefono,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dniCuit,
                  decoration: const InputDecoration(labelText: 'DNI / CUIT'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _domFiscal,
                  decoration:
                      const InputDecoration(labelText: 'Domicilio fiscal'),
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ],
            ),
    );
  }
}
