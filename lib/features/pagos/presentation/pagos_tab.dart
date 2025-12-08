import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Historial de pagos de expensas para la unidad actual.
class PagosTab extends StatefulWidget {
  const PagosTab({super.key});

  @override
  State<PagosTab> createState() => _PagosTabState();
}

class _PagosTabState extends State<PagosTab> {
  final ExpensasRepository _repository = ExpensasRepository();
  late Future<List<PagoExpensa>> _futurePagos;

  @override
  void initState() {
    super.initState();
    _futurePagos = _loadPagos();
  }

  Future<List<PagoExpensa>> _loadPagos() async {
    final contexto = context.read<CurrentContextNotifier>().current;
    if (contexto == null) {
      throw Exception('No hay contexto seleccionado.');
    }
    return _repository.fetchPagosDeUnidad(contexto.unidadId);
  }

  Future<void> _refresh() async {
    setState(() {
      _futurePagos = _loadPagos();
    });
    await _futurePagos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: RefreshIndicator(
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
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudieron cargar los pagos.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
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
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'No hay pagos registrados para esta unidad.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
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
                final estadoLabel = formatEstado(pago.estadoPago);
                final color = estadoColor(
                  pago.estadoPago == 'APROBADO' ? 'PAGADA' : pago.estadoPago,
                );

                final periodoLabel = pago.periodoExpensa != null
                    ? formatPeriodo(pago.periodoExpensa!)
                    : 'Expensa ${pago.expensaId.substring(0, 8)}...';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      formatImporte(pago.importe, pago.monedaExpensa ?? 'ARS'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${formatFechaCorta(pago.fechaPago)}'),
                        Text('Medio: ${formatEstado(pago.medioPago)}'),
                        Text('Periodo: $periodoLabel'),
                        if (pago.expensaImporteTotal != null)
                          Text(
                            'Importe expensa: ${formatImporte(pago.expensaImporteTotal!, pago.monedaExpensa ?? 'ARS')}',
                          ),
                        if ((pago.observaciones ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('Obs: ${pago.observaciones}'),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(estadoLabel),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: color.withValues(alpha: 0.12),
                      labelStyle: TextStyle(color: color),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
