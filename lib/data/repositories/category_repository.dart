import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/repositories/i_category_repository.dart';

class CategoryRepository implements ICategoryRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<List<Category>> fetchData({List<int>? categoryTypes}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.categoriesApi,
        queryParameters: {
          if (categoryTypes != null && categoryTypes.isNotEmpty)
            'category_type': categoryTypes,
        },
      );

      return response.data
          .map((item) => Category.fromJson(item))
          .cast<Category>()
          .toList();
    } on DioException {
      // Safe fallback: return empty list on error
      return [];
    }
  }

  Future<Category> fetchCategory(String id) async {
    try {
      final response = await _dio.get("${ApiEndpoints.categoriesApi}$id/");
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
