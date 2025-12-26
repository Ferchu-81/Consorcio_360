// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleTenant => 'Inquilino';

  @override
  String get roleOccupant => 'Ocupante';

  @override
  String get roleOwnerOrTenant => 'Propietario / Inquilino';

  @override
  String get cfgAmenitiesOwnerNonOccupantTitle =>
      'Amenities: propietario no ocupante';

  @override
  String get cfgAmenitiesOwnerNonOccupantSubtitle =>
      'Permite usar y reservar amenities aunque no viva en la unidad.';

  @override
  String get cfgOwnerVoteWithoutOccupyingTitle =>
      'Voto del propietario sin ocupar';

  @override
  String get cfgOwnerVoteWithoutOccupyingSubtitle =>
      'Permite votar al propietario aunque haya un ocupante en la unidad.';
}
