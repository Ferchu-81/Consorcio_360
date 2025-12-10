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

  late Expensa _expensa;
  List<PagoExpensa> _pagos = [];
  bool _loading = true;
  String? _error;
  bool _pagando = false;

  @override
  void initState() {
    super.initState();
    _expensa = widget.expensa;
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

  bool get _puedeMarcarDemo {
    final contexto = context.read<CurrentContextNotifier>().current;
    final esAdmin = contexto?.rol == 'ADMIN_CONSORCIO';
    return kDemoPagosHabilitado &&
        !esAdmin &&
        _expensa.estado == 'PENDIENTE';
  }

  Future<void> _pagoManualDemo() async {
    final contexto = context.read<CurrentContextNotifier>().current;
    final consorcioId = contexto?.consorcioId ?? _expensa.consorcioId;
    final unidadId = contexto?.unidadId ?? _expensa.unidadId;

    setState(() => _pagando = true);

    try {
      await _repository.marcarExpensaComoPagadaDemo(
        expensaId: _expensa.id,
        consorcioId: consorcioId,
        unidadId: unidadId,
        importe: _expensa.importeTotal,
      );

      if (!mounted) return;

      setState(() {
        _expensa = _expensa.copyWith(estado: 'PAGADA');
        _pagando = false;
      });

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pagando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar pago: $e')),
      );
    }
  }

  Future<Uint8List> _buildComprobanteExpensaBytes() {
    final contexto = context.read<CurrentContextNotifier>().current;
    final consorcioNombre =
        contexto?.consorcioNombre ?? _expensa.consorcioId;
    final unidadCodigo = contexto?.unidadCodigo ?? _expensa.unidadId;
    const moradorNombre = '';

    return ExpensaPdfService.buildComprobanteExpensa(
      expensa: _expensa,
      consorcioNombre: consorcioNombre,
      unidadCodigo: unidadCodigo,
      moradorNombre: moradorNombre,
    );
  }

  void _mostrarOpcionesComprobanteExpensa() {
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
                await _verComprobanteExpensa();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir comprobante'),
              onTap: () async {
                Navigator.of(context).pop();
                await _compartirComprobanteExpensa();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verComprobanteExpensa() async {
    try {
      final bytes = await _buildComprobanteExpensaBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar comprobante: $e')),
      );
    }
  }

  Future<void> _compartirComprobanteExpensa() async {
    try {
      final bytes = await _buildComprobanteExpensaBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'comprobante-expensa-${_expensa.periodo.toIso8601String()}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir comprobante: $e')),
      );
    }
  }

  Future<void> _generarBoletaPdf() async {
    final contexto = context.read<CurrentContextNotifier>().current;
    final consorcioNombre =
        contexto?.consorcioNombre ?? _expensa.consorcioId;
    final unidadCodigo = contexto?.unidadCodigo ?? _expensa.unidadId;
    const moradorNombre = '';

    final bytes = await ExpensaPdfService.buildBoletaExpensa(
      expensa: _expensa,
      consorcioNombre: consorcioNombre,
      unidadCodigo: unidadCodigo,
      moradorNombre: moradorNombre,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'boleta-expensa-${_expensa.periodo.toIso8601String()}.pdf',
    );
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
                await _pagoManualDemo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Pagar con pasarela (próximamente)'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La integración con la pasarela de pago se implementará en la siguiente etapa.',
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
                await _generarBoletaPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expensa = _expensa;
    final estadoLabel = formatEstado(expensa.estado);
    final unidadLabel =
        context.watch<CurrentContextNotifier>().current?.unidadCodigo ??
        expensa.unidadId;
    final estaPagada = expensa.estado == 'PAGADA';

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
            if (!estaPagada) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _pagando ? null : _mostrarOpcionesPago,
                  child: _pagando
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
                  'Opciones demo habilitadas. La integración con pasarela se agregará después.',
                ),
              ],
            ],
            if (estaPagada) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Comprobante'),
                  onPressed: _mostrarOpcionesComprobanteExpensa,
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



