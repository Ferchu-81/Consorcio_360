import 'package:consorcio_360/features/settings/domain/consorcio_config.dart';

bool puedeUsarAmenities({
  required String rol,
  required bool ocupa,
  required ConsorcioConfig cfg,
}) {
  if (ocupa) return true;
  if (rol == 'PROPIETARIO') return cfg.permitirUsoAmenitiesPropNoOcupante;
  return false;
}

bool puedeReservar({
  required String rol,
  required bool ocupa,
  required ConsorcioConfig cfg,
}) {
  if (ocupa) return true;
  if (rol == 'PROPIETARIO') return cfg.permitirReservasPropNoOcupante;
  return false;
}

bool puedeVotar({
  required String rol,
  required bool ocupa,
  required ConsorcioConfig cfg,
}) {
  if (ocupa) return true;
  if (rol == 'PROPIETARIO') return cfg.propietarioPuedeVotarSinOcupar;
  return false;
}
