import 'package:consorcio_360/features/reclamos/presentation/adjunto_viewer_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamos_utils.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReclamoAdjuntosScreen extends StatefulWidget {
  final String reclamoId;

  const ReclamoAdjuntosScreen({super.key, required this.reclamoId});

  @override
  State<ReclamoAdjuntosScreen> createState() => _ReclamoAdjuntosScreenState();
}

class _ReclamoAdjuntosScreenState extends State<ReclamoAdjuntosScreen> {
  List<Map<String, dynamic>> _adjuntos = [];
  bool _isLoading = true;
  String? _error;

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

      final data = await supabase
          .from('reclamo_adjuntos')
          .select('*')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_subida', ascending: true);

      setState(() {
        _adjuntos = List<Map<String, dynamic>>.from(data);
      });
    } on PostgrestException catch (e, st) {
      debugPrint(
        'Postgrest error al cargar adjuntos de reclamo ${widget.reclamoId}: '
        '${e.message} (${e.code})\n$st',
      );
      setState(() {
        _error = 'Error al cargar los archivos adjuntos.';
      });
    } catch (e, st) {
      debugPrint(
        'Error inesperado al cargar adjuntos de reclamo ${widget.reclamoId}: '
        '$e\n$st',
      );
      setState(() {
        _error = 'Error al cargar los archivos adjuntos.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _resolveFilePath(Map<String, dynamic> a) {
    final candidates = [
      'storage_path',
      'path',
      'ruta',
      'url_archivo',
      'archivo_url',
      'url',
    ];

    for (final key in candidates) {
      final v = a[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  String _resolveFileName(Map<String, dynamic> a) {
    final nameKeys = [
      'archivo_nombre',
      'nombre_archivo',
      'file_name',
      'filename',
      'nombre',
    ];

    for (final key in nameKeys) {
      final v = a[key];
      if (v != null) {
        final text = v.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }

    final path = _resolveFilePath(a);
    if (path.isNotEmpty) {
      final clean = path.split('?').first;
      final parts = clean.split('/');
      final last = parts.isNotEmpty ? parts.last : '';
      if (last.isNotEmpty) return last;
    }

    return 'Archivo sin nombre';
  }

  String _guessMimeTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return 'application/octet-stream';
  }

  String _resolveMimeType(Map<String, dynamic> a) {
    final raw = a['mime_type']?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final name = _resolveFileName(a);
    return _guessMimeTypeFromName(name);
  }

  IconData _iconForMime(String mime) {
    if (mime.startsWith('image/')) return Icons.image;
    if (mime == 'application/pdf') return Icons.picture_as_pdf;
    if (mime.startsWith('video/')) return Icons.video_file;
    return Icons.insert_drive_file;
  }

  Future<String?> _getSignedUrl(String rawPathOrUrl) async {
    if (rawPathOrUrl.startsWith('http://') ||
        rawPathOrUrl.startsWith('https://')) {
      return rawPathOrUrl;
    }

    if (_signedUrlsCache.containsKey(rawPathOrUrl)) {
      return _signedUrlsCache[rawPathOrUrl];
    }

    try {
      final supabase = Supabase.instance.client;
      final url = await supabase.storage
          .from('reclamos')
          .createSignedUrl(rawPathOrUrl, 60 * 60);
      _signedUrlsCache[rawPathOrUrl] = url;
      return url;
    } catch (e, st) {
      debugPrint('Error obteniendo signedUrl para $rawPathOrUrl: $e\n$st');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archivos adjuntos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _adjuntos.isEmpty
          ? const Center(
              child: Text('No hay archivos adjuntos para este reclamo.'),
            )
          : ListView.builder(
              itemCount: _adjuntos.length,
              itemBuilder: (context, index) {
                final a = _adjuntos[index];
                final nombre = _resolveFileName(a);
                final fecha = formatShortDateFromIso(a['fecha_subida']);
                final mime = _resolveMimeType(a);
                final path = _resolveFilePath(a);
                final esImagen = mime.startsWith('image/');

                Widget leading;
                if (esImagen && path.isNotEmpty) {
                  if (path.startsWith('http')) {
                    leading = ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        path,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final url = snapshot.data!;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            url,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  }
                } else {
                  leading = CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    child: Icon(
                      _iconForMime(mime),
                      size: 22,
                      color: Colors.green.shade800,
                    ),
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
                  onTap: () async {
                    final path = _resolveFilePath(a);
                    if (path.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se encontró la ruta del archivo.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    final mime = _resolveMimeType(a);
                    final url = await _getSignedUrl(path);

                    if (!context.mounted) return;
                    if (url == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo obtener la URL del archivo.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdjuntoViewerScreen(
                          adjunto: a,
                          url: url,
                          mimeType: mime,
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
