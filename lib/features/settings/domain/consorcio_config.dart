class ConsorcioConfig {
  final String consorcioId;

  /// Unificado: si es TRUE, el propietario NO ocupante puede usar/reservar amenities.
  final bool permitirAmenitiesPropNoOcupante;

  /// Voto del propietario aunque no ocupe.
  final bool propietarioPuedeVotarSinOcupar;

  const ConsorcioConfig({
    required this.consorcioId,
    this.permitirAmenitiesPropNoOcupante = false,
    this.propietarioPuedeVotarSinOcupar = true,
  });

  factory ConsorcioConfig.fromJson(Map<String, dynamic> json) {
    final uso = json['permitir_uso_amenities_prop_no_ocupante'] as bool? ?? false;
    final reservas =
        json['permitir_reservas_prop_no_ocupante'] as bool? ?? false;

    return ConsorcioConfig(
      consorcioId: json['consorcio_id'] as String,
      permitirAmenitiesPropNoOcupante: uso || reservas,
      propietarioPuedeVotarSinOcupar:
          json['propietario_puede_votar_sin_ocupar'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consorcio_id': consorcioId,
      'permitir_uso_amenities_prop_no_ocupante':
          permitirAmenitiesPropNoOcupante,
      'permitir_reservas_prop_no_ocupante': permitirAmenitiesPropNoOcupante,
      'propietario_puede_votar_sin_ocupar': propietarioPuedeVotarSinOcupar,
    };
  }

  ConsorcioConfig copyWith({
    bool? permitirAmenitiesPropNoOcupante,
    bool? propietarioPuedeVotarSinOcupar,
  }) {
    return ConsorcioConfig(
      consorcioId: consorcioId,
      permitirAmenitiesPropNoOcupante: permitirAmenitiesPropNoOcupante ??
          this.permitirAmenitiesPropNoOcupante,
      propietarioPuedeVotarSinOcupar:
          propietarioPuedeVotarSinOcupar ?? this.propietarioPuedeVotarSinOcupar,
    );
  }
}
