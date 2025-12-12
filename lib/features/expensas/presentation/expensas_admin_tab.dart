import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensa_admin_detail_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:consorcio_360/features/expensas/presentation/nueva_expensa_screen.dart';
import 'package:flutter/material.dart';

/// Vista de expensas para administrador: filtros y listado por consorcio.
class ExpensasAdminTab extends StatefulWidget {
  final String consorcioId;
  final String consorcioNombre;

  const ExpensasAdminTab({
    super.key,
    required this.consorcioId,
    required this.consorcioNombre,
  });

  @override
  State<ExpensasAdminTab> createState() => _ExpensasAdminTabState();
}

class _ExpensasAdminTabState extends State<ExpensasAdminTab> {
  final ExpensasRepository _repo = ExpensasRepository();

  /// Unidades del consorcio: cada mapa tiene al menos {id, codigo}
  List<Map<String, dynamic>> _unidades = [];

  /// null = todas las unidades
  String? _unidadSeleccionada;
  String _estadoSeleccionado = 'TODOS';
  DateTime? _desde;
  DateTime? _hasta;

  Future<List<Expensa>>? _futureExpensas;
  bool _cargandoFiltros = true;

  @override
  void initState() {
    super.initState();
    _cargarFiltrosYExpensas();
  }

  Future<void> _cargarFiltrosYExpensas() async {
    setState(() {
      _cargandoFiltros = true;
    });

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
    return _repo
        .fetchExpensasAdmin(
          consorcioId: widget.consorcioId,
          unidadId: _unidadSeleccionada, // null = todas
          estado: null, // filtramos por estado en memoria para contemplar vencidas
          desde: _desde,
          hasta: _hasta,
        )
        .then(
          (lista) => lista.where(_coincideFiltroEstadoVirtual).toList(),
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
      helpText: 'SeleccionÃ¡ periodo DESDE',
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
      helpText: 'SeleccionÃ¡ periodo HASTA',
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

  bool _coincideFiltroEstadoVirtual(Expensa expensa) {
    final filtro = _estadoSeleccionado.toUpperCase();
    final estadoBase = expensa.estado.toUpperCase();
    final estadoEfectivo = expensa.estadoEfectivo.toUpperCase();
    final esVencida = estadoEfectivo == 'VENCIDA';

    switch (filtro) {
      case 'VENCIDA':
        return esVencida;
      case 'PENDIENTE':
        return estadoBase == 'PENDIENTE' && !esVencida;
      case 'PAGADA':
        return estadoBase == 'PAGADA';
      case 'PARCIAL':
        return estadoBase == 'PARCIAL' || estadoBase == 'PAGOPARCIAL';
      case 'ANULADA':
        return estadoBase == 'ANULADA';
      case 'TODOS':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (_cargandoFiltros) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openNuevaExpensa,
              icon: const Icon(Icons.add),
              label: const Text('Nueva expensa'),
            ),
          ),
        ),
        _buildFiltros(),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _aplicarFiltros(),
            child: _futureExpensas == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : FutureBuilder<List<Expensa>>(
                    future: _futureExpensas,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !_cargandoFiltros) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
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

                          // Buscar datos de la unidad para mostrar su cÃ³digo.
                          final unidadMap = _unidades.firstWhere(
                            (u) => u['id'] == e.unidadId,
                            orElse: () => <String, dynamic>{},
                          );

                          final unidadLabel =
                              (e.unidadCodigo ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty
                              ? e.unidadCodigo!
                              : (unidadMap['codigo'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                              ? (unidadMap['codigo'] ?? '').toString()
                              : e.unidadId;

                          final estadoReal = e.estadoEfectivo;
                          final estadoLabel = formatEstado(estadoReal);
                          final color = estadoColor(estadoReal);

                          return Card(
                            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final recargar = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ExpensaAdminDetailScreen(
                                              consorcioId: widget.consorcioId,
                                              consorcioNombre:
                                                  widget.consorcioNombre,
                                              expensa: e,
                                              unidadCodigo: unidadLabel,
                                            ),
                                      ),
                                    );

                                if (recargar == true && mounted) {
                                  setState(() {
                                    _futureExpensas = _consultarExpensas();
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.receipt_long_outlined),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Unidad $unidadLabel • ${formatPeriodo(e.periodo)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Vence: ${formatFechaCorta(e.fechaVenc)}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formatImporte(
                                            e.importeTotal,
                                            e.moneda,
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Chip(
                                          label: Text(estadoLabel),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: color.withValues(
                                            alpha: 0.12,
                                          ),
                                          labelStyle: TextStyle(color: color),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFiltroUnidad()),
              const SizedBox(width: 8),
              Expanded(child: _buildFiltroEstado()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildFiltroFechaDesde()),
              const SizedBox(width: 8),
              Expanded(child: _buildFiltroFechaHasta()),
            ],
          ),
        ],
      ),
    );
  }

  /// Filtro de unidad: usa null = todas las unidades.
  Widget _buildFiltroUnidad() {
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Unidad',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      initialValue: _unidadSeleccionada,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
        ..._unidades.map(
          (u) => DropdownMenuItem<String?>(
            value: u['id'] as String,
            child: Text((u['codigo'] ?? '').toString()),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _unidadSeleccionada = value;
        });
        _aplicarFiltros();
      },
    );
  }

  Widget _buildFiltroEstado() {
    return DropdownButtonFormField<String>(
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
        setState(() {
          _estadoSeleccionado = value;
        });
        _aplicarFiltros();
      },
    );
  }

  Widget _buildFiltroFechaDesde() {
    return OutlinedButton.icon(
      onPressed: _seleccionarDesde,
      icon: const Icon(Icons.date_range),
      label: Text('Desde: ${_textoFecha(_desde)}'),
    );
  }

  Widget _buildFiltroFechaHasta() {
    return OutlinedButton.icon(
      onPressed: _seleccionarHasta,
      icon: const Icon(Icons.date_range),
      label: Text('Hasta: ${_textoFecha(_hasta)}'),
    );
  }

  Future<void> _openNuevaExpensa() async {
    final recargar = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NuevaExpensaScreen(consorcioId: widget.consorcioId),
      ),
    );

    if (recargar == true && mounted) {
      await _aplicarFiltros();
    }
  }
}


