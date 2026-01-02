import 'package:consorcio_360/features/settings/domain/consorcio_config.dart';

bool puedeUsarAmenities({
  required String rol,
  required bool ocupa,
  required ConsorcioConfig cfg,
}) {
  if (rol == 'ADMIN_CONSORCIO') return true;

  // Regla simple y profesional:
  // Si ocupa la unidad, tiene prioridad de uso/reserva.
  if (ocupa) return true;

  // Propietario no ocupante: depende de config.
  if (rol == 'PROPIETARIO' && !ocupa) {
    return cfg.permitirAmenitiesPropNoOcupante;
  }

  return false;
}

/// Por producto, reserva == uso. Si algún día querés separar, lo hacés a propósito.
bool puedeReservarAmenities({
  required String rol,
  required bool ocupa,
  required ConsorcioConfig cfg,
}) {
  return puedeUsarAmenities(rol: rol, ocupa: ocupa, cfg: cfg);
}

bool puedeVotar({
  required String rol,
  required bool ocupa,
  required ConsorcioConfig cfg,
}) {
  if (rol == 'ADMIN_CONSORCIO') return true;

  // Si ocupa, por defecto habilitado (más simple y usable).
  if (ocupa) return true;

  if (rol == 'PROPIETARIO' && !ocupa) {
    return cfg.propietarioPuedeVotarSinOcupar;
  }

  return false;
}
