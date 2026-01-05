import 'dart:async';

import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensa_admin_detail_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:consorcio_360/features/expensas/presentation/nueva_expensa_screen.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vista de expensas para administrador: filtros y listado por consorcio.
const String _prefHelpEnabledKey = 'ui_help_enabled';

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
  bool _helpEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHelpEnabled();
    _cargarFiltrosYExpensas();
  }

  Future<void> _loadHelpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefHelpEnabledKey);
    if (!mounted || value == null) return;
    setState(() => _helpEnabled = value);
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
    return _repo.fetchExpensasAdmin(
      consorcioId: widget.consorcioId,
      unidadId: _unidadSeleccionada, // null = todas
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
    final l10n = AppLocalizations.of(context);

    final date = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: l10n.helpExpensaDateFrom,
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
    final l10n = AppLocalizations.of(context);

    final date = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: l10n.helpExpensaDateTo,
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
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (_cargandoFiltros) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: _HelpListener(
              helpEnabled: _helpEnabled,
              helpText: l10n.helpExpensaNew,
              child: FilledButton.icon(
                onPressed: _openNuevaExpensa,
                icon: const Icon(Icons.add),
                label: const Text('Nueva expensa'),
              ),
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

                          // Buscar datos de la unidad para mostrar su código.
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
                            child: _HelpableTile(
                              helpEnabled: _helpEnabled,
                              helpText: l10n.helpExpensaDetail,
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

class _HelpListener extends StatefulWidget {
  final bool helpEnabled;
  final String helpText;
  final Widget child;

  const _HelpListener({
    required this.helpEnabled,
    required this.helpText,
    required this.child,
  });

  @override
  State<_HelpListener> createState() => _HelpListenerState();
}

class _HelpListenerState extends State<_HelpListener> {
  Timer? _timer;

  void _startTimer() {
    if (!widget.helpEnabled || widget.helpText.trim().isEmpty) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
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

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _startTimer(),
      onPointerUp: (_) => _cancelTimer(),
      onPointerCancel: (_) => _cancelTimer(),
      child: widget.child,
    );
  }
}

class _HelpableTile extends StatefulWidget {
  final bool helpEnabled;
  final String helpText;
  final BorderRadius? borderRadius;
  final Widget child;
  final VoidCallback? onTap;

  const _HelpableTile({
    required this.helpEnabled,
    required this.helpText,
    required this.child,
    this.borderRadius,
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
        borderRadius: widget.borderRadius,
        onTapDown: (_) => _startTimer(),
        onTapCancel: _cancelTimer,
        onTap: widget.onTap == null ? null : _handleTap,
        child: widget.child,
      ),
    );
  }
}



