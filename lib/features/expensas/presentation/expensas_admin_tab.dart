import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensa_admin_detail_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:flutter/material.dart';

/// Vista de expensas para administrador: filtros y listado por consorcio.
class ExpensasAdminTab extends StatefulWidget {
  final String consorcioId;

  const ExpensasAdminTab({super.key, required this.consorcioId});

  @override
  State<ExpensasAdminTab> createState() => _ExpensasAdminTabState();
}

class _ExpensasAdminTabState extends State<ExpensasAdminTab> {
  final ExpensasRepository _repo = ExpensasRepository();

  List<Map<String, dynamic>> _unidades = [];
  String? _unidadSeleccionada;
  String _estadoSeleccionado = 'TODOS';
  DateTime? _desde;
  DateTime? _hasta;

  late Future<List<Expensa>> _futureExpensas;
  bool _cargandoFiltros = true;

  @override
  void initState() {
    super.initState();
    _cargarFiltrosYExpensas();
  }

  Future<void> _cargarFiltrosYExpensas() async {
    setState(() => _cargandoFiltros = true);

    try {
      final unidades = await _repo.fetchUnidadesDeConsorcio(widget.consorcioId);

      setState(() {
        _unidades = unidades;
        _cargandoFiltros = false;
        _futureExpensas = _consultarExpensas();
      });
    } catch (e) {
      setState(() {
        _cargandoFiltros = false;
        _futureExpensas = Future.error(e);
      });
    }
  }

  Future<List<Expensa>> _consultarExpensas() {
    return _repo.fetchExpensasAdmin(
      consorcioId: widget.consorcioId,
      unidadId: _unidadSeleccionada,
      estado: _estadoSeleccionado == 'TODOS' ? null : _estadoSeleccionado,
      desde: _desde,
      hasta: _hasta,
    );
  }

  Future<void> _aplicarFiltros() async {
    setState(() {
      _futureExpensas = _consultarExpensas();
    });
  }

  Future<void> _seleccionarDesde() async {
    final ahora = DateTime.now();
    final inicial = _desde ?? DateTime(ahora.year, ahora.month, 1);

    final date = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona periodo DESDE',
    );

    if (date != null) {
      setState(() {
        _desde = DateTime(date.year, date.month, 1);
      });
      await _aplicarFiltros();
    }
  }

  Future<void> _seleccionarHasta() async {
    final ahora = DateTime.now();
    final inicial = _hasta ?? DateTime(ahora.year, ahora.month, 1);

    final date = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona periodo HASTA',
    );

    if (date != null) {
      setState(() {
        _hasta = DateTime(date.year, date.month, 1);
      });
      await _aplicarFiltros();
    }
  }

  String _textoFecha(DateTime? d) {
    if (d == null) return 'Sin filtro';
    return '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (_cargandoFiltros) const LinearProgressIndicator(minHeight: 2),
        _buildFiltros(),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _aplicarFiltros(),
            child: FutureBuilder<List<Expensa>>(
              future: _futureExpensas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_cargandoFiltros) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error al cargar expensas: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final expensas = snapshot.data ?? [];

                if (expensas.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No se encontraron expensas con los filtros actuales.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: expensas.length,
                  itemBuilder: (context, index) {
                    final e = expensas[index];
                    final unidadNombre = _unidades.firstWhere(
                      (u) => u['id'] == e.unidadId,
                      orElse: () => <String, dynamic>{},
                    );
                    final unidadLabel =
                        (unidadNombre['codigo'] ?? unidadNombre['nombre']) ??
                        e.unidadId;
                    final estadoLabel = formatEstado(e.estado);
                    final color = estadoColor(e.estado);

                    return Card(
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        onTap: () async {
                          final recargar = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => ExpensaAdminDetailScreen(
                                    consorcioId: widget.consorcioId,
                                    expensa: e,
                                  ),
                                ),
                              );
                          if (recargar == true) {
                            await _aplicarFiltros();
                          }
                        },
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(
                          'Unidad $unidadLabel • ${formatPeriodo(e.periodo)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Vence: ${formatFechaCorta(e.fechaVenc)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatImporte(e.importeTotal, e.moneda),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(estadoLabel),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: color.withValues(alpha: 0.12),
                              labelStyle: TextStyle(color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Unidad',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              initialValue: _unidadSeleccionada,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._unidades.map(
                  (u) => DropdownMenuItem(
                    value: u['id'] as String,
                    child: Text((u['codigo'] ?? u['nombre'] ?? '').toString()),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _unidadSeleccionada = value;
                });
                _aplicarFiltros();
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              initialValue: _estadoSeleccionado,
              items: const [
                DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
                DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                DropdownMenuItem(value: 'PAGADA', child: Text('Pagada')),
                DropdownMenuItem(value: 'VENCIDA', child: Text('Vencida')),
                DropdownMenuItem(value: 'PARCIAL', child: Text('Parcial')),
                DropdownMenuItem(value: 'ANULADA', child: Text('Anulada')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _estadoSeleccionado = value);
                _aplicarFiltros();
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: _seleccionarDesde,
            icon: const Icon(Icons.date_range),
            label: Text('Desde: ${_textoFecha(_desde)}'),
          ),
          OutlinedButton.icon(
            onPressed: _seleccionarHasta,
            icon: const Icon(Icons.date_range),
            label: Text('Hasta: ${_textoFecha(_hasta)}'),
          ),
        ],
      ),
    );
  }
}
