import 'package:flutter/material.dart';

/// Formatea el periodo (DateTime) a "Marzo 2025".
String formatPeriodo(DateTime periodo) {
  const meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  final mes = meses[periodo.month - 1];
  return '$mes ${periodo.year}';
}

/// Convierte un enum tipo "PENDIENTE" a "Pendiente".
String formatEstado(String estado) {
  if (estado.isEmpty) return estado;
  return estado
      .split('_')
      .map((p) {
        if (p.isEmpty) return '';
        final lower = p.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String formatFechaCorta(DateTime? fecha) {
  if (fecha == null) return '-';
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = (fecha.year % 100).toString().padLeft(2, '0');
  return '$dia/$mes/$anio';
}

String formatImporte(double importe, String moneda) {
  final prefix = moneda == 'ARS' ? r'$' : moneda;
  return '$prefix ${importe.toStringAsFixed(2)}';
}

Color estadoColor(String estado) {
  switch (estado) {
    case 'PAGADA':
    case 'APROBADO':
      return Colors.green;
    case 'PENDIENTE':
      return Colors.orange;
    case 'VENCIDA':
      return Colors.red;
    case 'PARCIAL':
      return Colors.blue;
    case 'RECHAZADO':
      return Colors.red.shade700;
    case 'CANCELADO':
      return Colors.grey.shade700;
    case 'ANULADA':
    default:
      return Colors.grey;
  }
}
