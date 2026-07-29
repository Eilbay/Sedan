class SedanMockListing {
  final String categoryKey;
  final String title;
  final String imageAsset;
  final String price;
  final List<SedanMockSpec> specs;
  final String condition;

  const SedanMockListing({
    required this.categoryKey,
    required this.title,
    required this.imageAsset,
    required this.price,
    required this.specs,
    required this.condition,
  });
}

class SedanMockSpec {
  final String label;
  final String value;

  const SedanMockSpec(this.label, this.value);
}

const sedanMockListings = <SedanMockListing>[
  SedanMockListing(
    categoryKey: 'passenger_cars',
    title: 'Mercedes-Benz E-Class',
    imageAsset: 'assets/sedan/mock/mercedes_e_class.jpg',
    price: '34 500 \$',
    specs: [
      SedanMockSpec('Год', '2019'),
      SedanMockSpec('Объем двигателя', '2.0 л (бензин)'),
    ],
    condition:
        'Отличное, без вложений. Автомобиль полностью обслужен, чистый и ухоженный салон.',
  ),
  SedanMockListing(
    categoryKey: 'suv',
    title: 'Mercedes-Benz G-Class G500',
    imageAsset: 'assets/sedan/mock/mercedes_g_class.jpg',
    price: '98 000 \$',
    specs: [
      SedanMockSpec('Год', '2018'),
      SedanMockSpec('Объем двигателя', '4.0 л (бензин, V8 Biturbo)'),
      SedanMockSpec('КПП', 'Автомат'),
    ],
    condition: 'Отличное, полностью обслужен, без вложений.',
  ),
  SedanMockListing(
    categoryKey: 'commercial',
    title: 'Hyundai Porter',
    imageAsset: 'assets/sedan/mock/hyundai_porter.jpg',
    price: '19 500 \$',
    specs: [
      SedanMockSpec('Год', '2021'),
      SedanMockSpec('Объем двигателя', '2.5 л (дизель)'),
      SedanMockSpec('КПП', 'Механика'),
    ],
    condition: 'Отличное, полностью обслужен, без вложений. Готов к работе.',
  ),
  SedanMockListing(
    categoryKey: 'motorcycle',
    title: 'BSE Z5 300 (Enduro)',
    imageAsset: 'assets/sedan/mock/bse_z5_enduro.jpg',
    price: '3 800 \$',
    specs: [
      SedanMockSpec('Год', '2024'),
      SedanMockSpec('Объем двигателя', '300 см3'),
      SedanMockSpec('КПП', '6-ступенчатая, механика'),
    ],
    condition:
        'Отличное, без пробега по Кыргызстану, полностью готов к эксплуатации.',
  ),
  SedanMockListing(
    categoryKey: 'parts',
    title: 'Комплект автозапчастей',
    imageAsset: 'assets/sedan/mock/parts_kit.jpg',
    price: '350 \$',
    specs: [
      SedanMockSpec('Год выпуска', '2024'),
      SedanMockSpec('Категория', 'Трансмиссия / Подшипники / Шестерни'),
    ],
    condition: 'Новые, оригинальное качество.',
  ),
  SedanMockListing(
    categoryKey: 'service',
    title: 'Покраска автомобилей',
    imageAsset: 'assets/sedan/mock/paint_service.jpg',
    price: 'от 150 \$',
    specs: [
      SedanMockSpec('Услуга', 'Полная и локальная покраска кузова'),
      SedanMockSpec('Материалы', 'Профессиональные лакокрасочные материалы'),
    ],
    condition: 'Качественное выполнение работ, гарантия результата.',
  ),
];

String? sedanMockCategoryKeyForName(String name) {
  final normalized = name.trim().toLowerCase();

  if (normalized.contains('внедорож')) return 'suv';
  if (normalized.contains('коммер') || normalized.contains('груз')) {
    return 'commercial';
  }
  if (normalized.contains('мото') || normalized.contains('техник')) {
    return 'motorcycle';
  }
  if (normalized.contains('запчаст')) return 'parts';
  if (normalized.contains('сервис') ||
      normalized.contains('услуг') ||
      normalized.contains('ремонт') ||
      normalized.contains('обслуж')) {
    return 'service';
  }
  if (normalized.contains('легков') ||
      normalized.contains('седан') ||
      normalized == 'авто' ||
      normalized.contains('автомоб')) {
    return 'passenger_cars';
  }

  return null;
}

SedanMockListing? sedanMockListingForCategory(String categoryName) {
  final key = sedanMockCategoryKeyForName(categoryName);
  if (key == null) return null;

  return sedanMockListingForKey(key);
}

SedanMockListing? sedanMockListingForKey(String categoryKey) {
  for (final listing in sedanMockListings) {
    if (listing.categoryKey == categoryKey) return listing;
  }
  return null;
}

String sedanMockCategoryTitleForKey(String categoryKey) {
  switch (categoryKey) {
    case 'passenger_cars':
      return 'Легковые';
    case 'suv':
      return 'Внедорожники';
    case 'commercial':
      return 'Коммерческие';
    case 'motorcycle':
      return 'Мототехника';
    case 'parts':
      return 'Запчасти';
    case 'service':
      return 'Услуги';
  }
  return 'Категория';
}

List<SedanMockListing> filterSedanMockListings(String? rawQuery) {
  final query = rawQuery?.trim().toLowerCase() ?? '';
  if (query.isEmpty) return sedanMockListings;

  return sedanMockListings.where((listing) {
    final searchable = [
      listing.title,
      listing.price,
      listing.condition,
      sedanMockCategoryTitleForKey(listing.categoryKey),
      ...listing.specs.map((spec) => '${spec.label} ${spec.value}'),
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }).toList();
}
