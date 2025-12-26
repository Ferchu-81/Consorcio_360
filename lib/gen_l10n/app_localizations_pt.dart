// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get roleAdmin => 'Síndico';

  @override
  String get roleOwner => 'Proprietário';

  @override
  String get roleTenant => 'Inquilino';

  @override
  String get roleOccupant => 'Morador';

  @override
  String get roleOwnerOrTenant => 'Proprietário / Inquilino';

  @override
  String get isPrimaryOwner => 'Titular';

  @override
  String get occupiesUnit => 'Ocupa';

  @override
  String get cfgAmenitiesOwnerNonOccupantTitle =>
      'Proprietário não residente: acesso às áreas comuns (uso e reserva)';

  @override
  String get cfgAmenitiesOwnerNonOccupantSubtitle =>
      'Permite usar e reservar áreas comuns mesmo sem morar na unidade.';

  @override
  String get cfgOwnerVoteWithoutOccupyingTitle =>
      'Voto do proprietário sem residir';

  @override
  String get cfgOwnerVoteWithoutOccupyingSubtitle =>
      'Permite que o proprietário vote mesmo com um residente na unidade.';

  @override
  String get unit => 'Unidade';
}
