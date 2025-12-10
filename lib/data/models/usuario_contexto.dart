class UsuarioContexto {
  final String usuarioUnidadId;
  final String consorcioId;
  final String consorcioNombre;
  final String unidadId;
  final String unidadCodigo;
  final String rol; // ADMIN_CONSORCIO / PROPIETARIO / MORADOR
  final bool esTitular;

  UsuarioContexto({
    required this.usuarioUnidadId,
    required this.consorcioId,
    required this.consorcioNombre,
    required this.unidadId,
    required this.unidadCodigo,
    required this.rol,
    required this.esTitular,
  });

  String get rolLegible {
    switch (rol) {
      case 'ADMIN_CONSORCIO':
        return 'Administrador';
      case 'PROPIETARIO':
        return 'Propietario';
      case 'MORADOR':
      default:
        return 'Morador';
    }
  }

  String get descripcionLarga =>
      '$consorcioNombre - Unidad $unidadCodigo - $rolLegible';

  Map<String, dynamic> toJson() {
    return {
      'usuario_unidad_id': usuarioUnidadId,
      'consorcio_id': consorcioId,
      'consorcio_nombre': consorcioNombre,
      'unidad_id': unidadId,
      'unidad_codigo': unidadCodigo,
      'rol': rol,
      'es_titular': esTitular,
    };
  }

  factory UsuarioContexto.fromJson(Map<String, dynamic> json) {
    return UsuarioContexto(
      usuarioUnidadId: json['usuario_unidad_id'] as String,
      consorcioId: json['consorcio_id'] as String,
      consorcioNombre: json['consorcio_nombre'] as String,
      unidadId: json['unidad_id'] as String,
      unidadCodigo: json['unidad_codigo'] as String,
      rol: json['rol'] as String,
      esTitular: json['es_titular'] as bool? ?? false,
    );
  }
}
