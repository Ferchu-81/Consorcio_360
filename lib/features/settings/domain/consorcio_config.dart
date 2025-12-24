class ConsorcioConfig {
  final String consorcioId;
  final bool permitirReservasPropNoOcupante;
  final bool permitirUsoAmenitiesPropNoOcupante;
  final bool propietarioPuedeVotarSinOcupar;

  const ConsorcioConfig({
    required this.consorcioId,
    required this.permitirReservasPropNoOcupante,
    required this.permitirUsoAmenitiesPropNoOcupante,
    required this.propietarioPuedeVotarSinOcupar,
  });

  factory ConsorcioConfig.fromJson(Map<String, dynamic> json) {
    return ConsorcioConfig(
      consorcioId: json['consorcio_id']?.toString() ?? '',
      permitirReservasPropNoOcupante:
          json['permitir_reservas_prop_no_ocupante'] == true,
      permitirUsoAmenitiesPropNoOcupante:
          json['permitir_uso_amenities_prop_no_ocupante'] == true,
      propietarioPuedeVotarSinOcupar:
          json['propietario_puede_votar_sin_ocupar'] == true,
    );
  }

  ConsorcioConfig copyWith({
    bool? permitirReservasPropNoOcupante,
    bool? permitirUsoAmenitiesPropNoOcupante,
    bool? propietarioPuedeVotarSinOcupar,
  }) {
    return ConsorcioConfig(
      consorcioId: consorcioId,
      permitirReservasPropNoOcupante:
          permitirReservasPropNoOcupante ?? this.permitirReservasPropNoOcupante,
      permitirUsoAmenitiesPropNoOcupante: permitirUsoAmenitiesPropNoOcupante ??
          this.permitirUsoAmenitiesPropNoOcupante,
      propietarioPuedeVotarSinOcupar:
          propietarioPuedeVotarSinOcupar ?? this.propietarioPuedeVotarSinOcupar,
    );
  }
}
