import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'new_reclamo_screen.dart';
import 'reclamo_detail_screen.dart';
import 'reclamos_utils.dart';

/// Tab de Reclamos (lista + botón "Nuevo reclamo")
import 'package:consorcio_360/data/models/usuario_contexto.dart';

class ReclamosTab extends StatefulWidget {
  final UsuarioContexto? contexto;

  const ReclamosTab({super.key, this.contexto});

  @override
  State<ReclamosTab> createState() => _ReclamosTabState();
}

class _ReclamosTabState extends State<ReclamosTab> {
  late Future<List<Map<String, dynamic>>> _futureReclamos;

  @override
  void initState() {
    super.initState();
    _futureReclamos = _loadReclamos();
  }

  Future<List<Map<String, dynamic>>> _loadReclamos() async {
    final supabase = Supabase.instance.client;
    final contexto =
        widget.contexto ?? context.read<CurrentContextNotifier>().current;

    if (contexto == null) {
      throw Exception('No hay contexto seleccionado.');
    }

    final response = await supabase
        .from('reclamos')
        .select()
        .eq('unidad_id', contexto.unidadId)
        .order('fecha_creacion', ascending: false);

    final data = response as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _openNewReclamo() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const NewReclamoScreen()));

    if (!mounted) return;

    if (created == true) {
      setState(() {
        _futureReclamos = _loadReclamos();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclamo creado correctamente.')),
      );
    }
  }

  void _openDetalle(Map<String, dynamic> reclamo) {
    final id = reclamo['id'] as String;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReclamoDetailScreen(reclamoId: id)),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN_CURSO':
        return Colors.blue;
      case 'EN_ESPERA':
        return Colors.amber;
      case 'RESUELTO':
        return Colors.green;
      case 'CERRADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _prioridadColor(String prioridad) {
    switch (prioridad) {
      case 'ALTA':
        return Colors.red;
      case 'MEDIA':
        return Colors.orange;
      case 'BAJA':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openNewReclamo,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo reclamo'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureReclamos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Error al cargar reclamos. Intenta nuevamente.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _futureReclamos = _loadReclamos();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final reclamos = snapshot.data ?? [];

                if (reclamos.isEmpty) {
                  return Center(
                    child: Text(
                      'No tenes reclamos para esta unidad.\n'
                      'Crea tu primer reclamo con el boton de arriba.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reclamos.length,
                  itemBuilder: (context, index) {
                    final r = reclamos[index];
                    final fechaStr = formatShortDateFromIso(
                      r['fecha_creacion'],
                    );
                    final estado = (r['estado'] ?? '').toString();
                    final prioridad = (r['prioridad'] ?? '').toString();
                    final estadoLabel = formatEnumLabel(estado);
                    final prioridadLabel = formatEnumLabel(prioridad);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _openDetalle(r),
                        title: Text(
                          r['titulo']?.toString() ?? '(Sin titulo)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r['tipo'] != null) Text('Tipo: ${r['tipo']}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _estadoColor(
                                      estado,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    estadoLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _estadoColor(estado),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _prioridadColor(
                                      prioridad,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Prioridad: $prioridadLabel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _prioridadColor(prioridad),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Creado: $fechaStr',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
