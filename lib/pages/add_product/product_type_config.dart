import 'package:flutter/material.dart';

class ChoseClass {
  late int? id;
  final String name;
  late String? imagePath;
  late String? categoryId;
  late Color? color;

  ChoseClass(
      {this.id, this.name = "", this.imagePath, this.categoryId, this.color});
}

String? categoryId;
String? categoryImage;

List<ChoseClass> listMainPostType = [
  ChoseClass(id: 2, name: "Товар", imagePath: "assets/types/tovary.png"),
  ChoseClass(id: 0, name: "Объявление", imagePath: "assets/types/orders.png"),
];

List<ChoseClass> listMainPostType2 = [
  ChoseClass(
      id: 2, name: "Я продаю товар оптом", imagePath: "assets/types/tovary.png"),
  ChoseClass(
      id: 0, name: "Я ищу товар оптом", imagePath: "assets/types/orders.png"),
];

List<ChoseClass> listMainPostTypeFavorite = [
  ChoseClass(id: null, name: "Все", imagePath: "assets/types/tovary.png"),
  ChoseClass(id: 0, name: "Заказы", imagePath: "assets/types/orders.png"),
  ChoseClass(id: 2, name: "Товары", imagePath: "assets/types/tovary.png"),
];

List<ChoseClass> listProviderAndManufacturer = [
  ChoseClass(
    id: 2,
    name: "Товары",
    imagePath: "assets/banners/products.png",
    color: Colors.green,
  ),
  ChoseClass(
    id: 4,
    name: "Поставщики",
    imagePath: "assets/banners/suppliers.png",
    color: Colors.red,
  ),
  ChoseClass(
    id: 8,
    name: "Производители",
    imagePath: "assets/banners/manufacturers.png",
    color: Colors.blue,
  ),
  ChoseClass(
    id: 0,
    name: "Заказы оптом",
    imagePath: "assets/banners/orders.png",
    color: Colors.purple,
  ),
  ChoseClass(
    id: 16,
    name: "Покупатели",
    imagePath: "assets/banners/customers.png",
    color: Colors.orange,
  ),
  ChoseClass(
    categoryId: "e47af4dd-adcf-49f5-8fbd-91abd5e52f70",
    id: 10,
    name: "Фулфилмент",
    imagePath: "assets/banners/fulfillment.png",
    color: Colors.purple,
  ),
];

List<ChoseClass> listChooseWithoutOrders = [
  ChoseClass(
      id: 4, name: "От поставщиков", imagePath: "assets/types/postavshiki.png"),
  ChoseClass(
      id: 8,
      name: "От производителей",
      imagePath: "assets/types/manufacture.png"),
];

List<ChoseClass> combinedList = [
  ...listProviderAndManufacturer.map((item) =>
      ChoseClass(id: item.id, name: item.name, imagePath: item.imagePath)),
];
List<ChoseClass> combinedListFavorite = [
  ...listMainPostTypeFavorite
      .map((item) => ChoseClass(id: item.id, name: item.name)),
];
List<ChoseClass> combinedListWithoutOrders = [
  ...listChooseWithoutOrders
      .map((item) => ChoseClass(id: item.id, name: item.name)),
];
