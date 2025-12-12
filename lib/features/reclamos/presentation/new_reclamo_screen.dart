import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reclamo_detail_screen.dart';

/// Pantalla para crear un nuevo reclamo.
class NewReclamoScreen extends StatefulWidget {
  const NewReclamoScreen({super.key});

  @override
  State<NewReclamoScreen> createState() => _NewReclamoScreenState();
}

class _NewReclamoScreenState extends State<NewReclamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  String? _tipoSeleccionado;
  String _prioridadSeleccionada = 'MEDIA';
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _tipos = const [
    'Filtracion',
    'Ruidos',
    'Ascensor',
    'Limpieza',
    'Otros',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    final contexto = context.read<CurrentContextNotifier>().current;

    if (user == null || contexto == null) {
      setState(() {
        _errorMessage = 'Sesion o contexto no validos. Volve a iniciar sesion.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final insertRes = await supabase
          .from('reclamos')
          .insert({
            'unidad_id': contexto.unidadId,
            'usuario_creador_id': user.id,
            'tipo': _tipoSeleccionado ?? 'Otros',
            'titulo': _tituloController.text.trim(),
            'descripcion': _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            'prioridad': _prioridadSeleccionada,
          })
          .select()
          .single();

      final nuevoId = insertRes['id'] as String;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReclamoDetailScreen(reclamoId: nuevoId),
        ),
      );
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Error al guardar el reclamo. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reclamo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de reclamo',
                    ),
                    items: _tipos
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    initialValue: _tipoSeleccionado,
                    onChanged: (value) {
                      setState(() {
                        _tipoSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ej.: Fuga de agua en baño',
                    ),
                    maxLength: 50,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un título';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Contá brevemente qué está pasando...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    initialValue: _prioridadSeleccionada,
                    items: const [
                      DropdownMenuItem(value: 'BAJA', child: Text('Baja')),
                      DropdownMenuItem(value: 'MEDIA', child: Text('Media')),
                      DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _prioridadSeleccionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _guardar,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar reclamo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
