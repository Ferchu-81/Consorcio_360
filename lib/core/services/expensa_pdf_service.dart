import 'dart:typed_data';

import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExpensaPdfService {
  ExpensaPdfService._();

  static Future<Uint8List> buildComprobante({
    required Expensa expensa,
    required String consorcioNombre,
    String? consorcioCuit,
    String? consorcioDomicilio,
    required String unidadCodigo,
    required String moradorNombre,
    required PagoExpensa pago,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      consorcioNombre,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if ((consorcioCuit ?? '').isNotEmpty)
                      pw.Text('CUIT: $consorcioCuit'),
                    if ((consorcioDomicilio ?? '').isNotEmpty)
                      pw.Text(consorcioDomicilio!),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'COMPROBANTE DE EXPENSAS',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Periodo: ${expensa.periodoFormatted}'),
                    pw.Text('Vencimiento: ${expensa.fechaVencFormatted}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Datos de la unidad',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Unidad: $unidadCodigo'),
            pw.Text('Titular / Ocupante: $moradorNombre'),
            pw.SizedBox(height: 12),
            pw.Text(
              'Detalle de expensas',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              headers: const ['Concepto', 'Importe'],
              data: [
                ['Gastos comunes', _fmt(expensa.importeTotal)],
              ],
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'TOTAL A PAGAR: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        _fmt(expensa.importeTotal),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Pago registrado',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Fecha de pago: ${pago.fechaFormatted}'),
            pw.Text('Importe: ${_fmt(pago.importe)}'),
            pw.Text('Medio de pago: ${_displayEnum(pago.medioPago)}'),
            if ((pago.observaciones ?? '').trim().isNotEmpty)
              pw.Text('Observaciones: ${pago.observaciones}'),
            pw.Spacer(),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text(
              'Este comprobante acredita el pago de expensas para el periodo indicado.',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Consorcio 360 - Generado desde la aplicacion movil.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> buildBoletaExpensa({
    required Expensa expensa,
    required String consorcioNombre,
    String? consorcioCuit,
    String? consorcioDomicilio,
    required String unidadCodigo,
    required String moradorNombre,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
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
            if ((consorcioCuit ?? '').isNotEmpty) pw.Text('CUIT: $consorcioCuit'),
            if ((consorcioDomicilio ?? '').isNotEmpty)
              pw.Text(consorcioDomicilio!),
            pw.SizedBox(height: 10),
            pw.Text(
              'BOLETA DE EXPENSAS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Periodo: ${expensa.periodoFormatted}'),
            pw.Text('Vencimiento: ${expensa.fechaVencFormatted}'),
            pw.SizedBox(height: 10),
            pw.Text('Unidad: $unidadCodigo'),
            pw.Text('Titular / Ocupante: $moradorNombre'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              headers: const ['Concepto', 'Importe'],
              data: [
                ['Gastos comunes', _fmt(expensa.importeTotal)],
              ],
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 8),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL: ${_fmt(expensa.importeTotal)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'Presentar este comprobante para abonar en ventanilla o transferencia.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static String _fmt(double valor) =>
      '\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  static String _displayEnum(String value) {
    if (value.isEmpty) return value;
    return value.replaceAll('_', ' ');
  }
}
