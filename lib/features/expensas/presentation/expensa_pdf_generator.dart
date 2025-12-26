import 'dart:typed_data';

import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Factura / boleta de expensa para pago presencial o comprobante de pago.
Future<Uint8List> buildExpensaFacturaPdfA4({
  required Expensa expensa,
  required String consorcioNombre,
  required String consorcioCuit,
  required String unidadCodigo,
  PagoExpensa? pago,
}) async {
  final doc = pw.Document();

  final periodoStr =
      '${expensa.periodo.month.toString().padLeft(2, '0')}/${expensa.periodo.year}';

  final venceStr =
      '${expensa.fechaVenc.day.toString().padLeft(2, '0')}/${expensa.fechaVenc.month.toString().padLeft(2, '0')}/${expensa.fechaVenc.year}';

  final estadoPago = pago == null ? 'PENDIENTE' : pago.estadoPago;
  final importePago = pago?.importe ?? expensa.importeTotal;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        consorcioNombre,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (consorcioCuit.isNotEmpty)
                        pw.Text('CUIT: $consorcioCuit'),
                      pw.SizedBox(height: 8),
                      pw.Text('Unidad: $unidadCodigo'),
                      pw.Text('Periodo: $periodoStr'),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          pago == null
                              ? 'BOLETA DE EXPENSAS'
                              : 'COMPROBANTE DE PAGO',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Estado: $estadoPago'),
                        pw.Text('Vence: $venceStr'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFEFEFEF),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Concepto',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Importe',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Expensas ordinarias'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          _formatMoney(expensa.importeTotal, expensa.moneda),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total a pagar: ${_formatMoney(importePago, expensa.moneda)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Instrucciones de pago',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pago == null
                ? pw.Text(
                    'Esta boleta puede ser utilizada para pago presencial en la administracion '
                    'o por los medios acordados (transferencia, etc.).',
                    style: const pw.TextStyle(fontSize: 10),
                  )
                : pw.Text(
                    'Pago registrado el ${_formatDate(pago.fechaPago)} '
                    'por ${_medioPagoLabel(pago.medioPago)}.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generado por Consorcio 360',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

String _formatMoney(num value, String moneda) {
  final v = value.toDouble();
  final str = v.toStringAsFixed(2).replaceAll('.', ',');
  return '$moneda $str';
}

String _formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

String _medioPagoLabel(String medio) {
  switch (medio) {
    case 'EFECTIVO':
      return 'Efectivo';
    case 'TRANSFERENCIA':
      return 'Transferencia';
    case 'MERCADO_PAGO':
      return 'Mercado Pago';
    default:
      return medio;
  }
}
