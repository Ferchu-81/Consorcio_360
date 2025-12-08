/// Pago registrado para una expensa (manual o via pasarela a futuro).
class PagoExpensa {
  final String id;
  final String expensaId;
  final String consorcioId;
  final String unidadId;
  final DateTime fechaPago;
  final double importe;
  final String medioPago; // EFECTIVO / TRANSFERENCIA / MERCADO_PAGO / OTRO
  final String estadoPago; // PENDIENTE / APROBADO / RECHAZADO / CANCELADO
  final String? refMp;
  final String? observaciones;
  final DateTime? periodoExpensa;
  final String? monedaExpensa;
  final double? expensaImporteTotal;

  PagoExpensa({
    required this.id,
    required this.expensaId,
    required this.consorcioId,
    required this.unidadId,
    required this.fechaPago,
    required this.importe,
    required this.medioPago,
    required this.estadoPago,
    this.refMp,
    this.observaciones,
    this.periodoExpensa,
    this.monedaExpensa,
    this.expensaImporteTotal,
  });

  factory PagoExpensa.fromMap(Map<String, dynamic> map) {
    final expensaRelacion = map['expensa'] as Map<String, dynamic>?;
    return PagoExpensa(
      id: map['id'] as String,
      expensaId: map['expensa_id'] as String,
      consorcioId: map['consorcio_id'] as String,
      unidadId: map['unidad_id'] as String,
      fechaPago:
          DateTime.tryParse(map['fecha_pago']?.toString() ?? '') ??
          DateTime.now(),
      importe: _toDouble(map['importe']),
      medioPago: (map['medio_pago'] ?? 'EFECTIVO').toString(),
      estadoPago: (map['estado_pago'] ?? 'APROBADO').toString(),
      refMp: map['ref_mp']?.toString(),
      observaciones: map['observaciones']?.toString(),
      periodoExpensa: expensaRelacion != null
          ? DateTime.tryParse(expensaRelacion['periodo']?.toString() ?? '')
          : null,
      monedaExpensa: expensaRelacion?['moneda']?.toString(),
      expensaImporteTotal: expensaRelacion != null
          ? _toDouble(expensaRelacion['importe_total'])
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
