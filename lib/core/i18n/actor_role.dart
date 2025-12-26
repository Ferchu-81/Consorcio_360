import 'package:flutter/widgets.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';

/// Roles "de sistema" (cÃ³digos DB) -> rol de actor en UI.
/// Importante: el label es i18n (se resuelve por idioma en AppLocalizations).
enum ActorRole {
  adminConsorcio,
  propietario,
  ocupante,
}

ActorRole actorRoleFromDb(String rol) {
  switch (rol) {
    case 'ADMIN_CONSORCIO':
      return ActorRole.adminConsorcio;
    case 'PROPIETARIO':
      return ActorRole.propietario;
    case 'MORADOR':
    default:
      return ActorRole.ocupante;
  }
}

extension ActorRoleX on ActorRole {
  String label(
    BuildContext context, {
    required bool esInquilino,
  }) {
    final l10n = AppLocalizations.of(context);

    switch (this) {
      case ActorRole.adminConsorcio:
        return l10n.roleAdmin;
      case ActorRole.propietario:
        return l10n.roleOwner;
      case ActorRole.ocupante:
        return esInquilino ? l10n.roleTenant : l10n.roleOccupant;
    }
  }
}


