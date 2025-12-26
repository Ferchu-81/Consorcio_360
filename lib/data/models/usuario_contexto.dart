import 'package:consorcio_360/core/i18n/actor_role.dart';
import 'package:flutter/widgets.dart';

class UsuarioContexto {
  final String usuarioUnidadId;
  final String consorcioId;
  final String consorcioNombre;
  final String unidadId;
  final String unidadCodigo;
  final String? nombre;

  /// Códigos DB: ADMIN_CONSORCIO / PROPIETARIO / MORADOR
  final String rol;

  /// Para PROPIETARIO: indica si es el titular registral (o principal).
  final bool esTitular;

  /// Indica si la persona efectivamente ocupa la unidad.
  /// - PROPIETARIO puede ser ocupa=true o false.
  /// - MORADOR/OCUPANTE normalmente ocupa=true.
  final bool ocupa;

  /// Para rol MORADOR/OCUPANTE: por defecto es inquilino (true).
  /// Si no (comodato, familiar, etc.), esInquilino=false y en UI se muestra "Ocupante".
  final bool esInquilino;

  /// Soft-delete / vigencia.
  final bool activo;

  UsuarioContexto({
    required this.usuarioUnidadId,
    required this.consorcioId,
    required this.consorcioNombre,
    required this.unidadId,
    required this.unidadCodigo,
    this.nombre,
    required this.rol,
    required this.esTitular,
    required this.ocupa,
    required this.esInquilino,
    required this.activo,
  });

  ActorRole get actorRole => actorRoleFromDb(rol);

  /// Label i18n del rol.
  String rolLabel(BuildContext context) {
    return actorRole.label(context, esInquilino: esInquilino);
  }

  /// Solo para logs / debugging (sin i18n).
  String get descripcionLarga =>
      '$consorcioNombre - Unidad $unidadCodigo - Rol $rol';

  @Deprecated('Usá rolLabel(context) para i18n.')
  String get rolLegible {
    switch (rol) {
      case 'ADMIN_CONSORCIO':
        return 'Administrador';
      case 'PROPIETARIO':
        return 'Propietario';
      case 'MORADOR':
      default:
        return esInquilino ? 'Inquilino' : 'Ocupante';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_unidad_id': usuarioUnidadId,
      'consorcio_id': consorcioId,
      'consorcio_nombre': consorcioNombre,
      'unidad_id': unidadId,
      'unidad_codigo': unidadCodigo,
      'nombre': nombre,
      'rol': rol,
      'es_titular': esTitular,
      'ocupa': ocupa,
      'es_inquilino': esInquilino,
      'activo': activo,
    };
  }

  factory UsuarioContexto.fromJson(Map<String, dynamic> json) {
    return UsuarioContexto(
      usuarioUnidadId: json['usuario_unidad_id'] as String,
      consorcioId: json['consorcio_id'] as String,
      consorcioNombre: json['consorcio_nombre'] as String,
      unidadId: json['unidad_id'] as String,
      unidadCodigo: json['unidad_codigo'] as String,
      nombre: json['nombre'] as String?,
      rol: json['rol'] as String,
      esTitular: json['es_titular'] as bool? ?? false,
      ocupa: json['ocupa'] as bool? ?? false,
      esInquilino: json['es_inquilino'] as bool? ?? true,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
