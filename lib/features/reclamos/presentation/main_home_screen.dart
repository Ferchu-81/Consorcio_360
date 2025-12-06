import 'dart:typed_data';

import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/auth/presentation/login_screen.dart';
import 'package:consorcio_360/features/context/presentation/context_selection_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// --------- Helpers generales ---------

String formatEnumLabel(String value) {
  if (value.isEmpty) return value;
  return value
      .split('_')
      .map((part) {
        if (part.isEmpty) return '';
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String formatShortDateFromIso(dynamic value) {
  if (value == null) return '';
  final str = value.toString();
  final dt = DateTime.tryParse(str);
  if (dt == null) {
    return str.split('T').first;
  }
  const meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final dia = dt.day.toString().padLeft(2, '0');
  final mes = meses[dt.month - 1];
  final anio = (dt.year % 100).toString().padLeft(2, '0');
  return '$dia $mes $anio';
}

/// --------- Home principal ---------

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _tituloSeccion() {
    switch (_selectedIndex) {
      case 0:
        return 'Reclamos';
      case 1:
        return 'Expensas';
      case 2:
        return 'Pagos / Tablero';
      default:
        return 'Consorcio 360';
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.read<CurrentContextNotifier>().clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar sesion'),
            content: const Text(
              'Queres cerrar la sesion actual?\n'
              'Vas a tener que ingresar de nuevo para continuar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar sesion'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;
    await _logout();
  }

  Future<void> _changeContext() async {
    context.read<CurrentContextNotifier>().clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ContextSelectionScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmChangeContext() async {
    final shouldChange =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambiar de rol / unidad'),
            content: const Text(
              'Queres cambiar de consorcio, unidad o rol?\n'
              'Se cerrara el contexto actual.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cambiar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldChange) return;

    await _changeContext();
  }

  void _openConsorcioReclamos() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ConsorcioReclamosScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<CurrentContextNotifier>();
    final contexto = current.current;

    if (contexto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consorcio 360')),
        body: const Center(
          child: Text(
            'No hay contexto seleccionado. Volve a la pantalla anterior.',
          ),
        ),
      );
    }

    Widget body;
    if (_selectedIndex == 0) {
      body = const ReclamosTab();
    } else if (_selectedIndex == 1) {
      body = const PlaceholderFeatureScreen(titulo: 'Expensas');
    } else {
      body = const PlaceholderFeatureScreen(titulo: 'Pagos / Tablero');
    }

    final tituloSeccion = _tituloSeccion();
    final bool esAdmin = contexto.rol == 'ADMIN_CONSORCIO';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8EE),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${contexto.consorcioNombre} – Unidad ${contexto.unidadCodigo}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(tituloSeccion, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ActionChip(
              label: Text(contexto.rolLegible),
              avatar: const Icon(Icons.person_outline, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: _confirmChangeContext,
            ),
          ),
          if (esAdmin && _selectedIndex == 0)
            IconButton(
              tooltip: 'Reclamos del consorcio',
              icon: const Icon(Icons.list_alt),
              onPressed: _openConsorcioReclamos,
            ),
          IconButton(
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.report_gmailerrorred_outlined),
            label: 'Reclamos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Expensas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Pagos',
          ),
        ],
      ),
    );
  }
}

/// --------- Tab de Reclamos ---------

class ReclamosTab extends StatefulWidget {
  const ReclamosTab({super.key});

  @override
  State<ReclamosTab> createState() => _ReclamosTabState();
}

class _ReclamosTabState extends State<ReclamosTab> {
  late Future<List<Map<String, dynamic>>> _futureReclamos;

  @override
  void initState() {
    super.initState();
    _futureReclamos = _loadReclamos();
  }

