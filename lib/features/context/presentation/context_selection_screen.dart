import 'package:consorcio_360/core/services/context_storage.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/auth/presentation/login_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/main_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContextSelectionScreen extends StatefulWidget {
  const ContextSelectionScreen({super.key});

  @override
  State<ContextSelectionScreen> createState() => _ContextSelectionScreenState();
}

class _ContextSelectionScreenState extends State<ContextSelectionScreen> {
  late Future<List<UsuarioContexto>> _futureContextos;

  @override
  void initState() {
    super.initState();
    _futureContextos = _loadContexts();
  }

  Future<List<UsuarioContexto>> _loadContexts() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario logueado');
    }

    final response = await supabase
        .from('usuarios_unidades')
        .select('''
        id,
        rol,
        es_titular,
        unidades (
          id,
          codigo,
          consorcio_id,
          consorcios (
            id,
            nombre
          )
        ),
        usuarios (
          nombre,
          apellido,
          email
        )
      ''')
        .eq('usuario_id', user.id);

    if (response.isEmpty) {
      return [];
    }

    final data = response as List<dynamic>;

    return data.map<UsuarioContexto>((row) {
      final unidad = row['unidades'] as Map<String, dynamic>;
      final consorcio = unidad['consorcios'] as Map<String, dynamic>;
      final usuario = row['usuarios'] as Map<String, dynamic>;

      final nombre = (usuario['nombre'] as String?)?.trim() ?? '';
      final apellido = (usuario['apellido'] as String?)?.trim() ?? '';
      final email = (usuario['email'] as String?) ?? '';

      final nombreCompleto = [
        if (nombre.isNotEmpty) nombre,
        if (apellido.isNotEmpty) apellido,
      ].join(' ').trim();

      return UsuarioContexto(
        usuarioUnidadId: row['id'] as String,
        consorcioId: unidad['consorcio_id'] as String,
        consorcioNombre: consorcio['nombre'] as String,
        unidadId: unidad['id'] as String,
        unidadCodigo: unidad['codigo'] as String,
        nombre: nombreCompleto.isNotEmpty ? nombreCompleto : email,
        rol: row['rol'] as String,
        esTitular: row['es_titular'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await ContextStorage.limpiarContexto();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar contexto'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<UsuarioContexto>>(
        future: _futureContextos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar contextos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final contextos = snapshot.data ?? [];

          if (contextos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No tenes unidades asignadas.\n\n'
                  'Revisa en Supabase que exista al menos una fila en:\n'
                  'consorcios, unidades y usuarios_unidades para tu usuario.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contextos.length,
            itemBuilder: (context, index) {
              final ctx = contextos[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    ctx.consorcioNombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Unidad ${ctx.unidadCodigo} - ${ctx.rolLegible}',
                  ),
                  trailing: ctx.esTitular
                      ? const Chip(
                          label: Text('Titular'),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    // 1) Guardamos el contexto globalmente
                    context.read<CurrentContextNotifier>().setContext(ctx);
                    // 2) Persistimos la elección
                    await ContextStorage.guardarContexto(ctx);
                    if (!mounted) return;
                    // 3) Navegamos al home principal
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainHomeScreen()),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
