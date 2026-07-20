/// Pickup point model
/// TODO: Replace with API model when backend is ready
class PickupPoint {
  final String id;
  final String name;
  final String address;
  final String workingHours;
  final String? mapImageAsset; // Local asset path for map image

  const PickupPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.workingHours,
    this.mapImageAsset,
  });

  /// Hardcoded pickup points
  /// TODO: Replace with API call when backend is ready
  static const List<PickupPoint> bishkekPoints = [
    PickupPoint(
      id: '1',
      name: 'Пункт выдачи "Бишкек"',
      address: 'г. Бишкек, мкр-н Тунгуч, 36Б',
      workingHours: '09:00 - 21:00',
      mapImageAsset: 'assets/maps/pickup_1.png',
    ),
    PickupPoint(
      id: '2',
      name: 'Пункт выдачи "Ош"',
      address: 'г. Ош, ул. Ашимахунова, 6 (Келечек)',
      workingHours: '09:00 - 21:00',
      mapImageAsset: 'assets/maps/pickup_2.png',
    ),
  ];

  static PickupPoint? findById(String? id) {
    if (id == null) return null;
    try {
      return bishkekPoints.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
