import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final List<Category> children;

  const Category({
    this.id = '',
    this.name = '',
    this.icon = '',
    this.children = const [],
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      children: children ?? this.children,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? "").toString(),
      name: json['name'] ?? "",
      icon: json['icon'] ?? "",
      children: (json['children'] as List<dynamic>?)
              ?.map((item) => Category.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "icon": icon,
      "children": children.map((child) => child.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, icon, children];
}
