import 'package:flutter/widgets.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';

/// Labels de rol para UI (DB sigue igual: ADMIN_CONSORCIO / PROPIETARIO / MORADOR).
/// En ES (Argentina): MORADOR => "Inquilino"
/// En PT-BR: MORADOR => "Inquilino" (por defecto, claro y comercial)
String roleLabel(BuildContext context, String rolDb) {
  final l10n = AppLocalizations.of(context);

  switch (rolDb) {
    case 'ADMIN_CONSORCIO':
      return l10n.roleAdmin;
    case 'PROPIETARIO':
      return l10n.roleOwner;
    case 'MORADOR':
      return l10n.roleOccupantDefault;
    default:
      return rolDb.replaceAll('_', ' '); // fallback por si aparece algo nuevo
  }
}