  Future<List<Map<String, dynamic>>> _loadReclamos() async {
    final supabase = Supabase.instance.client;
    final contexto = context.read<CurrentContextNotifier>().current;

    if (contexto == null) {
      throw Exception('No hay contexto seleccionado.');
    }

    final response = await supabase
        .from('reclamos')
        .select()
        .eq('unidad_id', contexto.unidadId)
        .order('fecha_creacion', ascending: false);

    final data = response as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _openNewReclamo() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const NewReclamoScreen()));

    if (!mounted) return;

    if (created == true) {
      setState(() {
        _futureReclamos = _loadReclamos();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclamo creado correctamente.')),
      );
    }
  }

  void _openDetalle(Map<String, dynamic> reclamo) {
    final id = reclamo['id'] as String;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReclamoDetailScreen(reclamoId: id)),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN_CURSO':
        return Colors.blue;
      case 'EN_ESPERA':
        return Colors.amber;
      case 'RESUELTO':
        return Colors.green;
      case 'CERRADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _prioridadColor(String prioridad) {
    switch (prioridad) {
      case 'ALTA':
        return Colors.red;
      case 'MEDIA':
        return Colors.orange;
      case 'BAJA':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openNewReclamo,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo reclamo'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureReclamos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Error al cargar reclamos. Intenta nuevamente.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _futureReclamos = _loadReclamos();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final reclamos = snapshot.data ?? [];

                if (reclamos.isEmpty) {
                  return Center(
                    child: Text(
                      'No tenes reclamos para esta unidad.\n'
                      'Crea tu primer reclamo con el boton de arriba.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reclamos.length,
                  itemBuilder: (context, index) {
                    final r = reclamos[index];
                    final fechaStr = formatShortDateFromIso(
                      r['fecha_creacion'],
                    );
                    final estado = (r['estado'] ?? '').toString();
                    final prioridad = (r['prioridad'] ?? '').toString();
                    final estadoLabel = formatEnumLabel(estado);
                    final prioridadLabel = formatEnumLabel(prioridad);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _openDetalle(r),
                        title: Text(
                          r['titulo']?.toString() ?? '(Sin titulo)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r['tipo'] != null) Text('Tipo: ${r['tipo']}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _estadoColor(
                                      estado,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    estadoLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _estadoColor(estado),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _prioridadColor(
                                      prioridad,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Prioridad: $prioridadLabel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _prioridadColor(prioridad),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Creado: $fechaStr',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// --------- Nuevo reclamo ---------

class NewReclamoScreen extends StatefulWidget {
  const NewReclamoScreen({super.key});

  @override
  State<NewReclamoScreen> createState() => _NewReclamoScreenState();
}

class _NewReclamoScreenState extends State<NewReclamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  String? _tipoSeleccionado;
  String _prioridadSeleccionada = 'MEDIA';
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _tipos = const [
    'Filtracion',
    'Ruidos',
    'Ascensor',
    'Limpieza',
    'Otros',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    final contexto = context.read<CurrentContextNotifier>().current;

    if (user == null || contexto == null) {
      setState(() {
        _errorMessage = 'Sesion o contexto no validos. Volve a iniciar sesion.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('reclamos').insert({
        'unidad_id': contexto.unidadId,
        'usuario_creador_id': user.id,
        'tipo': _tipoSeleccionado ?? 'Otros',
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        'prioridad': _prioridadSeleccionada,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Error al guardar el reclamo. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reclamo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de reclamo',
                    ),
                    items: _tipos
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    initialValue: _tipoSeleccionado,
                    onChanged: (value) {
                      setState(() {
                        _tipoSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Titulo / Asunto',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un titulo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripcion'),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    initialValue: _prioridadSeleccionada,
                    items: const [
                      DropdownMenuItem(value: 'BAJA', child: Text('Baja')),
                      DropdownMenuItem(value: 'MEDIA', child: Text('Media')),
                      DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _prioridadSeleccionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _guardar,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar reclamo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// --------- Detalle de reclamo + chat + adjuntos + PDF ---------

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

      // 1) Datos del reclamo + unidad
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

      // 2) Mensajes del reclamo
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

      // 3) Adjuntos (si falla NO rompemos la pantalla)
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

      // Llevar el scroll al último mensaje
      _scrollToBottom();
    } catch (e, st) {
      debugPrint(
        'Error al recargar mensajes de reclamo ${widget.reclamoId}: $e\n$st',
      );
      // No rompemos la pantalla si falla
    }
  }

  Future<void> _loadAdjuntosSolo() async {
    try {
      final supabase = Supabase.instance.client;

      // Usamos select('*') para que funcione aunque cambien
      // los nombres de columnas (archivo_nombre / url_archivo, etc.)
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
      // No tocamos _error para no tirar abajo la pantalla
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
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _subiendoAdjunto = true;
    });

    try {
      final sanitizedName = fileName.replaceAll(' ', '_');
      final path =
          'reclamos/${widget.reclamoId}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      await supabase.storage
          .from('reclamos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      await supabase.from('reclamo_adjuntos').insert({
        'reclamo_id': widget.reclamoId,
        'usuario_id': user.id,
        'archivo_nombre': fileName,
        'storage_path': path,
        'mime_type': mimeType,
      });

      await _loadAdjuntosSolo();
    } catch (e, st) {
      debugPrint(
        'Error al subir adjunto en reclamo ${widget.reclamoId}: $e\n$st',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo adjuntar el archivo.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _subiendoAdjunto = false;
        });
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (_subiendoAdjunto) return;
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
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
    final xfile = await _imagePicker.pickImage(source: ImageSource.gallery);
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

    await _uploadAttachment(
      bytes: file.bytes!,
      fileName: file.name,
      mimeType: _guessMimeType(file.name),
    );
  }

  Future<void> _openAdjunto(Map<String, dynamic> adj) async {
    final supabase = Supabase.instance.client;
    final path = adj['storage_path']?.toString() ?? '';
    if (path.isEmpty) return;

    try {
      final url = await supabase.storage
          .from('reclamos')
          .createSignedUrl(path, 60 * 60);

      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el archivo.')),
        );
      }
    } catch (e, st) {
      debugPrint(
        'Error al abrir adjunto de reclamo ${widget.reclamoId}: $e\n$st',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo.')),
      );
    }
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
        builder: (_) => ReclamoAdjuntosScreen(
          reclamoId: widget.reclamoId,
          onOpenAdjunto: _openAdjunto,
        ),
      ),
    );
  }

  /// --------- PDF ---------

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
        return 'Administrador – $nombreLabel';
      } else {
        final unidadText = unidadCodigo.isEmpty ? '' : 'Unidad $unidadCodigo';
        if (unidadText.isEmpty) {
          return 'Propietario / Morador – $nombreLabel';
        }
        return '$nombreLabel – $unidadText';
      }
    } else {
      if (esMio) {
        final rolLabel = contexto.rolLegible;
        final unidadText = unidadCodigo.isEmpty ? '' : 'Unidad $unidadCodigo';
        final partes = <String>[rolLabel, nombreLabel];
        if (unidadText.isNotEmpty) {
          partes.add(unidadText);
        }
        return partes.join(' – ');
      } else {
        return 'Administrador – $nombreLabel';
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

  /// --------- UI ---------

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
          // Encabezado mas compacto
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
                  const SizedBox(height: 4),
                  // Prioridad
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(
                          'Prioridad: '
                          '${formatEnumLabel(_reclamo!['prioridad']?.toString() ?? '')}',
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Unidad + Estado en una sola linea
                  Row(
                    children: [
                      if (unidadCodigo.isNotEmpty)
                        Chip(
                          label: Text('Unidad $unidadCodigo'),
                          visualDensity: VisualDensity.compact,
                        ),
                      const SizedBox(width: 8),
                      if (esAdmin)
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Estado: ',
                                style: theme.textTheme.bodySmall,
                              ),
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
                          ),
                        )
                      else
                        Chip(
                          label: Text('Estado: $estadoLabel'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (_reclamo!['descripcion'] != null &&
                      (_reclamo!['descripcion'] as String).trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        _reclamo!['descripcion'] as String,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  // boton pequeño de adjuntos
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

          // Mensajes
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
                  etiqueta = partes.join(' · ');
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
                  etiqueta = partes.join(' · ');
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

          // Input para nuevo mensaje
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

/// --------- Pantalla de adjuntos (lista con miniaturas) ---------

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
      final url = await supabase.storage
          .from('reclamos')
          .createSignedUrl(path, 60 * 60);
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
              separatorBuilder: (context, _) => const Divider(height: 1),
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
                      if (snapshot.connectionState == ConnectionState.waiting ||
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

/// --------- Reclamos del consorcio (vista admin) ---------

class ConsorcioReclamosScreen extends StatefulWidget {
  const ConsorcioReclamosScreen({super.key});

  @override
  State<ConsorcioReclamosScreen> createState() =>
      _ConsorcioReclamosScreenState();
}

class _ConsorcioReclamosScreenState extends State<ConsorcioReclamosScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reclamos = [];

  String _estadoFiltro = 'TODOS';
  String _prioridadFiltro = 'TODAS';
  String _unidadFiltroTexto = '';

  final List<String> _estadosFiltro = const [
    'TODOS',
    'PENDIENTE',
    'EN_CURSO',
    'EN_ESPERA',
    'RESUELTO',
    'CERRADO',
  ];

  final List<String> _prioridadesFiltro = const [
    'TODAS',
    'BAJA',
    'MEDIA',
    'ALTA',
  ];

  @override
  void initState() {
    super.initState();
    _loadReclamosConsorcio();
  }

  Future<void> _loadReclamosConsorcio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final contexto = context.read<CurrentContextNotifier>().current;

      if (contexto == null) {
        throw Exception('No hay contexto seleccionado.');
      }

      if (contexto.rol != 'ADMIN_CONSORCIO') {
        throw Exception(
          'Solo un administrador de consorcio puede ver esta vista.',
        );
      }

      final response = await supabase
          .from('reclamos')
          .select('''
            id,
            titulo,
            tipo,
            estado,
            prioridad,
            fecha_creacion,
            unidad:unidades!inner (
              id,
              codigo,
              consorcio_id
            ),
            usuario:usuarios (
              id,
              nombre,
              email
            )
          ''')
          .eq('unidad.consorcio_id', contexto.consorcioId)
          .order('fecha_creacion', ascending: false);

      final data = response as List<dynamic>;
      setState(() {
        _reclamos = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar reclamos del consorcio: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _reclamosFiltrados {
    return _reclamos.where((r) {
      final estado = (r['estado'] ?? '').toString();
      final prioridad = (r['prioridad'] ?? '').toString();
      final unidad = (r['unidad']?['codigo'] ?? '').toString().toLowerCase();

      if (_estadoFiltro != 'TODOS' && estado != _estadoFiltro) {
        return false;
      }

      if (_prioridadFiltro != 'TODAS' && prioridad != _prioridadFiltro) {
        return false;
      }

      if (_unidadFiltroTexto.trim().isNotEmpty) {
        final filtro = _unidadFiltroTexto.trim().toLowerCase();
        if (!unidad.contains(filtro)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _openDetalle(Map<String, dynamic> reclamo) {
    final id = reclamo['id'] as String;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReclamoDetailScreen(reclamoId: id)),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN_CURSO':
        return Colors.blue;
      case 'EN_ESPERA':
        return Colors.amber;
      case 'RESUELTO':
        return Colors.green;
      case 'CERRADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _prioridadColor(String prioridad) {
    switch (prioridad) {
      case 'ALTA':
        return Colors.red;
      case 'MEDIA':
        return Colors.orange;
      case 'BAJA':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contexto = context.watch<CurrentContextNotifier>().current;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          contexto == null
              ? 'Reclamos del consorcio'
              : 'Reclamos – ${contexto.consorcioNombre}',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadReclamosConsorcio,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Filtros
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                              ),
                              initialValue: _estadoFiltro,
                              items: _estadosFiltro
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e == 'TODOS'
                                            ? 'Todos'
                                            : formatEnumLabel(e),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _estadoFiltro = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Prioridad',
                              ),
                              initialValue: _prioridadFiltro,
                              items: _prioridadesFiltro
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e == 'TODAS'
                                            ? 'Todas'
                                            : formatEnumLabel(e),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _prioridadFiltro = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por unidad (ej: 3B)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _unidadFiltroTexto = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _reclamosFiltrados.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No hay reclamos para el consorcio con los filtros actuales.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _reclamosFiltrados.length,
                          itemBuilder: (context, index) {
                            final r = _reclamosFiltrados[index];
                            final unidadCodigo = (r['unidad']?['codigo'] ?? '')
                                .toString();
                            final creadorNombre =
                                (r['usuario']?['nombre'] ?? '').toString();
                            final creadorEmail = (r['usuario']?['email'] ?? '')
                                .toString();
                            final creadorLabel = creadorNombre.isNotEmpty
                                ? creadorNombre
                                : creadorEmail;
                            final fechaStr = formatShortDateFromIso(
                              r['fecha_creacion'],
                            );
                            final estado = (r['estado'] ?? '').toString();
                            final prioridad = (r['prioridad'] ?? '').toString();
                            final estadoLabel = formatEnumLabel(estado);
                            final prioridadLabel = formatEnumLabel(prioridad);

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                onTap: () => _openDetalle(r),
                                title: Text(
                                  r['titulo']?.toString() ?? '(Sin titulo)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unidad $unidadCodigo · $creadorLabel',
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _estadoColor(
                                              estado,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            estadoLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _estadoColor(estado),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _prioridadColor(
                                              prioridad,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'Prioridad: $prioridadLabel',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _prioridadColor(prioridad),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fecha: $fechaStr',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// --------- Placeholder Expensas / Pagos ---------

class PlaceholderFeatureScreen extends StatelessWidget {
  final String titulo;

  const PlaceholderFeatureScreen({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(titulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Esta seccion aun no esta disponible en esta version.\n'
              'Forma parte del alcance futuro del proyecto.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
