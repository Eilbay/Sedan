import 'package:dio/dio.dart';

extension DioErrorExtension on DioException {
  List<String> get messageErrors {
    try {
      final errorResponse = response;
      if (errorResponse == null) {
        return ['Проблема с сетью'];
      }
      if (errorResponse.statusCode == 403) {
        return ['Пожалуйста авторизуйтесь!'];
      }
      final Map<String, dynamic> data = errorResponse.data;
      try {
        final values =
            data.values.map((e) => List.from(e).cast<String>()).toList();
        final List<String> errors = [];
        for (final element in values) {
          errors.addAll(element);
        }
        return errors;
      } catch (_) {
        return data.values.map((e) => e).cast<String>().toList();
      }
    } catch (_) {
      return ['Неизвестная ошибка!'];
    }
  }

  bool get isExitRequired => response?.statusCode == 403;
}
