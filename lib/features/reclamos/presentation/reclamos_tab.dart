import 'dart:async';

import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'new_reclamo_screen.dart';
import 'reclamo_detail_screen.dart';
import 'reclamos_utils.dart';

/// Tab de Reclamos (lista + botón "Nuevo reclamo")
import 'package:consorcio_360/data/models/usuario_contexto.dart';

const String _prefHelpEnabledKey = 'ui_help_enabled';

class ReclamosTab extends StatefulWidget {
  final UsuarioContexto? contexto;

  const ReclamosTab({super.key, this.contexto});

  @override
  State<ReclamosTab> createState() => _ReclamosTabState();
}

class _ReclamosTabState extends State<ReclamosTab> {
  late Future<List<Map<String, dynamic>>> _futureReclamos;
  bool _helpEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHelpEnabled();
    _futureReclamos = _loadReclamos();
  }

  Future<void> _loadHelpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefHelpEnabledKey);
    if (!mounted || value == null) return;
    setState(() => _helpEnabled = value);
  }

  Future<List<Map<String, dynamic>>> _loadReclamos() async {
    final supabase = Supabase.instance.client;
    final contexto =
        widget.contexto ?? context.read<CurrentContextNotifier>().current;

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
      case 'EN CURSO':
        return Colors.blue;
      case 'EN ESPERA':
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
            child: _HelpListener(
              helpEnabled: _helpEnabled,
              helpText: 'Crear un nuevo reclamo.',
              child: FilledButton.icon(
                onPressed: _openNewReclamo,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo reclamo'),
              ),
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
                      child: _HelpableTile(
                        helpEnabled: _helpEnabled,
                        helpText: 'Abrir detalle del reclamo.',
                        onTap: () => _openDetalle(r),
                        child: ListTile(
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

class _HelpListener extends StatefulWidget {
  final bool helpEnabled;
  final String helpText;
  final Widget child;

  const _HelpListener({
    required this.helpEnabled,
    required this.helpText,
    required this.child,
  });

  @override
  State<_HelpListener> createState() => _HelpListenerState();
}

class _HelpListenerState extends State<_HelpListener> {
  Timer? _timer;

  void _startTimer() {
    if (!widget.helpEnabled || widget.helpText.trim().isEmpty) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(widget.helpText)),
      );
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _startTimer(),
      onPointerUp: (_) => _cancelTimer(),
      onPointerCancel: (_) => _cancelTimer(),
      child: widget.child,
    );
  }
}

class _HelpableTile extends StatefulWidget {
  final bool helpEnabled;
  final String helpText;
  final Widget child;
  final VoidCallback? onTap;

  const _HelpableTile({
    required this.helpEnabled,
    required this.helpText,
    required this.child,
    this.onTap,
  });

  @override
  State<_HelpableTile> createState() => _HelpableTileState();
}

class _HelpableTileState extends State<_HelpableTile> {
  Timer? _timer;
  bool _helpShown = false;

  void _startTimer() {
    if (!widget.helpEnabled || widget.helpText.trim().isEmpty) return;
    _timer?.cancel();
    _helpShown = false;
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _helpShown = true;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(widget.helpText)),
      );
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleTap() {
    _cancelTimer();
    if (_helpShown) {
      _helpShown = false;
      return;
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: (_) => _startTimer(),
        onTapCancel: _cancelTimer,
        onTap: widget.onTap == null ? null : _handleTap,
        child: widget.child,
      ),
    );
  }
}
