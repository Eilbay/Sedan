import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:optombai/data/models/posts/post_model.dart';

part 'cart_item_model.g.dart';

/// Cart item model for local storage
/// TODO: Replace with API model when backend is ready
/// Currently using Hive for local persistence
@HiveType(typeId: 10)
class CartItem extends Equatable {
  @HiveField(0)
  final String id; // UUID generated locally

  @HiveField(1)
  final String productId;

  @HiveField(10)
  final int? productNumber; // Article number

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String? productImage;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final int quantity;

  @HiveField(6)
  final String? ownerName; // Company/seller name

  @HiveField(7)
  final String? countryName;

  @HiveField(8)
  final String? countryFlag; // Flag asset path

  @HiveField(9)
  final DateTime addedAt;

  const CartItem({
    required this.id,
    required this.productId,
    this.productNumber,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    this.ownerName,
    this.countryName,
    this.countryFlag,
    required this.addedAt,
  });

  CartItem copyWith({
    String? id,
    String? productId,
    int? productNumber,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    String? ownerName,
    String? countryName,
    String? countryFlag,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productNumber: productNumber ?? this.productNumber,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      ownerName: ownerName ?? this.ownerName,
      countryName: countryName ?? this.countryName,
      countryFlag: countryFlag ?? this.countryFlag,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get totalPrice => price * quantity;

  /// Create CartItem from Product model
  factory CartItem.fromProduct(Product product) {
    return CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productNumber: product.productNumber,
      productName: product.name,
      productImage: product.previewUrl,
      price: product.price ?? 0,
      quantity: 1,
      ownerName: product.owner?.username,
      countryName: product.owner?.country?.name,
      countryFlag: product.owner?.country?.flag,
      addedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productNumber': productNumber,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'ownerName': ownerName,
      'countryName': countryName,
      'countryFlag': countryFlag,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productNumber: json['productNumber'] as int?,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      ownerName: json['ownerName'] as String?,
      countryName: json['countryName'] as String?,
      countryFlag: json['countryFlag'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, productId, productNumber, quantity];
}
