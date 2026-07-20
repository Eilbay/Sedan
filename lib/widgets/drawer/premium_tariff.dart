enum PremiumTariff { weekly, monthly }

extension PremiumTariffX on PremiumTariff {
  int get priceRub => switch (this) {
        PremiumTariff.weekly => 922,
        PremiumTariff.monthly => 3600,
        // PremiumTariff.weekly => 1,
        // PremiumTariff.monthly => 1,
      };

  String get label => switch (this) {
        PremiumTariff.weekly => '7 дней',
        PremiumTariff.monthly => '30 дней',
      };
}
