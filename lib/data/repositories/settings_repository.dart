import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/countries/countries.dart';
import 'package:optombai/data/models/currency/currency_model.dart';
import 'package:optombai/data/models/question/question_model.dart';

import 'package:optombai/data/models/banner/settings_banners_model.dart';
import 'package:optombai/data/repositories/i_settings_repository.dart';

final String urlCurrency = "${ApiEndpoints.settingsApi}currencies/";
final String urlBanner = "${ApiEndpoints.settingsApi}banners/";
final String urlQuestion = "${ApiEndpoints.settingsApi}question/";
final String urlCountry = "${ApiEndpoints.settingsApi}countries/";

class SettingsRepository implements ISettingsRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<void> createQuestion(QuestionModel question, String token) async {
    try {
      await _dio.post(urlQuestion,
          data: question.toJson(), options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<CurrencyModel>> getCurrency(String token) async {
    try {
      final response = await _dio.get(urlCurrency);

      final data = response.data;
      final list = (data is List ? data : data["results"]) ?? [];

      return list
          .map((item) => CurrencyModel.fromJson(item))
          .cast<CurrencyModel>()
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<BannerModel>> getBanner() async {
    try {
      final response = await _dio.get(urlBanner);

      final list = (response.data["results"] as List? ?? const [])
          .map((item) => BannerModel.fromJson(item))
          .cast<BannerModel>()
          .toList()
        // Admin-defined display order; id keeps ties stable across refreshes.
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<CountryModel>> getCountry() async {
    try {
      var response = await _dio.get(urlCountry);
      var list = response.data["results"]
          .map((item) => CountryModel.fromJson(item))
          .cast<CountryModel>()
          .toList();
      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
