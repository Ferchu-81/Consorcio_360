import 'dart:typed_data';

import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamo_adjuntos_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamos_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReclamoDetailScreen extends StatefulWidget {
  final String reclamoId;

  const ReclamoDetailScreen({super.key, required this.reclamoId});

  @override
  State<ReclamoDetailScreen> createState() => _ReclamoDetailScreenState();
}

class _ReclamoDetailScreenState extends State<ReclamoDetailScreen> {
  Map<String, dynamic>? _reclamo;
  List<Map<String, dynamic>> _mensajes = [];
  List<Map<String, dynamic>> _adjuntos = [];

  bool _isLoading = true;
  String? _error;

  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _enviando = false;
  bool _cambiandoEstado = false;
  bool _subiendoAdjunto = false;

  final List<String> _estadosPosibles = const [
    'PENDIENTE',
    'EN_CURSO',
    'EN_ESPERA',
    'RESUELTO',
    'CERRADO',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final reclamoData = await supabase
          .from('reclamos')
          .select('''
            id,
            titulo,
            tipo,
            estado,
            prioridad,
            descripcion,
            fecha_creacion,
            unidad:unidades (
              codigo
            )
          ''')
          .eq('id', widget.reclamoId)
          .maybeSingle();

      if (reclamoData == null) {
        setState(() {
          _reclamo = null;
          _mensajes = [];
          _adjuntos = [];
          _error = 'Reclamo no encontrado.';
        });
        return;
      }

      final mensajesData = await supabase
          .from('reclamo_mensajes')
          .select('''
            id,
            texto,
            fecha_mensaje,
            usuario_id,
            usuario:usuarios (
              id,
              nombre
            )
          ''')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_mensaje', ascending: true);

      setState(() {
        _reclamo = Map<String, dynamic>.from(reclamoData);
        _mensajes = List<Map<String, dynamic>>.from(mensajesData);
      });

      await _loadAdjuntosSolo();

      _scrollToBottom();
    } on PostgrestException catch (e, st) {
      debugPrint(
        'Postgrest error en _loadAll para reclamo ${widget.reclamoId}: '
        '${e.message} (${e.code})\n$st',
      );
      setState(() {
        _error = 'Error de datos al cargar el reclamo: ${e.message}';
      });
    } catch (e, st) {
      debugPrint(
        'Error inesperado en _loadAll para reclamo ${widget.reclamoId}: '
        '$e\n$st',
      );
      setState(() {
        _error = 'Error al cargar el reclamo. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMensajesSolo() async {
    try {
      final supabase = Supabase.instance.client;

      final mensajesData = await supabase
          .from('reclamo_mensajes')
          .select('''
            id,
            texto,
            fecha_mensaje,
            usuario_id,
            usuario:usuarios (
              id,
              nombre
            )
          ''')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_mensaje', ascending: true);

      setState(() {
        _mensajes = List<Map<String, dynamic>>.from(mensajesData);
      });

      _scrollToBottom();
    } catch (e, st) {
      debugPrint(
        'Error al recargar mensajes de reclamo ${widget.reclamoId}: $e\n$st',
      );
    }
  }

  Future<void> _loadAdjuntosSolo() async {
    try {
      final supabase = Supabase.instance.client;

      final adjuntosData = await supabase
          .from('reclamo_adjuntos')
          .select('*')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_subida', ascending: true);

      setState(() {
        _adjuntos = List<Map<String, dynamic>>.from(adjuntosData);
      });
    } on PostgrestException catch (e, st) {
      debugPrint(
        'Postgrest error al cargar adjuntos de reclamo ${widget.reclamoId}: '
        '${e.message} (${e.code})\n$st',
      );
    } catch (e, st) {
      debugPrint(
        'Error inesperado al cargar adjuntos de reclamo ${widget.reclamoId}: '
        '$e\n$st',
      );
    }
  }

  String _guessMimeType(String fileName) {
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

  Future<void> _uploadAttachment({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (!mounted) return;

    setState(() => _subiendoAdjunto = true);

    try {
      final supabase = Supabase.instance.client;

      final cleanName = fileName.replaceAll(' ', '_');
      final path = '${widget.reclamoId}/$cleanName';
      final resolvedMime = _guessMimeType(cleanName);

      await supabase.storage
          .from('reclamos')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: resolvedMime),
          );

      await supabase.from('reclamo_adjuntos').insert({
        'reclamo_id': widget.reclamoId,
        'archivo_nombre': fileName,
        'mime_type': resolvedMime,
        'storage_path': path,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunto subido correctamente.')),
      );
    } catch (e, st) {
      debugPrint(
        'Error al subir adjunto en reclamo ${widget.reclamoId}: $e\n$st',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el adjunto')),
      );
    } finally {
      if (mounted) {
        setState(() => _subiendoAdjunto = false);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (_subiendoAdjunto) return;
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    await _uploadAttachment(
      bytes: bytes,
      fileName: xfile.name,
      mimeType: 'image/jpeg',
    );
  }

  Future<void> _pickFromGallery() async {
    if (_subiendoAdjunto) return;
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    await _uploadAttachment(
      bytes: bytes,
      fileName: xfile.name,
      mimeType: _guessMimeType(xfile.name),
    );
  }

  Future<void> _pickFile() async {
    if (_subiendoAdjunto) return;

    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    const maxSizeBytes = 5 * 1024 * 1024;
    if (file.size > maxSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El archivo es muy grande (max. 5 MB).')),
      );
      return;
    }

    await _uploadAttachment(
      bytes: file.bytes!,
      fileName: file.name,
      mimeType: _guessMimeType(file.name),
    );
  }

  bool _puedeEliminarMensaje(DateTime? fecha) {
    if (fecha == null) return false;
    final ahora = DateTime.now().toUtc();
    final base = fecha.isUtc ? fecha : fecha.toUtc();
    final diff = ahora.difference(base);
    return diff.inMinutes <= 10;
  }

  Future<void> _onLongPressMensaje(
    Map<String, dynamic> mensaje,
    bool esMio,
  ) async {
    if (!esMio) return;

    final fechaRaw = mensaje['fecha_mensaje'];
    final fecha = DateTime.tryParse(fechaRaw?.toString() ?? '');
    if (!_puedeEliminarMensaje(fecha)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo podes borrar mensajes de los ultimos 10 minutos.',
          ),
        ),
      );
      return;
    }

    final confirmar =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar mensaje'),
            content: const Text(
              'Queres eliminar este mensaje del expediente del reclamo?\n'
              'Solo se pueden borrar mensajes recientes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('reclamo_mensajes')
          .delete()
          .eq('id', mensaje['id'] as String);

      await _loadMensajesSolo();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mensaje eliminado.')));
    } catch (e, st) {
      debugPrint(
        'Error al eliminar mensaje de reclamo ${widget.reclamoId}: $e\n$st',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el mensaje.')),
      );
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _enviando = true;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('reclamo_mensajes').insert({
        'reclamo_id': widget.reclamoId,
        'usuario_id': user.id,
        'texto': texto,
      });

      _mensajeController.clear();
      await _loadMensajesSolo();
    } catch (e, st) {
      debugPrint(
        'Error al enviar mensaje en reclamo ${widget.reclamoId}: $e\n$st',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    if (_reclamo == null) return;
    final estadoActual = _reclamo!['estado']?.toString();
    if (estadoActual == nuevoEstado) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _cambiandoEstado = true;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('reclamos')
          .update({'estado': nuevoEstado})
          .eq('id', widget.reclamoId);

      await supabase.from('reclamo_mensajes').insert({
        'reclamo_id': widget.reclamoId,
        'usuario_id': user.id,
        'texto': 'Estado cambiado a $nuevoEstado por Administrador.',
      });

      setState(() {
        _reclamo!['estado'] = nuevoEstado;
      });

      await _loadMensajesSolo();
    } catch (e, st) {
      debugPrint(
        'Error al cambiar estado del reclamo ${widget.reclamoId}: $e\n$st',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cambiar el estado.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cambiandoEstado = false;
        });
      }
    }
  }

