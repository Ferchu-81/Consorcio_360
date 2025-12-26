// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleTenant => 'Tenant';

  @override
  String get roleOccupant => 'Occupant';

  @override
  String get roleOwnerOrTenant => 'Owner / Tenant';

  @override
  String get cfgAmenitiesOwnerNonOccupantTitle =>
      'Amenities: non-occupant owner';

  @override
  String get cfgAmenitiesOwnerNonOccupantSubtitle =>
      'Allows the owner to use and reserve amenities even when not living in the unit.';

  @override
  String get cfgOwnerVoteWithoutOccupyingTitle =>
      'Owner voting without occupying';

  @override
  String get cfgOwnerVoteWithoutOccupyingSubtitle =>
      'Allows the owner to vote even if there is an occupant in the unit.';
}
