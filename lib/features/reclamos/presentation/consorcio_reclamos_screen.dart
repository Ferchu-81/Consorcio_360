import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reclamo_detail_screen.dart';
import 'reclamos_utils.dart';

/// Pantalla de reclamos del consorcio (solo para ADMIN_CONSORCIO).
class ConsorcioReclamosScreen extends StatefulWidget {
  const ConsorcioReclamosScreen({super.key});

  @override
  State<ConsorcioReclamosScreen> createState() =>
      _ConsorcioReclamosScreenState();
}

class _ConsorcioReclamosScreenState extends State<ConsorcioReclamosScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reclamos = [];

  String _estadoFiltro = 'TODOS';
  String _prioridadFiltro = 'TODAS';
  String _unidadFiltroTexto = '';

  final List<String> _estadosFiltro = const [
    'TODOS',
    'PENDIENTE',
    'EN_CURSO',
    'EN_ESPERA',
    'RESUELTO',
    'CERRADO',
  ];

  final List<String> _prioridadesFiltro = const [
    'TODAS',
    'BAJA',
    'MEDIA',
    'ALTA',
  ];

  @override
  void initState() {
    super.initState();
    _loadReclamosConsorcio();
  }

  Future<void> _loadReclamosConsorcio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final contexto = context.read<CurrentContextNotifier>().current;

      if (contexto == null) {
        throw Exception('No hay contexto seleccionado.');
      }

      if (contexto.rol != 'ADMIN_CONSORCIO') {
        throw Exception(
          'Solo un administrador de consorcio puede ver esta vista.',
        );
      }

      final response = await supabase
          .from('reclamos')
          .select('''
            id,
            titulo,
            tipo,
            estado,
            prioridad,
            fecha_creacion,
            unidad:unidades!inner (
              id,
              codigo,
              consorcio_id
            ),
            usuario:usuarios (
              id,
              nombre,
              email
            )
          ''')
          .eq('unidad.consorcio_id', contexto.consorcioId)
          .order('fecha_creacion', ascending: false);

      final data = response as List<dynamic>;
      setState(() {
        _reclamos = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar reclamos del consorcio: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _reclamosFiltrados {
    return _reclamos.where((r) {
      final estado = (r['estado'] ?? '').toString();
      final prioridad = (r['prioridad'] ?? '').toString();
      final unidad = (r['unidad']?['codigo'] ?? '').toString().toLowerCase();

      if (_estadoFiltro != 'TODOS' && estado != _estadoFiltro) {
        return false;
      }

      if (_prioridadFiltro != 'TODAS' && prioridad != _prioridadFiltro) {
        return false;
      }

      if (_unidadFiltroTexto.trim().isNotEmpty) {
        final filtro = _unidadFiltroTexto.trim().toLowerCase();
        if (!unidad.contains(filtro)) {
          return false;
        }
      }

      return true;
    }).toList();
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
    final contexto = context.watch<CurrentContextNotifier>().current;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          contexto == null
              ? 'Reclamos del consorcio'
              : 'Reclamos – ${contexto.consorcioNombre}',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadReclamosConsorcio,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Filtros
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Estado',
                                  ),
                                  initialValue: _estadoFiltro,
                                  items: _estadosFiltro
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e == 'TODOS'
                                                ? 'Todos'
                                                : formatEnumLabel(e),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _estadoFiltro = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Prioridad',
                                  ),
                                  initialValue: _prioridadFiltro,
                                  items: _prioridadesFiltro
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e == 'TODAS'
                                                ? 'Todas'
                                                : formatEnumLabel(e),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _prioridadFiltro = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por unidad (ej: 3B)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _unidadFiltroTexto = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _reclamosFiltrados.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No hay reclamos para el consorcio con los filtros actuales.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _reclamosFiltrados.length,
                              itemBuilder: (context, index) {
                                final r = _reclamosFiltrados[index];
                                final unidadCodigo =
                                    (r['unidad']?['codigo'] ?? '').toString();
                                final creadorNombre =
                                    (r['usuario']?['nombre'] ?? '')
                                        .toString();
                                final creadorEmail =
                                    (r['usuario']?['email'] ?? '').toString();
                                final creadorLabel = creadorNombre.isNotEmpty
                                    ? creadorNombre
                                    : creadorEmail;
                                final fechaStr =
                                    formatShortDateFromIso(r['fecha_creacion']);
                                final estado =
                                    (r['estado'] ?? '').toString();
                                final prioridad =
                                    (r['prioridad'] ?? '').toString();
                                final estadoLabel = formatEnumLabel(estado);
                                final prioridadLabel =
                                    formatEnumLabel(prioridad);

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    onTap: () => _openDetalle(r),
                                    title: Text(
                                      r['titulo']?.toString() ??
                                          '(Sin titulo)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Unidad $unidadCodigo · $creadorLabel',
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _estadoColor(
                                                  estado,
                                                ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _prioridadColor(
                                                  prioridad,
                                                ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Prioridad: $prioridadLabel',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      _prioridadColor(prioridad),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Fecha: $fechaStr',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    trailing:
                                        const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
