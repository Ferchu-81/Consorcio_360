/// Modelo simple para una expensa emitida a una unidad.
class Expensa {
  final String id;
  final String consorcioId;
  final String unidadId;
  final DateTime periodo; // Representa el mes (ej: 2025-03-01)
  final double importeTotal;
  final String estado; // PENDIENTE / PAGADA / VENCIDA / PARCIAL / ANULADA
  final DateTime fechaVenc;
  final DateTime? fechaEmision;
  final String moneda;

  const Expensa({
    required this.id,
    required this.consorcioId,
    required this.unidadId,
    required this.periodo,
    required this.importeTotal,
    required this.estado,
    required this.fechaVenc,
    this.fechaEmision,
    this.moneda = 'ARS',
  });

  factory Expensa.fromMap(Map<String, dynamic> map) {
    return Expensa(
      id: map['id'] as String,
      consorcioId: map['consorcio_id'] as String,
      unidadId: map['unidad_id'] as String,
      periodo: DateTime.tryParse(map['periodo']?.toString() ?? '') ??
          DateTime.now(),
      importeTotal: _toDouble(map['importe_total']),
      estado: (map['estado'] ?? 'PENDIENTE').toString(),
      fechaVenc: DateTime.tryParse(map['fecha_venc']?.toString() ?? '') ??
          DateTime.now(),
      fechaEmision: map['fecha_emision'] != null
          ? DateTime.tryParse(map['fecha_emision'].toString())
          : null,
      moneda: (map['moneda'] ?? 'ARS').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consorcio_id': consorcioId,
      'unidad_id': unidadId,
      'periodo': periodo.toIso8601String(),
      'importe_total': importeTotal,
      'estado': estado,
      'fecha_venc': fechaVenc.toIso8601String(),
      'fecha_emision': fechaEmision?.toIso8601String(),
      'moneda': moneda,
    };
  }

  Expensa copyWith({
    String? id,
    String? consorcioId,
    String? unidadId,
    DateTime? periodo,
    double? importeTotal,
    String? estado,
    DateTime? fechaVenc,
    DateTime? fechaEmision,
    String? moneda,
  }) {
    return Expensa(
      id: id ?? this.id,
      consorcioId: consorcioId ?? this.consorcioId,
      unidadId: unidadId ?? this.unidadId,
      periodo: periodo ?? this.periodo,
      importeTotal: importeTotal ?? this.importeTotal,
      estado: estado ?? this.estado,
      fechaVenc: fechaVenc ?? this.fechaVenc,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      moneda: moneda ?? this.moneda,
    );
  }

  bool get estaPendiente => estado == 'PENDIENTE';
  bool get estaPagada => estado == 'PAGADA';
  bool get estaVencida => estado == 'VENCIDA';

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
