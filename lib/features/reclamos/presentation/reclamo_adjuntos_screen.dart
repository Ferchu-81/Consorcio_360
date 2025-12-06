import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reclamos_utils.dart';

/// Pantalla de adjuntos (lista con miniaturas)
class ReclamoAdjuntosScreen extends StatefulWidget {
  final String reclamoId;
  final Future<void> Function(Map<String, dynamic> adjunto) onOpenAdjunto;

  const ReclamoAdjuntosScreen({
    super.key,
    required this.reclamoId,
    required this.onOpenAdjunto,
  });

  @override
  State<ReclamoAdjuntosScreen> createState() => _ReclamoAdjuntosScreenState();
}

class _ReclamoAdjuntosScreenState extends State<ReclamoAdjuntosScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _adjuntos = [];
  final Map<String, String> _signedUrlsCache = {};

  @override
  void initState() {
    super.initState();
    _loadAdjuntos();
  }

  Future<void> _loadAdjuntos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final adjuntosData = await supabase
          .from('reclamo_adjuntos')
          .select('''
            id,
            archivo_nombre,
            storage_path,
            mime_type,
            fecha_subida
          ''')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_subida', ascending: true);

      setState(() {
        _adjuntos = List<Map<String, dynamic>>.from(adjuntosData);
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los archivos adjuntos.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getSignedUrl(String path) async {
    if (_signedUrlsCache.containsKey(path)) {
      return _signedUrlsCache[path];
    }
    try {
      final supabase = Supabase.instance.client;
      final url =
          await supabase.storage.from('reclamos').createSignedUrl(path, 60 * 60);
      _signedUrlsCache[path] = url;
      return url;
    } catch (_) {
      return null;
    }
  }

  IconData _iconForMime(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Archivos adjuntos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _adjuntos.isEmpty
                  ? Center(
                      child: Text(
                        'Este reclamo no tiene archivos adjuntos.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _adjuntos.length,
                      separatorBuilder: (context, _) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final a = _adjuntos[index];
                        final nombre = (a['archivo_nombre'] ?? '').toString();
                        final fecha = formatShortDateFromIso(a['fecha_subida']);
                        final mime = (a['mime_type'] ?? '').toString();
                        final path = (a['storage_path'] ?? '').toString();
                        final esImagen = mime.startsWith('image/');

                        Widget leading;
                        if (esImagen && path.isNotEmpty) {
                          leading = FutureBuilder<String?>(
                            future: _getSignedUrl(path),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  !snapshot.hasData) {
                                return const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final url = snapshot.data!;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  url,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          );
                        } else {
                          leading = Icon(
                            _iconForMime(mime),
                            size: 32,
                            color: Colors.grey.shade700,
                          );
                        }

                        return ListTile(
                          leading: leading,
                          title: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(fecha),
                          onTap: () => widget.onOpenAdjunto(a),
                        );
                      },
                    ),
    );
  }
}
