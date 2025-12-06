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
}
