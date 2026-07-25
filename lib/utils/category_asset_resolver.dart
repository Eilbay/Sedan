import 'package:optombai/data/mock/sedan_mock_listings.dart';

String? localCategoryAssetForName(String name) {
  final categoryKey = sedanMockCategoryKeyForName(name);
  if (categoryKey == 'suv') {
    return 'assets/sedan/category/suv.png';
  }
  if (categoryKey == 'commercial') {
    return 'assets/sedan/category/commercial.png';
  }
  if (categoryKey == 'motorcycle') {
    return 'assets/sedan/category/motorcycle.png';
  }
  if (categoryKey == 'parts') {
    return 'assets/sedan/category/parts.png';
  }
  if (categoryKey == 'service') {
    return 'assets/sedan/category/service.png';
  }
  if (categoryKey == 'passenger_cars') {
    return 'assets/sedan/category/passenger_cars.png';
  }

  return null;
}
