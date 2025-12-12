import 'package:flutter/material.dart';

import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarCodigosUnidades();
    _futurePagos = _loadPagos();
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
      return _repo.fetchPagosAdmin(
        consorcioId: ctx.consorcioId,
        unidadId: ctx.unidadCodigo == 'GLOBAL' ? null : ctx.unidadId,
      );
    }

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

    final header = Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.blueAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pagos y tablero',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Este módulo muestra el estado de los pagos de expensas y está '
              'en desarrollo. La app ya implementa la integración con Mercado '
              'Pago en entorno de pruebas (sandbox): preferencias, checkout en '
              'la app y registro del pago.\n\n'
              'Durante las pruebas, algunas validaciones de usuarios de prueba '
              'de Mercado Pago pueden impedir completar un pago ficticio. La '
              'aplicación muestra un mensaje claro y mantiene la expensa como '
              'pendiente. En producción se usará la cuenta real del '
              'administrador y, opcionalmente, webhooks para confirmar pagos '
              'de forma automática.',
              style: TextStyle(fontSize: 13, height: 1.3),
            ),
          ],
        ),
      ),
    );

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
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: header,
                ),
                const SizedBox(height: 12),
                const Center(
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
            itemCount: pagos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: header,
                );
              }

              final pago = pagos[index - 1];
              final esAdmin = widget.contexto.rol == 'ADMIN_CONSORCIO';

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

              return Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(
                    'Unidad $unidadLabel · $periodoLabel',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Fecha: ${formatFechaCorta(pago.fechaPago)}\n'
                    'Medio: $medioLabel',
                  ),
                  trailing: Column(
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
              );
            },
          );
        },
      ),
    );
  }
}