  Future<void> _showAdjuntosOptions() async {
    if (_subiendoAdjunto) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Sacar foto'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Elegir de galeria'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Adjuntar archivo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAdjuntosScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReclamoAdjuntosScreen(reclamoId: widget.reclamoId),
      ),
    );
  }

  String _buildEmisorLabelForPdf(
    Map<String, dynamic> mensaje,
    Map<String, dynamic> usuario,
    UsuarioContexto contexto,
    String unidadCodigo,
  ) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final esMio = mensaje['usuario_id'] == currentUserId;
    final soyAdmin = contexto.rol == 'ADMIN_CONSORCIO';

    final nombre = (usuario['nombre'] ?? '').toString().trim();
    final nombreLabel = nombre.isEmpty ? 'Usuario' : nombre;

    if (soyAdmin) {
      if (esMio) {
        return 'Administrador - $nombreLabel';
      } else {
        final unidadText = unidadCodigo.isEmpty ? '' : 'Unidad $unidadCodigo';
        if (unidadText.isEmpty) {
          return 'Propietario / Morador - $nombreLabel';
        }
        return '$nombreLabel - $unidadText';
      }
    } else {
      if (esMio) {
        final rolLabel = contexto.rolLegible;
        final unidadText = unidadCodigo.isEmpty ? '' : 'Unidad $unidadCodigo';
        final partes = <String>[rolLabel, nombreLabel];
        if (unidadText.isNotEmpty) {
          partes.add(unidadText);
        }
        return partes.join(' - ');
      } else {
        return 'Administrador - $nombreLabel';
      }
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    final contexto = context.read<CurrentContextNotifier>().current;
    if (_reclamo == null || contexto == null) {
      return Uint8List(0);
    }

    final doc = pw.Document();
    final estadoActual = _reclamo!['estado']?.toString() ?? 'PENDIENTE';
    final estadoLabel = formatEnumLabel(estadoActual);
    final prioridadLabel = formatEnumLabel(
      _reclamo!['prioridad']?.toString() ?? '',
    );
    final unidadCodigo = (_reclamo!['unidad']?['codigo'] ?? '')
        .toString()
        .trim();
    final descripcion = (_reclamo!['descripcion'] ?? '').toString().trim();

    final mensajesRows = <List<String>>[];
    final participantes = <String>{};

    for (final m in _mensajes) {
      final fecha = formatShortDateFromIso(m['fecha_mensaje']);
      final usuarioMap =
          (m['usuario'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final emisor = _buildEmisorLabelForPdf(
        m,
        usuarioMap,
        contexto,
        unidadCodigo,
      );
      final texto = (m['texto'] ?? '').toString();

      participantes.add(emisor);
      mensajesRows.add([fecha, emisor, texto]);
    }

    pw.TableRow infoRow(String label, String value) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(value),
          ),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pdfContext) => [
          pw.Text(
            'Expediente de reclamo',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(120),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              infoRow('Consorcio', contexto.consorcioNombre),
              infoRow(
                'Unidad',
                unidadCodigo.isEmpty ? '-' : 'Unidad $unidadCodigo',
              ),
              infoRow('Titulo', _reclamo!['titulo']?.toString() ?? ''),
              infoRow('Tipo', _reclamo!['tipo']?.toString() ?? ''),
              infoRow('Estado', estadoLabel),
              infoRow('Prioridad', prioridadLabel),
              infoRow(
                'Fecha emision',
                formatShortDateFromIso(DateTime.now().toIso8601String()),
              ),
            ],
          ),
          if (descripcion.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Descripcion inicial:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(descripcion),
          ],
          if (participantes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Participantes del reclamo',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            for (final p in participantes) pw.Bullet(text: p),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            'Conversacion del reclamo',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (mensajesRows.isEmpty)
            pw.Text('No hay mensajes registrados para este reclamo.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Fecha', 'Emisor', 'Mensaje'],
              data: mensajesRows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE0E0E0),
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.topLeft,
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FixedColumnWidth(130),
                2: const pw.FlexColumnWidth(),
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _exportPdf() async {
    final contexto = context.read<CurrentContextNotifier>().current;
    final unidadCodigo = (_reclamo?['unidad']?['codigo'] ?? '')
        .toString()
        .trim();
    final bytes = await _buildPdfBytes();
    if (!mounted) return;
    if (bytes.isEmpty) return;

    final safeUnidad = unidadCodigo.isEmpty ? 'sin_unidad' : unidadCodigo;
    final fileName =
        'reclamo_${contexto?.consorcioNombre ?? 'consorcio'}_$safeUnidad.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final contexto = context.watch<CurrentContextNotifier>().current;
    final esAdmin = contexto?.rol == 'ADMIN_CONSORCIO';

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del reclamo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (_reclamo == null) {
      return const Scaffold(body: Center(child: Text('Reclamo no encontrado')));
    }

    final estadoActual = _reclamo!['estado']?.toString() ?? 'PENDIENTE';
    final estadoLabel = formatEnumLabel(estadoActual);
    final unidadCodigo = (_reclamo!['unidad']?['codigo'] ?? '')
        .toString()
        .trim();
    final descripcion = (_reclamo!['descripcion'] ?? '').toString();
    final prioridadLabel = formatEnumLabel(
      _reclamo!['prioridad']?.toString() ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del reclamo'),
        actions: [
          IconButton(
            tooltip: 'Exportar expediente en PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reclamo!['titulo']?.toString() ?? '(Sin titulo)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (_reclamo!['tipo'] != null)
                    Text(
                      'Tipo: ${_reclamo!['tipo']}',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (unidadCodigo.isNotEmpty)
                              Chip(
                                label: Text('Unidad $unidadCodigo'),
                                visualDensity: VisualDensity.compact,
                              ),
                            Chip(
                              label: Text('Prioridad: $prioridadLabel'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (esAdmin)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Estado:', style: theme.textTheme.bodySmall),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: estadoActual,
                              underline: const SizedBox.shrink(),
                              items: _estadosPosibles
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(formatEnumLabel(e)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _cambiandoEstado
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _cambiarEstado(value);
                                      }
                                    },
                            ),
                            if (_cambiandoEstado) ...[
                              const SizedBox(width: 4),
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Chip(
                          label: Text('Estado: $estadoLabel'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (descripcion.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        descripcion,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _adjuntos.isEmpty ? null : _openAdjuntosScreen,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text('Adjuntos (${_adjuntos.length})'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final m = _mensajes[index];
                final esMio = m['usuario_id'] == userId;

                final fechaStr = formatShortDateFromIso(m['fecha_mensaje']);

                final usuarioMap =
                    (m['usuario'] as Map<String, dynamic>?) ?? {};
                final nombreOtro = (usuarioMap['nombre'] ?? '')
                    .toString()
                    .trim();

                String etiqueta;
                if (esMio) {
                  final partes = <String>['Yo'];
                  if (contexto?.consorcioNombre != null) {
                    partes.add(contexto!.consorcioNombre);
                  }
                  partes.add(fechaStr);
                  etiqueta = partes.join(' - ');
                } else {
                  final partes = <String>[];
                  if (unidadCodigo.isNotEmpty) {
                    partes.add('Unidad $unidadCodigo');
                  }
                  if (nombreOtro.isNotEmpty) {
                    partes.add(nombreOtro);
                  } else {
                    partes.add('Vecino');
                  }
                  partes.add(fechaStr);
                  etiqueta = partes.join(' - ');
                }

                return Align(
                  alignment: esMio
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: InkWell(
                    onLongPress: () => _onLongPressMensaje(m, esMio),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: esMio
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['texto']?.toString() ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            etiqueta,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Adjuntar archivo',
                    icon: _subiendoAdjunto
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file),
                    onPressed: _subiendoAdjunto ? null : _showAdjuntosOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _mensajeController,
                      decoration: const InputDecoration(
                        hintText: 'Escribi un mensaje...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        _enviando || _mensajeController.text.trim().isEmpty
                        ? null
                        : _enviarMensaje,
                    icon: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
