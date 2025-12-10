import 'dart:typed_data';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensa_pdf_service.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

const bool kDemoPagosHabilitado = true;

/// Detalle de una expensa + pagos asociados.
class ExpensaDetailScreen extends StatefulWidget {
  final Expensa expensa;

  const ExpensaDetailScreen({super.key, required this.expensa});

  @override
  State<ExpensaDetailScreen> createState() => _ExpensaDetailScreenState();
}

class _ExpensaDetailScreenState extends State<ExpensaDetailScreen> {
  final ExpensasRepository _repository = ExpensasRepository();

  Expensa? _expensa;
  List<PagoExpensa> _pagos = [];
  bool _loading = true;
  String? _error;
  bool _marcandoPago = false;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final expensaActualizada =
          await _repository.fetchExpensaPorId(widget.expensa.id) ??
          widget.expensa;
      final pagos = await _repository.fetchPagosDeExpensa(widget.expensa.id);

      if (!mounted) return;
      setState(() {
        _expensa = expensaActualizada;
        _pagos = pagos;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar la expensa. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Expensa get _currentExpensa => _expensa ?? widget.expensa;

  bool get _puedeMarcarDemo {
    final contexto = context.read<CurrentContextNotifier>().current;
    final esAdmin = contexto?.rol == 'ADMIN_CONSORCIO';
    return kDemoPagosHabilitado &&
        !esAdmin &&
        _currentExpensa.estado == 'PENDIENTE';
  }

  Future<void> _marcarComoPagada() async {
    final contexto = context.read<CurrentContextNotifier>().current;
    if (contexto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay contexto seleccionado.')),
      );
      return;
    }

    setState(() => _marcandoPago = true);

    try {
      await _repository.marcarExpensaComoPagadaDemo(
        expensaId: _currentExpensa.id,
        consorcioId: contexto.consorcioId,
        unidadId: contexto.unidadId,
        importe: _currentExpensa.importeTotal,
      );

      if (!mounted) return;
      setState(() {
        _expensa = _currentExpensa.copyWith(estado: 'PAGADA');
        _marcandoPago = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expensa marcada como pagada (demo).')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _marcandoPago = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el pago: $e')),
      );
    }
  }

  void _mostrarOpcionesComprobante(PagoExpensa pago) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Ver / imprimir comprobante'),
              onTap: () async {
                Navigator.of(context).pop();
                await _verComprobante(pago);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir comprobante'),
              onTap: () async {
                Navigator.of(context).pop();
                await _compartirComprobante(pago);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildComprobanteBytes(PagoExpensa pago) {
    final contexto = context.read<CurrentContextNotifier>().current;
    final consorcioNombre =
        contexto?.consorcioNombre ?? _currentExpensa.consorcioId;
    final unidadCodigo = contexto?.unidadCodigo ?? _currentExpensa.unidadId;
    const moradorNombre = ''; // No se almacena en contexto actualmente.

    return ExpensaPdfService.buildComprobantePago(
      expensa: _currentExpensa,
      pago: pago,
      consorcioNombre: consorcioNombre,
      unidadCodigo: unidadCodigo,
      moradorNombre: moradorNombre,
    );
  }

  Future<void> _verComprobante(PagoExpensa pago) async {
    try {
      final bytes = await _buildComprobanteBytes(pago);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar comprobante: $e')),
      );
    }
  }

  Future<void> _compartirComprobante(PagoExpensa pago) async {
    try {
      final bytes = await _buildComprobanteBytes(pago);
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'comprobante-expensa-${_currentExpensa.periodo.toIso8601String()}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir comprobante: $e')),
      );
    }
  }

  void _mostrarOpcionesPago() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Pago manual (demo)'),
              onTap: () async {
                Navigator.of(context).pop();
                await _marcarComoPagada();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Pagar con pasarela (prÃ³ximamente)'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La integracion con Mercado Pago se implementara en la siguiente etapa.',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Generar boleta para pago presencial'),
              onTap: () async {
                Navigator.of(context).pop();
                await _generarBoletaPagoPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generarBoletaPagoPdf() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generacion de boleta pendiente de implementar.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expensa = _currentExpensa;
    final estadoLabel = formatEstado(expensa.estado);
    final unidadLabel =
        context.watch<CurrentContextNotifier>().current?.unidadCodigo ??
        expensa.unidadId;
    final estaPagada = expensa.estado == 'PAGADA';
    final tienePagos = _pagos.isNotEmpty;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expensa')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expensa')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loadDetalle,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Expensa')),
      body: RefreshIndicator(
        onRefresh: _loadDetalle,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatPeriodo(expensa.periodo),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total a pagar: ${formatImporte(expensa.importeTotal, expensa.moneda)}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vence: ${formatFechaCorta(expensa.fechaVenc)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text('Estado: $estadoLabel'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: estadoColor(
                            expensa.estado,
                          ).withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: estadoColor(expensa.estado),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('Unidad $unidadLabel'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_currentExpensa.estado != 'PAGADA') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _marcandoPago ? null : _mostrarOpcionesPago,
                  child: _marcandoPago
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Pagar expensa'),
                ),
              ),
              if (_puedeMarcarDemo) ...[
                const SizedBox(height: 4),
                const Text(
                  'Opciones demo habilitadas. La integracion con pasarela se agregara despues.',
                ),
              ],
            ],
            if (estaPagada && tienePagos) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Comprobante'),
                  onPressed: () => _mostrarOpcionesComprobante(_pagos.first),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text('Pagos registrados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_pagos.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Aun no hay pagos registrados para esta expensa.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ..._pagos.map((p) {
                final estadoPagoLabel = formatEstado(p.estadoPago);
                final color = estadoColor(
                  p.estadoPago == 'APROBADO' ? 'PAGADA' : p.estadoPago,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    title: Text(
                      formatImporte(p.importe, expensa.moneda),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${formatFechaCorta(p.fechaPago)}'),
                        Text('Medio: ${formatEstado(p.medioPago)}'),
                        if ((p.observaciones ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('Obs: ${p.observaciones}'),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(estadoPagoLabel),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: color.withValues(alpha: 0.12),
                      labelStyle: TextStyle(color: color),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

