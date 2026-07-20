import 'package:optombai/data/models/category/category_model.dart';

abstract interface class ICategoryRepository {
  Future<List<Category>> fetchData({List<int>? categoryTypes});

  Future<Category> fetchCategory(String id);
}
