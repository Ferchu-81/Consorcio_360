import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'pdf_preview_screen.dart';

/// Muestra opciones comunes para PDFs: ver, imprimir y compartir.
Future<void> showPdfOptionsBottomSheet({
  required BuildContext context,
  required String title,
  required String fileName,
  required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PdfPreviewScreen(
                      title: title,
                      buildPdf: buildPdf,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Imprimir'),
              onTap: () async {
                Navigator.of(context).pop();
                await Printing.layoutPdf(
                  onLayout: (format) => buildPdf(format),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Compartir'),
              onTap: () async {
                Navigator.of(context).pop();
                final bytes = await buildPdf(PdfPageFormat.a4);
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: fileName,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
