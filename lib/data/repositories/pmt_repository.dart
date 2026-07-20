import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/pmt/pmt_model.dart';
import 'package:optombai/data/repositories/i_pmt_repository.dart';

class PmtRepository implements IPmtRepository {
  final Dio _dio = ApiClient.I.dio;
  String get pmtEndpoint => '${ApiEndpoints.accountsApi}/payments/';
  String get pmtStatusEndpoint => '${ApiEndpoints.accountsApi}/payments/status/';

  Future<List<PmtModel>> getPmtHistory(String token) async {
    try {
      final response = await _dio.get(pmtEndpoint, options: options(token));
      return response.data["results"]
          .map<PmtModel>((item) => PmtModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PmtModel> createPmt(PmtModel pmt, String token) async {
    try {
      final response = await _dio.post(pmtEndpoint,
          data: pmt.toJson(), options: options(token));
      return PmtModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PmtModel> patchPmtStatus(String pmtId, String token) async {
    try {
      final response = await _dio.patch(
        "$pmtEndpoint$pmtId/",
        data: {"status": "success"},
        options: options(token),
      );
      return PmtModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response?> getPmtStatus(String token) async {
    try {
      final response = await _dio.get(
        pmtStatusEndpoint,
        options: options(token),
      );
      return response;
    } on DioException catch (e) {
      final appException = ErrorHandler.handle(e);
      if (appException is NotFoundException) return null;
      throw appException;
    }
  }

  Future<PmtModel> updatePmtStatus(String pmtId, String status, String amount,
      String pmtMethod, String token) async {
    try {
      final response = await _dio.put(
        "$pmtEndpoint$pmtId/",
        data: {
          "payment_id": pmtId,
          "status": "success",
          "amount": amount,
          "payment_method": pmtMethod
        },
        options: options(token),
      );
      return PmtModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> updateUserStatus(
      String pmtId, String premiumId, String token) async {
    try {
      final String statusUpdateEndpoint = "${ApiEndpoints.accountsApi}/statuses/";

      await _dio.put(
        statusUpdateEndpoint,
        data: {
          "payment_id": pmtId,
          "premium_id": premiumId,
        },
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PmtModel> getPmtById(String pmtId, String token) async {
    try {
      final response = await _dio.get(
        "$pmtEndpoint$pmtId/",
        options: options(token),
      );
      return PmtModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  String getPmtRedirectUrl(String pmtId) {
    return ApiEndpoints.freedomPayRedirect(pmtId);
  }
}
