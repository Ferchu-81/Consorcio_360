import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Modelo simple para representar un rubro de gasto dentro de la expensa.
class GastoCategoria {
  final String categoria;
  final double importe;

  const GastoCategoria(this.categoria, this.importe);
}

/// Donut con desglose de gastos de una expensa.
class ExpensaDonutChart extends StatelessWidget {
  final List<GastoCategoria> datos;

  const ExpensaDonutChart({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final total = datos.fold<double>(0, (sum, g) => sum + g.importe);
    if (total == 0) {
      return const Center(child: Text('Sin desglose de gastos'));
    }

    final colores = _buildPalette(context);

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 50,
          sectionsSpace: 2,
          sections: [
            for (int i = 0; i < datos.length; i++)
              _buildSection(datos[i], total, colores[i % colores.length]),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _buildSection(
    GastoCategoria gasto,
    double total,
    Color color,
  ) {
    final porcentaje = (gasto.importe / total) * 100;
    return PieChartSectionData(
      value: gasto.importe,
      title: '${porcentaje.toStringAsFixed(0)}%',
      radius: 70,
      color: color,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  List<Color> _buildPalette(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      scheme.primaryContainer,
      scheme.secondaryContainer,
    ];
  }
}
