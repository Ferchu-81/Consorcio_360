import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:consorcio_360/features/expensas/presentation/expensa_detail_screen.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_utils.dart';
import 'package:flutter/material.dart';

/// Lista de expensas para el rol morador/propietario.
class ExpensasMoradorTab extends StatefulWidget {
  final String unidadId;

  const ExpensasMoradorTab({super.key, required this.unidadId});

  @override
  State<ExpensasMoradorTab> createState() => _ExpensasMoradorTabState();
}

class _ExpensasMoradorTabState extends State<ExpensasMoradorTab> {
  final ExpensasRepository _repository = ExpensasRepository();
  late Future<List<Expensa>> _futureExpensas;

  @override
  void initState() {
    super.initState();
    _futureExpensas = _loadExpensas();
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

  void _openDetalle(Expensa expensa) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExpensaDetailScreen(expensa: expensa)),
    );
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
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
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
                final estadoLabel = formatEstado(expensa.estado);
                final color = estadoColor(expensa.estado);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _openDetalle(expensa),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
