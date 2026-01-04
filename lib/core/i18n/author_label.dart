import 'package:flutter/widgets.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:consorcio_360/core/i18n/role_label.dart';

/// Label para mostrar el "autor" de un mensaje en UI.
/// Regla:
/// - si es admin (o rol == ADMIN_CONSORCIO) => "Administrador"
/// - si rol conocido => roleLabel(...) (Propietario / Inquilino)
/// - si no => "Usuario"
String authorLabel(
  BuildContext context, {
  required bool isAdmin,
  String? rol,
}) {
  final l10n = AppLocalizations.of(context);

  if (isAdmin || rol == 'ADMIN_CONSORCIO') {
    return l10n.roleAdmin;
  }

  if (rol != null && rol.trim().isNotEmpty) {
    return roleLabel(context, rol);
  }

  return l10n.genericUser;
}
