import 'dart:async';

import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensa_detail_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lista de expensas para el rol morador/propietario.
const String _prefHelpEnabledKey = 'ui_help_enabled';

class ExpensasMoradorTab extends StatefulWidget {
  final String unidadId;

  const ExpensasMoradorTab({super.key, required this.unidadId});

  @override
  State<ExpensasMoradorTab> createState() => _ExpensasMoradorTabState();
}

class _ExpensasMoradorTabState extends State<ExpensasMoradorTab> {
  final ExpensasRepository _repository = ExpensasRepository();
  late Future<List<Expensa>> _futureExpensas;
  bool _helpEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHelpEnabled();
    _futureExpensas = _loadExpensas();
  }

  Future<void> _loadHelpEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefHelpEnabledKey);
    if (!mounted || value == null) return;
    setState(() => _helpEnabled = value);
  }

  Future<List<Expensa>> _loadExpensas() async {
    return _repository.fetchExpensasDeUnidad(widget.unidadId);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureExpensas = _loadExpensas();
    });
    await _futureExpensas;
  }

  Future<void> _openDetalle(Expensa expensa) async {
    final recargar = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExpensaDetailScreen(expensa: expensa)),
    );
    if (recargar == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Expensa>>(
          future: _futureExpensas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudieron cargar las expensas.'),
                        const SizedBox(height: 12),
                        _HelpListener(
                          helpEnabled: _helpEnabled,
                          helpText: 'Volver a cargar expensas.',
                          child: FilledButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final expensas = snapshot.data ?? [];

            if (expensas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'No hay expensas registradas para esta unidad.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: expensas.length,
              itemBuilder: (context, index) {
                final expensa = expensas[index];
                final periodoLabel = formatPeriodo(expensa.periodo);
                final estadoReal = expensa.estadoEfectivo;
                final estadoLabel = formatEstado(estadoReal);
                final color = estadoColor(estadoReal);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _HelpableTile(
                    helpEnabled: _helpEnabled,
                    helpText: 'Abrir detalle de la expensa.',
                    onTap: () => _openDetalle(expensa),
                    child: ListTile(
                      title: Text(
                        periodoLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            'Importe: ${formatImporte(expensa.importeTotal, expensa.moneda)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vencimiento: ${formatFechaCorta(expensa.fechaVenc)}',
                          ),
                          const SizedBox(height: 6),
                          Chip(
                            label: Text(estadoLabel),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: color.withValues(alpha: 0.12),
                            labelStyle: TextStyle(color: color),
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
