import 'dart:async';

import 'package:flutter/material.dart';

import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefHelpEnabledKey = 'ui_help_enabled';

class PagosTab extends StatefulWidget {
  final UsuarioContexto contexto;

  const PagosTab({
    super.key,
    required this.contexto,
  });

  @override
  State<PagosTab> createState() => _PagosTabState();
}

class _PagosTabState extends State<PagosTab> {
  final ExpensasRepository _repo = ExpensasRepository();
  late Future<List<PagoExpensa>> _futurePagos;
  Map<String, String> _unidadCodigoPorId = {};
  bool _helpEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHelpEnabled();
    _cargarCodigosUnidades();
    _futurePagos = _loadPagos();
  }

  Future<void> _loadHelpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefHelpEnabledKey);
    if (!mounted || value == null) return;
    setState(() => _helpEnabled = value);
  }

  Future<void> _cargarCodigosUnidades() async {
    if (widget.contexto.rol != 'ADMIN_CONSORCIO') return;
    final unidades =
        await _repo.fetchUnidadesDeConsorcio(widget.contexto.consorcioId);
    if (!mounted) return;
    setState(() {
      _unidadCodigoPorId = {
        for (final u in unidades)
          if (u['id'] != null && u['codigo'] != null)
            u['id'].toString(): u['codigo'].toString(),
      };
    });
  }

  Future<List<PagoExpensa>> _loadPagos() {
    final ctx = widget.contexto;
    final rol = ctx.rol;

    if (rol == 'ADMIN_CONSORCIO') {
      // ADMIN: ve todos los pagos del consorcio actual.
      // Si la unidad del contexto es GLOBAL, no filtramos por unidad.
      return _repo.fetchPagosAdmin(
        consorcioId: ctx.consorcioId,
        unidadId: ctx.unidadCodigo == 'GLOBAL' ? null : ctx.unidadId,
      );
    }

    // MORADOR / PROPIETARIO: solo pagos de su unidad
    return _repo.fetchPagosMorador(unidadId: ctx.unidadId);
  }

  Future<void> _refresh() async {
    await _cargarCodigosUnidades();
    setState(() {
      _futurePagos = _loadPagos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<PagoExpensa>>(
        future: _futurePagos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error al cargar pagos: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          final pagos = snapshot.data ?? [];

          if (pagos.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay pagos registrados para esta unidad.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: pagos.length,
            itemBuilder: (context, index) {
              final pago = pagos[index];
              final esAdmin = widget.contexto.rol == 'ADMIN_CONSORCIO';

              // Mostrar código legible; para admin intentamos mapear id->código.
              final unidadLabel = esAdmin
                  ? (_unidadCodigoPorId[pago.unidadId] ??
                      (widget.contexto.unidadCodigo != 'GLOBAL'
                          ? widget.contexto.unidadCodigo
                          : pago.unidadId))
                  : widget.contexto.unidadCodigo;

              final periodoLabel = pago.periodoExpensa != null
                  ? formatPeriodo(pago.periodoExpensa!)
                  : '';
              final color = estadoPagoColor(pago.estadoPago);
              final estadoLabel = formatEstadoPago(pago.estadoPago);
              final medioLabel = formatEstado(pago.medioPago);

              return _HelpListener(
                helpEnabled: _helpEnabled,
                helpText: 'Detalle de pago registrado.',
                child: Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  isThreeLine: true,
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(
                    'Unidad $unidadLabel • $periodoLabel',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Fecha: ${formatFechaCorta(pago.fechaPago)}\n'
                    'Medio: $medioLabel',
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatImporte(
                          pago.importe,
                          pago.monedaExpensa ?? 'ARS',
                        ),
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
                ),
              );
            },
          );
        },
      ),
    );
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
