import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showPdfActionSheet({
  required BuildContext context,
  required Future<Uint8List> Function() buildPdfBytes,
  required String filenameBase,
}) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver / imprimir'),
              onTap: () async {
                Navigator.pop(ctx);
                final bytes = await buildPdfBytes();
                await Printing.layoutPdf(onLayout: (_) async => bytes);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                final bytes = await buildPdfBytes();
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/$filenameBase.pdf');
                await file.writeAsBytes(bytes);
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Documento generado desde Consorcio 360',
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
