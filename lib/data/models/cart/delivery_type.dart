import 'package:hive/hive.dart';

part 'delivery_type.g.dart';

/// Enum for delivery type selection
/// TODO: Replace with API enum when backend is ready
@HiveType(typeId: 13)
enum DeliveryType {
  @HiveField(0)
  pickup, // Free delivery to pickup point

  @HiveField(1)
  courier, // Courier delivery - 350 RUB
}

extension DeliveryTypeExtension on DeliveryType {
  double get cost {
    switch (this) {
      case DeliveryType.pickup:
        return 0;
      case DeliveryType.courier:
        return 150;
    }
  }

  String get displayName {
    switch (this) {
      case DeliveryType.pickup:
        return 'Бесплатная доставка до пункта выдачи';
      case DeliveryType.courier:
        return 'Доставка курьером';
    }
  }

  String get shortName {
    switch (this) {
      case DeliveryType.pickup:
        return 'До пункта выдачи';
      case DeliveryType.courier:
        return 'Курьером';
    }
  }
}
