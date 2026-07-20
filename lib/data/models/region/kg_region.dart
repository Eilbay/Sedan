class KgRegion {
  final int id;
  final String title;

  const KgRegion({required this.id, required this.title});

  static const List<KgRegion> all = [
    KgRegion(id: 1, title: 'Бишкек'),
    KgRegion(id: 2, title: 'Ош'),
    KgRegion(id: 3, title: 'Чуйская область'),
    KgRegion(id: 4, title: 'Иссык-Кульская область'),
    KgRegion(id: 5, title: 'Нарынская область'),
    KgRegion(id: 6, title: 'Таласская область'),
    KgRegion(id: 7, title: 'Джалал-Абадская область'),
    KgRegion(id: 8, title: 'Ошская область'),
    KgRegion(id: 9, title: 'Баткенская область'),
  ];

  static KgRegion? fromId(int? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static KgRegion? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map) {
      final id = json['id'];
      return fromId(id is int ? id : int.tryParse(id?.toString() ?? ''));
    }
    if (json is int) return fromId(json);
    return fromId(int.tryParse(json.toString()));
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) => other is KgRegion && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
