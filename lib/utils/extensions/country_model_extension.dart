import 'package:optombai/data/models/countries/countries.dart';

extension CountryModelExtension on CountryModel? {
  bool get isTariffAllowed {
    final iso = this?.iso2;
    if (iso == null) return false;
    const allowed = {'KG', 'KZ', 'UZ', 'RU'};
    return allowed.contains(iso.toUpperCase());
  }
}
