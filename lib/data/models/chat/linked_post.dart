import 'package:optombai/data/models/posts/post_model.dart';

class LinkedPost {
  final String id;
  final String title;
  final String? imageUrl;
  final double? price;
  final String currency;

  const LinkedPost({
    required this.id,
    required this.title,
    this.imageUrl,
    this.price,
    this.currency = 'KGS',
  });

  factory LinkedPost.fromJson(dynamic json) {
    if (json is String) {
      return LinkedPost(id: json, title: 'Товар');
    }

    if (json is! Map<String, dynamic>) {
      return const LinkedPost(id: '', title: 'Товар');
    }

    final product = Product.fromJson(json);
    final title = (json['title'] ?? json['name'] ?? product.name).toString();
    final imageUrl = (json['image_url'] ??
            json['image'] ??
            json['cover_image'] ??
            product.previewUrl)
        ?.toString();
    final price = json['price'] is num
        ? (json['price'] as num).toDouble()
        : double.tryParse(json['price']?.toString() ?? '') ?? product.price;
    final currency = (json['currency'] as String?) ?? product.currency;
    final id = (json['id'] ?? json['post_id'] ?? json['post'])?.toString();

    return LinkedPost(
      id: id ?? '',
      title: title.isNotEmpty ? title : 'Товар',
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
      price: price,
      currency: currency,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image_url': imageUrl,
        'price': price,
        'currency': currency,
      };
}
