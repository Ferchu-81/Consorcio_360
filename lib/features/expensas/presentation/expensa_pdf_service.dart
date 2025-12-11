import 'dart:typed_data';

import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:pdf/widgets.dart' as pw;

class ExpensaPdfService {
  static Future<Uint8List> buildComprobantePago({
    required Expensa expensa,
    required PagoExpensa pago,
    required String consorcioNombre,
    required String unidadCodigo,
    required String moradorNombre,
  }) async {
    final doc = pw.Document();

    final importePago =
        formatImporte(pago.importe, pago.monedaExpensa ?? expensa.moneda);
    final importeExpensa = formatImporte(
      expensa.importeTotal,
      expensa.moneda,
    );

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              consorcioNombre,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Comprobante de pago de expensa'),
            pw.SizedBox(height: 12),
            pw.Text('Unidad: $unidadCodigo'),
            pw.Text('Titular / Morador: $moradorNombre'),
            pw.SizedBox(height: 8),
            pw.Text('Periodo: ${formatPeriodo(expensa.periodo)}'),
            pw.Text('Importe total: $importeExpensa'),
            pw.SizedBox(height: 10),
            pw.Text('Pago registrado:'),
            pw.Bullet(
              text:
                  'Importe: $importePago - Medio: ${formatEstado(pago.medioPago)}',
            ),
            pw.Bullet(
              text: 'Fecha: ${formatFechaCorta(pago.fechaPago)}',
            ),
            if ((pago.observaciones ?? '').trim().isNotEmpty)
              pw.Bullet(text: 'Obs: ${pago.observaciones}'),
            pw.SizedBox(height: 14),
            pw.Text(
              'Estado de expensa: ${formatEstado(expensa.estado)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildComprobanteExpensa({
    required Expensa expensa,
    required String consorcioNombre,
    required String unidadCodigo,
    required String moradorNombre,
  }) async {
    final doc = pw.Document();
    final importeExpensa = formatImporte(expensa.importeTotal, expensa.moneda);

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              consorcioNombre,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Comprobante de expensa'),
            pw.SizedBox(height: 12),
            pw.Text('Unidad: $unidadCodigo'),
            pw.Text('Titular / Morador: $moradorNombre'),
            pw.SizedBox(height: 8),
            pw.Text('Periodo: ${formatPeriodo(expensa.periodo)}'),
            pw.Text('Importe total: $importeExpensa'),
            pw.Text('Vencimiento: ${formatFechaCorta(expensa.fechaVenc)}'),
            pw.SizedBox(height: 14),
            pw.Text(
              'Estado de expensa: ${formatEstado(expensa.estado)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildBoletaExpensa({
    required Expensa expensa,
    required String consorcioNombre,
    required String unidadCodigo,
    required String moradorNombre,
  }) async {
    final doc = pw.Document();
    final importe = formatImporte(expensa.importeTotal, expensa.moneda);

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              consorcioNombre,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Boleta de expensa'),
            pw.SizedBox(height: 12),
            pw.Text('Unidad: $unidadCodigo'),
            pw.Text('Titular / Morador: $moradorNombre'),
            pw.SizedBox(height: 8),
            pw.Text('Periodo: ${formatPeriodo(expensa.periodo)}'),
            pw.Text('Importe a abonar: $importe'),
            pw.Text('Vencimiento: ${formatFechaCorta(expensa.fechaVenc)}'),
            pw.SizedBox(height: 12),
            pw.Text(
              'Presentar este comprobante al pagar en ventanilla o transferencia.',
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }
}
