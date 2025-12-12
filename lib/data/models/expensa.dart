/// Modelo simple para una expensa emitida a una unidad.
class Expensa {
  final String id;
  final String consorcioId;
  final String unidadId;
  final String? unidadCodigo;
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
    this.unidadCodigo,
    required this.periodo,
    required this.importeTotal,
    required this.estado,
    required this.fechaVenc,
    this.fechaEmision,
    this.moneda = 'ARS',
  });

  /// Estado considerando vencimiento: si está pendiente y ya pasó el vencimiento, se muestra VENCIDA.
  String get estadoEfectivo => estaVencida ? 'VENCIDA' : estado;

  DateTime? get fechaVencimiento => fechaVenc;

  bool get estaPagada => estado.toUpperCase() == 'PAGADA';

  bool get estaParcial =>
      estado.toUpperCase() == 'PARCIAL' || estado.toUpperCase() == 'PAGOPARCIAL';

  bool get estaVencida {
    final fv = fechaVencimiento;
    if (fv == null || estaPagada) return false;
    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final venSoloFecha = DateTime(fv.year, fv.month, fv.day);
    return venSoloFecha.isBefore(hoySoloFecha);
  }

  String get periodoFormatted =>
      '${_mesNombre(periodo.month)} ${periodo.year}';

  String get fechaVencFormatted =>
      '${fechaVenc.day.toString().padLeft(2, '0')}/${fechaVenc.month.toString().padLeft(2, '0')}/${fechaVenc.year}';

  String _mesNombre(int mes) {
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
    return meses[mes - 1];
  }

  factory Expensa.fromMap(Map<String, dynamic> map) {
    return Expensa(
      id: map['id'] as String,
      consorcioId: map['consorcio_id'] as String,
      unidadId: map['unidad_id'] as String,
      unidadCodigo: (map['unidades'] as Map<String, dynamic>?)?['codigo']?.toString(),
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
      'unidad_codigo': unidadCodigo,
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
    String? unidadCodigo,
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
      unidadCodigo: unidadCodigo ?? this.unidadCodigo,
      periodo: periodo ?? this.periodo,
      importeTotal: importeTotal ?? this.importeTotal,
      estado: estado ?? this.estado,
      fechaVenc: fechaVenc ?? this.fechaVenc,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      moneda: moneda ?? this.moneda,
    );
  }

  bool get estaPendiente => estado == 'PENDIENTE';

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
