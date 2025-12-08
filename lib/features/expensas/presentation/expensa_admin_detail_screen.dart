import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:flutter/material.dart';

/// Detalle exclusivo para administrador, con cambio de estado.
class ExpensaAdminDetailScreen extends StatefulWidget {
  final String consorcioId;
  final String? consorcioNombre;
  final Expensa expensa;
  final String? unidadCodigo;

  const ExpensaAdminDetailScreen({
    super.key,
    required this.consorcioId,
    this.consorcioNombre,
    required this.expensa,
    this.unidadCodigo,
  });

  @override
  State<ExpensaAdminDetailScreen> createState() =>
      _ExpensaAdminDetailScreenState();
}

class _ExpensaAdminDetailScreenState extends State<ExpensaAdminDetailScreen> {
  final ExpensasRepository _repo = ExpensasRepository();

  late Expensa _expensaActual;
  late Future<List<PagoExpensa>> _futurePagos;
  String _estadoSeleccionado = 'PENDIENTE';
  bool _guardandoEstado = false;

  @override
  void initState() {
    super.initState();
    _expensaActual = widget.expensa;
    _estadoSeleccionado = _expensaActual.estado;
    _futurePagos = _repo.fetchPagosDeExpensa(_expensaActual.id);
  }

  Future<void> _actualizarEstado() async {
    if (_estadoSeleccionado == _expensaActual.estado) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El estado no cambio.')));
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cambio de estado'),
        content: Text(
          'La expensa pasara de ${_expensaActual.estado} '
          'a $_estadoSeleccionado. Confirmas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _guardandoEstado = true);

    try {
      await _repo.actualizarEstadoExpensa(
        expensaId: _expensaActual.id,
        nuevoEstado: _estadoSeleccionado,
      );

      if (!mounted) return;
      setState(() {
        _expensaActual = _expensaActual.copyWith(estado: _estadoSeleccionado);
        _guardandoEstado = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar estado: $e')));
      setState(() => _guardandoEstado = false);
    }
  }

  Future<void> _onVerComprobantePressed() async {
    // Placeholder: integrar generación/recuperación de comprobante y visor.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comprobante de pago: TODO implementar')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = _expensaActual;
    final estadoLabel = formatEstado(e.estado);
    final colorEstado = estadoColor(e.estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expensa - Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Ver comprobante',
            onPressed: _onVerComprobantePressed,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatPeriodo(e.periodo)} - Unidad ${widget.unidadCodigo ?? e.unidadId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Importe total: ${formatImporte(e.importeTotal, e.moneda)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Consorcio: ${widget.consorcioNombre ?? widget.consorcioId}'),
                  Text('Vence: ${formatFechaCorta(e.fechaVenc)}'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          initialValue: _estadoSeleccionado,
                          items: const [
                            DropdownMenuItem(
                              value: 'PENDIENTE',
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: 'PAGADA',
                              child: Text('Pagada'),
                            ),
                            DropdownMenuItem(
                              value: 'VENCIDA',
                              child: Text('Vencida'),
                            ),
                            DropdownMenuItem(
                              value: 'PARCIAL',
                              child: Text('Parcial'),
                            ),
                            DropdownMenuItem(
                              value: 'ANULADA',
                              child: Text('Anulada'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _estadoSeleccionado = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _guardandoEstado ? null : _actualizarEstado,
                        child: _guardandoEstado
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text('Estado actual: $estadoLabel'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorEstado.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: colorEstado),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pagos registrados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: FutureBuilder<List<PagoExpensa>>(
              future: _futurePagos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error al cargar pagos: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final pagos = snapshot.data ?? [];
                if (pagos.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay pagos registrados para esta expensa.',
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: pagos.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = pagos[index];
                    final color = estadoColor(
                      p.estadoPago == 'APROBADO' ? 'PAGADA' : p.estadoPago,
                    );
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        '${formatImporte(p.importe, p.monedaExpensa ?? e.moneda)} '
                        '- ${formatEstado(p.medioPago)}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha: ${formatFechaCorta(p.fechaPago)}'),
                          if ((p.observaciones ?? '').isNotEmpty)
                            Text('Obs: ${p.observaciones}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(formatEstado(p.estadoPago)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: color.withValues(alpha: 0.12),
                        labelStyle: TextStyle(color: color),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

