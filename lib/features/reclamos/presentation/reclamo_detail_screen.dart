import 'dart:typed_data';

import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamo_adjuntos_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/reclamos_utils.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:consorcio_360/shared/pdf/pdf_actions.dart';
import 'package:consorcio_360/shared/pdf/pdf_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ReclamoEmptyHint extends StatelessWidget {
  const _ReclamoEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '\u00bfC\u00f3mo funciona este reclamo?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Us\u00e1 este espacio como un chat para comunicarte con la administraci\u00f3n. Cada mensaje queda registrado como parte del expediente del reclamo y no se puede editar ni borrar.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pod\u00e9s adjuntar fotos, describir mejor el problema y hacer seguimiento '
                'de las respuestas.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

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

  String _formatFechaHora(dynamic value) {
    final fecha = formatShortDateFromIso(value);
    if (value == null) return fecha;
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return fecha;
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$fecha $hh:$mm';
  }

  String _formatTipoAdjunto(dynamic value, AppLocalizations l10n) {
    final tipo = value?.toString().toLowerCase().trim() ?? '';
    switch (tipo) {
      case 'pdf':
        return l10n.reclamoAdjuntoTipoPdf;
      case 'imagen':
      case 'image':
        return l10n.reclamoAdjuntoTipoImagen;
      case 'jpg':
      case 'jpeg':
        return 'JPG';
      case 'png':
        return 'PNG';
      case 'gif':
        return 'GIF';
      default:
        return tipo.isEmpty ? l10n.reclamoAdjuntoTipoDesconocido : tipo;
    }
  }

  String _formatTipoAdjuntoPorNombre(
    String? fileName,
    String? mimeType,
    AppLocalizations l10n,
  ) {
    final name = (fileName ?? '').toLowerCase().trim();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'JPG';
    if (name.endsWith('.png')) return 'PNG';
    if (name.endsWith('.gif')) return 'GIF';
    if (name.endsWith('.pdf')) return 'PDF';
    if (mimeType == null) return l10n.reclamoAdjuntoTipoDesconocido;
    return _formatTipoAdjunto(mimeType, l10n);
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final contexto = context.read<CurrentContextNotifier>().current;

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
              id,
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

      final reclamoMap = Map<String, dynamic>.from(reclamoData);
      final consorcioId = contexto?.consorcioId ?? '';

      final unidadDelReclamo = (reclamoMap['unidad']?['id'] ?? '')
          .toString()
          .trim();
      final unidadId = unidadDelReclamo.isNotEmpty
          ? unidadDelReclamo
          : (contexto?.unidadId ?? '');

      final mensajesData = await supabase
          .from('reclamo_mensajes')
          .select('''
            id,
            texto,
            fecha_mensaje,
            usuario_id,
            usuario:usuarios (
              id,
              nombre,
              apellido
            )
          ''')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_mensaje', ascending: true);

      final mensajes = List<Map<String, dynamic>>.from(mensajesData);
      final userIds = mensajes
          .map((m) => m['usuario_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final rolPorUsuarioId = <String, String>{};

      if (userIds.isNotEmpty && consorcioId.isNotEmpty && unidadId.isNotEmpty) {
        final uuRows = await supabase
            .from('v_usuarios_unidades')
            .select('usuario_id, rol')
            .eq('consorcio_id', consorcioId)
            .eq('unidad_id', unidadId)
            .inFilter('usuario_id', userIds);

        for (final row in (uuRows as List)) {
          final map = row as Map<String, dynamic>;
          final userId = map['usuario_id']?.toString();
          final rol = map['rol']?.toString();
          if (userId != null && rol != null) {
            rolPorUsuarioId[userId] = rol;
          }
        }
      }

      final mensajesConRol = mensajes.map((m) {
        final uid = m['usuario_id']?.toString();
        final rol = uid == null ? null : rolPorUsuarioId[uid];
        return {...m, 'autor_rol': rol};
      }).toList();

      setState(() {
        _reclamo = reclamoMap;
        _mensajes = mensajesConRol;
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
      final contexto = context.read<CurrentContextNotifier>().current;
      final consorcioId = contexto?.consorcioId ?? '';

      // La unidad del reclamo manda. Si no estÃ¡, fallback al contexto.
      final unidadDelReclamo = (_reclamo?['unidad']?['id'] ?? '')
          .toString()
          .trim();
      final unidadId = unidadDelReclamo.isNotEmpty
          ? unidadDelReclamo
          : (contexto?.unidadId ?? '');

      final mensajesData = await supabase
          .from('reclamo_mensajes')
          .select('''
            id,
            texto,
            fecha_mensaje,
            usuario_id,
            usuario:usuarios (
              id,
              nombre,
              apellido
            )
          ''')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_mensaje', ascending: true);

      final mensajes = List<Map<String, dynamic>>.from(mensajesData);
      final userIds = mensajes
          .map((m) => m['usuario_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final rolPorUsuarioId = <String, String>{};

      if (userIds.isNotEmpty && consorcioId.isNotEmpty && unidadId.isNotEmpty) {
        final uuRows = await supabase
            .from('v_usuarios_unidades')
            .select('usuario_id, rol')
            .eq('consorcio_id', consorcioId)
            .eq('unidad_id', unidadId)
            .inFilter('usuario_id', userIds);

        for (final row in (uuRows as List)) {
          final map = row as Map<String, dynamic>;
          final userId = map['usuario_id']?.toString();
          final rol = map['rol']?.toString();
          if (userId != null && rol != null) {
            rolPorUsuarioId[userId] = rol;
          }
        }
      }

      final mensajesConRol = mensajes.map((m) {
        final uid = m['usuario_id']?.toString();
        final rol = uid == null ? null : rolPorUsuarioId[uid];
        return {...m, 'autor_rol': rol};
      }).toList();

      setState(() {
        _mensajes = mensajesConRol;
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

      final contexto = context.read<CurrentContextNotifier>().current;
      final consorcioId = contexto?.consorcioId ?? '';
      final unidadDelReclamo = (_reclamo?['unidad']?['id'] ?? '')
          .toString()
          .trim();
      final unidadId = unidadDelReclamo.isNotEmpty
          ? unidadDelReclamo
          : (contexto?.unidadId ?? '');

      final adjuntosData = await supabase
          .from('reclamo_adjuntos')
          .select('*')
          .eq('reclamo_id', widget.reclamoId)
          .order('fecha_subida', ascending: true);

      final adjuntosList = List<Map<String, dynamic>>.from(adjuntosData);
      final userIds = adjuntosList
          .map((a) => a['usuario_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final nombrePorUsuarioId = <String, String>{};
      if (userIds.isNotEmpty) {
        final usuariosData = await supabase
            .from('usuarios')
            .select('id, nombre, apellido')
            .inFilter('id', userIds);

        for (final row in (usuariosData as List)) {
          final map = row as Map<String, dynamic>;
          final userId = map['id']?.toString();
          final nombre = (map['nombre'] ?? '').toString().trim();
          final apellido = (map['apellido'] ?? '').toString().trim();
          final nombreCompleto = [nombre, apellido]
              .where((value) => value.isNotEmpty)
              .join(' ');
          if (userId != null && nombreCompleto.isNotEmpty) {
            nombrePorUsuarioId[userId] = nombreCompleto;
          }
        }
      }

      final rolPorUsuarioId = <String, String>{};
      if (userIds.isNotEmpty && consorcioId.isNotEmpty && unidadId.isNotEmpty) {
        final uuRows = await supabase
            .from('v_usuarios_unidades')
            .select('usuario_id, rol')
            .eq('consorcio_id', consorcioId)
            .eq('unidad_id', unidadId)
            .inFilter('usuario_id', userIds);

        for (final row in (uuRows as List)) {
          final map = row as Map<String, dynamic>;
          final userId = map['usuario_id']?.toString();
          final rol = map['rol']?.toString();
          if (userId != null && rol != null) {
            rolPorUsuarioId[userId] = rol;
          }
        }
      }

      final adjuntosConAutor = adjuntosList.map((a) {
        final userId = a['usuario_id']?.toString();
        final autorNombre = userId == null ? null : nombrePorUsuarioId[userId];
        final autorRol = userId == null ? null : rolPorUsuarioId[userId];

        return {
          ...a,
          'autor_nombre': autorNombre,
          'autor_rol': autorRol,
        };
      }).toList();

      setState(() {
        _adjuntos = adjuntosConAutor;
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
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final cleanName = fileName.replaceAll(' ', '_');
      final path = '${widget.reclamoId}/$cleanName';
      final resolvedMime = _guessMimeType(cleanName);
      final isPdf = resolvedMime == 'application/pdf';

      await supabase.storage
          .from('reclamos')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: resolvedMime),
          );

      final insertData = {
        'reclamo_id': widget.reclamoId,
        'usuario_id': userId,
        'tipo_archivo': isPdf ? 'pdf' : 'imagen',
        'url_archivo': path,
        'archivo_nombre': fileName,
        'mime_type': resolvedMime,
        'storage_path': path,
      };

      await supabase.from('reclamo_adjuntos').insert(insertData);
      await _loadAdjuntosSolo();

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
    String nombreLabel,
    String? autorRol,
    String unidadCodigo,
    String consorcioNombre,
    AppLocalizations l10n, {
    bool includeLocation = true,
    bool includeAdminLocation = true,
  }) {
    final partes = <String>[];

    if (autorRol == null || autorRol == 'ADMIN_CONSORCIO') {
      partes.add(l10n.roleAdmin);
      if (nombreLabel.isNotEmpty) {
        partes.add(nombreLabel);
      }
      if (includeAdminLocation && consorcioNombre.isNotEmpty) {
        partes.add(consorcioNombre);
      }
      return partes.join(' - ');
    }

    final rolLabel = roleLabel(context, autorRol);
    if (rolLabel.isNotEmpty) {
      partes.add(rolLabel);
    }
    if (nombreLabel.isNotEmpty) {
      partes.add(nombreLabel);
    }
    if (includeLocation && unidadCodigo.isNotEmpty) {
      partes.add(unidadCodigo);
    }
    return partes.join(' - ');
  }

  Future<Uint8List> _buildPdfBytes() async {
    final contexto = context.read<CurrentContextNotifier>().current;
    if (_reclamo == null || contexto == null) {
      return Uint8List(0);
    }

    final l10n = AppLocalizations.of(context);
    final theme = await PdfThemeLoader.load();
    final doc = pw.Document(theme: theme);
    final estadoActualRaw = _reclamo!['estado']?.toString() ?? 'PENDIENTE';
    final estadoActual = estadoActualRaw.trim().toUpperCase().replaceAll(
      ' ',
      '_',
    );
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
    final consorcioNombre = contexto.consorcioNombre.toString().trim();

    for (final m in _mensajes) {
      final fecha = _formatFechaHora(m['fecha_mensaje']);
      final usuarioMap =
          (m['usuario'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final nombre = (usuarioMap['nombre'] ?? '').toString().trim();
      final apellido = (usuarioMap['apellido'] ?? '').toString().trim();
      final nombreCompleto = [nombre, apellido]
          .where((value) => value.isNotEmpty)
          .join(' ');
      final nombreLabel =
          nombreCompleto.isEmpty ? l10n.genericUser : nombreCompleto;

      String? autorRol;
      final autorRolRaw = m['autor_rol'];
      if (autorRolRaw != null) {
        autorRol = autorRolRaw.toString();
      }
      if (autorRol != null && autorRol.trim().isEmpty) {
        autorRol = null;
      }

      final emisor = _buildEmisorLabelForPdf(
        nombreLabel,
        autorRol,
        unidadCodigo,
        consorcioNombre,
        l10n,
        includeLocation: false,
        includeAdminLocation: false,
      );
      final participante = _buildEmisorLabelForPdf(
        nombreLabel,
        autorRol,
        unidadCodigo,
        consorcioNombre,
        l10n,
        includeAdminLocation: false,
      );
      final texto = (m['texto'] ?? '').toString();

      participantes.add(participante);
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
            l10n.reclamoPdfTitle,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(120),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              infoRow(l10n.reclamoPdfConsorcio, contexto.consorcioNombre),
              infoRow(
                l10n.reclamoPdfUnidad,
                unidadCodigo.isEmpty ? '-' : unidadCodigo,
              ),
              infoRow(
                l10n.reclamoPdfTitulo,
                _reclamo!['titulo']?.toString() ?? '',
              ),
              infoRow(l10n.reclamoPdfTipo, _reclamo!['tipo']?.toString() ?? ''),
              infoRow(l10n.reclamoPdfEstado, estadoLabel),
              infoRow(l10n.reclamoPdfPrioridad, prioridadLabel),
              infoRow(
                l10n.reclamoPdfFechaEmision,
                _formatFechaHora(DateTime.now().toIso8601String()),
              ),
            ],
          ),
          if (descripcion.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              l10n.reclamoPdfDescripcionInicial,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(descripcion),
          ],
          if (participantes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.reclamoPdfParticipantes,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            for (final p in participantes) pw.Bullet(text: p),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.reclamoPdfConversacion,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (mensajesRows.isEmpty)
            pw.Text(l10n.reclamoPdfMensajesVacios)
          else
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.reclamoPdfColFechaHora,
                l10n.reclamoPdfColEmisor,
                l10n.reclamoPdfColMensaje,
              ],
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
          if (_adjuntos.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.reclamoPdfAdjuntosTitulo,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.reclamoPdfAdjuntosColNumero,
                l10n.reclamoPdfAdjuntosColAutor,
                l10n.reclamoPdfAdjuntosColTipo,
                l10n.reclamoPdfAdjuntosColNombre,
              ],
              data: _adjuntos.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final a = entry.value;
                final autorRol = a['autor_rol']?.toString();
                final autorNombre = (a['autor_nombre'] ?? '').toString().trim();
                final nombreLabel = autorNombre.isEmpty
                    ? l10n.genericUser
                    : autorNombre;
                final autorLabel = _buildEmisorLabelForPdf(
                  nombreLabel,
                  autorRol,
                  unidadCodigo,
                  consorcioNombre,
                  l10n,
                  includeLocation: false,
                  includeAdminLocation: false,
                );
                final archivoNombre =
                    (a['archivo_nombre'] ?? a['url_archivo'] ?? '').toString();
                final tipoLabel = _formatTipoAdjuntoPorNombre(
                  archivoNombre,
                  a['mime_type']?.toString(),
                  l10n,
                );
                return [index.toString(), autorLabel, tipoLabel, archivoNombre];
              }).toList(),
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
                0: const pw.FixedColumnWidth(30),
                1: const pw.FixedColumnWidth(150),
                2: const pw.FixedColumnWidth(60),
                3: const pw.FlexColumnWidth(),
              },
            ),
          ],
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
    final safeUnidad = unidadCodigo.isEmpty ? 'sin_unidad' : unidadCodigo;
    final fileName =
        'reclamo_${contexto?.consorcioNombre ?? 'consorcio'}_$safeUnidad.pdf';

    await showPdfOptionsBottomSheet(
      context: context,
      title: 'Expediente del reclamo',
      fileName: fileName,
      buildPdf: (format) => _buildPdfBytes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final contexto = context.watch<CurrentContextNotifier>().current;
    final esAdmin = contexto?.rol == 'ADMIN_CONSORCIO';
    final estadosUnicos = _estadosPosibles.toSet().toList();

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
    final tipoRaw = (_reclamo!['tipo'] ?? '').toString().trim();
    final tipoLabel = tipoRaw.isEmpty ? '-' : formatEnumLabel(tipoRaw);
    final unidadLabel = unidadCodigo.isEmpty ? '-' : unidadCodigo;
    final prioridadValue = prioridadLabel.isEmpty ? '-' : prioridadLabel;

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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(label: 'Tipo', value: tipoLabel),
                      const SizedBox(width: 8),
                      _InfoChip(label: 'Unidad', value: unidadLabel),
                      const SizedBox(width: 8),
                      _InfoChip(label: 'Prioridad', value: prioridadValue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (esAdmin)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Estado:', style: theme.textTheme.bodySmall),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: estadosUnicos.contains(estadoActual)
                                  ? estadoActual
                                  : null,
                              underline: const SizedBox.shrink(),
                              items: estadosUnicos
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
                      TextButton.icon(
                        onPressed: _adjuntos.isEmpty
                            ? null
                            : _openAdjuntosScreen,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: Text('Adjuntos (${_adjuntos.length})'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
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
                ],
              ),
            ),
          ),
          Expanded(
            child: _mensajes.isEmpty
                ? const _ReclamoEmptyHint()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final m = _mensajes[index];
                      final esMio = m['usuario_id'] == userId;

                      final fechaHora = _formatFechaHora(m['fecha_mensaje']);

                      final usuarioMap =
                          (m['usuario'] as Map<String, dynamic>?) ??
                          <String, dynamic>{};
                      final nombreOtro = (usuarioMap['nombre'] ?? '')
                          .toString()
                          .trim();
                      final nombreLabel = nombreOtro.isEmpty
                          ? l10n.genericUser
                          : nombreOtro;

                      String? autorRol;
                      final autorRolRaw = m['autor_rol'];
                      if (autorRolRaw != null) {
                        autorRol = autorRolRaw.toString();
                      }
                      if (autorRol != null && autorRol.trim().isEmpty) {
                        autorRol = null;
                      }

                      final autorEsAdmin =
                          autorRol == 'ADMIN_CONSORCIO' || autorRol == null;

                      String etiqueta;
                      if (esMio) {
                        final miRolLabel = roleLabel(
                          context,
                          contexto?.rol ?? '',
                        );
                        final partes = <String>[l10n.selfLabel];
                        if (miRolLabel.isNotEmpty) {
                          partes.add(miRolLabel);
                        }
                        if (unidadCodigo.isNotEmpty) {
                          partes.add(unidadCodigo);
                        }
                        if (fechaHora.isNotEmpty) {
                          partes.add(fechaHora);
                        }
                        etiqueta = partes.join(' - ');
                      } else if (autorEsAdmin) {
                        final consorcioNombre =
                            contexto?.consorcioNombre.trim() ?? '';
                        final partes = <String>[l10n.roleAdmin, nombreLabel];
                        if (consorcioNombre.isNotEmpty) {
                          partes.add(consorcioNombre);
                        }
                        if (fechaHora.isNotEmpty) {
                          partes.add(fechaHora);
                        }
                        etiqueta = partes.join(' - ');
                      } else {
                        final rolAutorLabel = roleLabel(context, autorRol);
                        final partes = <String>[nombreLabel];
                        if (unidadCodigo.isNotEmpty) {
                          partes.add(unidadCodigo);
                        }
                        if (rolAutorLabel.isNotEmpty) {
                          partes.add(rolAutorLabel);
                        }
                        if (fechaHora.isNotEmpty) {
                          partes.add(fechaHora);
                        }
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
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: esMio
                                  ? const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.15)
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





