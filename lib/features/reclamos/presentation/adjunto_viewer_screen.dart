import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class AdjuntoViewerScreen extends StatelessWidget {
  final Map<String, dynamic> adjunto;
  final String url;
  final String mimeType;

  const AdjuntoViewerScreen({
    super.key,
    required this.adjunto,
    required this.url,
    required this.mimeType,
  });

  String _resolveNombre() {
    final raw = adjunto['archivo_nombre']?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Adjunto';
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _resolveNombre();
    final lowerMime = mimeType.toLowerCase();

    Widget body;

    if (lowerMime.startsWith('image/')) {
      body = Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (lowerMime == 'application/pdf') {
      body = SfPdfViewer.network(url);
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Este tipo de archivo no se puede mostrar dentro de la app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(url);
                final ok = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir el archivo.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir con otra aplicación'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          nombre,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: body,
    );
  }
}
