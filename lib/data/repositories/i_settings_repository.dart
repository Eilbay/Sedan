import 'package:optombai/data/models/countries/countries.dart';
import 'package:optombai/data/models/currency/currency_model.dart';
import 'package:optombai/data/models/question/question_model.dart';
import 'package:optombai/data/models/banner/settings_banners_model.dart';

abstract interface class ISettingsRepository {
  Future<void> createQuestion(QuestionModel question, String token);

  Future<List<CurrencyModel>> getCurrency(String token);

  Future<List<BannerModel>> getBanner();

  Future<List<CountryModel>> getCountry();
}
