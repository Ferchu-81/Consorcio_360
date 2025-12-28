import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Pantalla generica para ver un PDF dentro de la app.
class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return PdfPreview.builder(
            build: buildPdf,
            canChangePageFormat: false,
            initialPageFormat: PdfPageFormat.a4,
            useActions: false,
            pagesBuilder: (context, pages) {
              return InteractiveViewer(
                constrained: false,
                minScale: 1,
                maxScale: 5,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: pages
                          .map(
                            (page) => Container(
                              margin: const EdgeInsets.only(
                                left: 20,
                                top: 8,
                                right: 20,
                                bottom: 12,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    offset: Offset(0, 3),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: AspectRatio(
                                aspectRatio: page.aspectRatio,
                                child: Image(
                                  image: page.image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
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

