import 'dart:async';

import 'package:consorcio_360/core/i18n/role_label.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dashboard de inicio (morador / admin)
const String _prefHelpEnabledKey = 'ui_help_enabled';

class DashboardTab extends StatefulWidget {
  final UsuarioContexto contexto;

  const DashboardTab({
    super.key,
    required this.contexto,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String? _displayName;

  bool _loading = true;
  String? _error;

  // Métricas de expensas
  int _expensasPendientes = 0;
  int _expensasVencidas = 0;
  int _expensasPagadas = 0;

  // Métricas de reclamos
  int _reclamosActivos = 0;
  int _reclamosResueltos = 0;
  bool _helpEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHelpEnabled();
    _refresh();
  }

  Future<void> _loadHelpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefHelpEnabledKey);
    if (!mounted || value == null) return;
    setState(() => _helpEnabled = value);
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadNombreUsuario(),
        _loadResumenExpensas(),
        _loadResumenReclamos(),
      ]);
    } catch (e) {
      _error = 'Error al cargar datos: $e';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadNombreUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _displayName = 'Usuario';
      return;
    }

    final userId = user.id;

    // Intento leer nombre/apellido de la tabla usuarios
    final data = await Supabase.instance.client
        .from('usuarios')
        .select('nombre, apellido')
        .eq('id', userId)
        .maybeSingle();

    if (data != null) {
      final nombre = (data['nombre'] as String?)?.trim();
      final apellido = (data['apellido'] as String?)?.trim();

      if (nombre != null && nombre.isNotEmpty) {
        final partes = <String>[];
        partes.add(nombre);
        if (apellido != null && apellido.isNotEmpty) {
          partes.add(apellido);
        }
        _displayName = partes.join(' ');
        return;
      }
    }

    // Fallback: email del auth
    _displayName = user.email ?? 'Usuario';
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _loadResumenExpensas() async {
    final c = widget.contexto;
    final client = Supabase.instance.client;

    final hoy = DateTime.now();
    final hoyCorte = DateTime(hoy.year, hoy.month, hoy.day);
    final haceUnAnio = DateTime(hoy.year - 1, hoy.month, 1);
    final desdeStr = _formatDate(haceUnAnio);

    // Unidades a considerar:
    // - Admin: todas las unidades del consorcio excepto las con código GLOBAL
    // - Morador/propietario: solo su unidad
    final List<String> unidadesFiltrar = [];
    if (c.rol == 'ADMIN_CONSORCIO') {
      final unidades = await client
          .from('unidades')
          .select('id, codigo')
          .eq('consorcio_id', c.consorcioId);

      for (final u in unidades as List<dynamic>) {
        final map = u as Map<String, dynamic>;
        final codigo = map['codigo']?.toString() ?? '';
        if (codigo.toUpperCase() == 'GLOBAL') continue;
        final id = map['id']?.toString();
        if (id != null && id.isNotEmpty) {
          unidadesFiltrar.add(id);
        }
      }
    } else {
      unidadesFiltrar.add(c.unidadId);
    }

    // Fallback por si quedó vacío
    if (unidadesFiltrar.isEmpty) {
      unidadesFiltrar.add(c.unidadId);
    }

    var query = client
        .from('expensas')
        .select('estado, fecha_venc')
        .eq('consorcio_id', c.consorcioId)
        .gte('periodo', desdeStr);

    if (unidadesFiltrar.length == 1) {
      query = query.eq('unidad_id', unidadesFiltrar.first);
    } else if (unidadesFiltrar.isNotEmpty) {
      final orClause =
          unidadesFiltrar.map((id) => 'unidad_id.eq.$id').join(',');
      query = query.or(orClause);
    }

    final rows = await query;

    int pendientes = 0;
    int vencidas = 0;
    int pagadas = 0;

    for (final row in rows as List<dynamic>) {
      final data = row as Map<String, dynamic>;
      final estado = (data['estado'] as String?) ?? 'PENDIENTE';
      final fechaStr = data['fecha_venc'] as String?;
      final fechaVenc = fechaStr != null ? DateTime.tryParse(fechaStr) : null;

      if (estado == 'ANULADA') {
        continue;
      } else if (estado == 'PAGADA') {
        pagadas++;
      } else {
        final bool vencidaPorFecha =
            fechaVenc != null && fechaVenc.isBefore(hoyCorte);

        if (estado == 'VENCIDA' || vencidaPorFecha) {
          vencidas++;
        } else {
          pendientes++;
        }
      }
    }

    _expensasPendientes = pendientes;
    _expensasVencidas = vencidas;
    _expensasPagadas = pagadas;
  }

  Future<void> _loadResumenReclamos() async {
    final c = widget.contexto;
    final client = Supabase.instance.client;

    var query = client
        .from('reclamos')
        .select('estado')
        .eq('unidad_id', c.unidadId);

    final List<dynamic> rows = await query;

    const estadosNoActivos = ['RESUELTO', 'CERRADO', 'ANULADO'];

    int abiertos = 0;
    int resueltos = 0;

    for (final row in rows) {
      final estado = (row['estado'] as String?) ?? '';
      if (estadosNoActivos.contains(estado)) {
        resueltos++;
      } else {
        abiertos++;
      }
    }

    _reclamosActivos = abiertos;
    _reclamosResueltos = resueltos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = _displayName ?? 'Usuario';

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hola, $nombre',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                roleLabel(context, widget.contexto.rol),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),

              _HelpListener(
                helpEnabled: _helpEnabled,
                helpText: 'Resumen de expensas del ultimo ano.',
                child: _buildExpensasCard(theme),
              ),
              const SizedBox(height: 16),
              _HelpListener(
                helpEnabled: _helpEnabled,
                helpText: 'Resumen de reclamos activos y resueltos.',
                child: _buildReclamosCard(theme),
              ),
              const SizedBox(height: 16),
              _buildBasesLegalesCard(context),
            ],
          ),
        ),

        if (_loading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Widget _buildExpensasCard(ThemeData theme) {
    final total =
        _expensasPendientes + _expensasVencidas + _expensasPagadas;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expensas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Unidad ${widget.contexto.unidadCodigo}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (total == 0)
              const Text(
                'No hay expensas registradas en el último año.',
              )
            else
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildExpensasSections(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem(
                            color: Colors.orange,
                            label: 'Pendientes',
                            value: _expensasPendientes,
                          ),
                          const SizedBox(height: 6),
                          _legendItem(
                            color: Colors.redAccent,
                            label: 'Vencidas',
                            value: _expensasVencidas,
                          ),
                          const SizedBox(height: 6),
                          _legendItem(
                            color: Colors.green,
                            label: 'Pagadas',
                            value: _expensasPagadas,
                          ),
                          const Spacer(),
                          Text(
                            'Total registradas: $total',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildExpensasSections() {
    final total =
        _expensasPendientes + _expensasVencidas + _expensasPagadas;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey[300],
          title: '',
        ),
      ];
    }

    final sections = <PieChartSectionData>[];

    if (_expensasPendientes > 0) {
      sections.add(
        PieChartSectionData(
          value: _expensasPendientes.toDouble(),
          color: Colors.orange,
          title: '',
        ),
      );
    }
    if (_expensasVencidas > 0) {
      sections.add(
        PieChartSectionData(
          value: _expensasVencidas.toDouble(),
          color: Colors.redAccent,
          title: '',
        ),
      );
    }
    if (_expensasPagadas > 0) {
      sections.add(
        PieChartSectionData(
          value: _expensasPagadas.toDouble(),
          color: Colors.green,
          title: '',
        ),
      );
    }

    return sections;
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildReclamosCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reclamos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricBox(
                    color: Colors.orange,
                    label: 'Activos',
                    value: _reclamosActivos,
                    icon: Icons.assignment_late_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricBox(
                    color: Colors.green,
                    label: 'Resueltos',
                    value: _reclamosResueltos,
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasesLegalesCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: _HelpableTile(
        helpEnabled: _helpEnabled,
        helpText: 'Abrir bases legales del consorcio.',
        onTap: () {
          Navigator.of(context).pushNamed('/bases-legales');
        },
        child: const ListTile(
          leading: Icon(Icons.gavel_outlined),
          title: Text('Bases legales'),
          subtitle: Text('Reglamento de consorcio y leyes vigentes'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _metricBox({
    required Color color,
    required String label,
    required int value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ],
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
