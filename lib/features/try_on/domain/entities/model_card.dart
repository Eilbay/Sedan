class TryOnModelCard {
  final String id;
  final String name;
  final String gender;
  final String faceImageUrl;
  final String bodyImageUrl;
  final String source;
  final String? nationality;
  final String? type;
  final String? age;

  TryOnModelCard({
    required this.id,
    required this.name,
    required this.gender,
    required this.faceImageUrl,
    required this.bodyImageUrl,
    required this.source,
    this.nationality,
    this.type,
    this.age,
  });

  factory TryOnModelCard.fromJson(Map<String, dynamic> j) => TryOnModelCard(
        id: j['id'],
        name: j['name'],
        gender: j['gender'],
        faceImageUrl: j['face_image_url'],
        bodyImageUrl: j['body_image_url'],
        source: j['source'],
        nationality: j['nationality'],
        type: j['type'],
        age: j['age'],
      );
}
