import 'package:dio/dio.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/features/promotion/data/models/create_campaign_request.dart';
import 'package:optombai/features/promotion/data/models/promotion_campaign_model.dart';
import 'package:optombai/features/promotion/data/models/promotion_package_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromotionRemoteDataSource {
  PromotionRemoteDataSource(this._dio, this.preferences);

  final Dio _dio;
  final SharedPreferences preferences;

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Options headers() => Options(
        headers: {
          'Authorization': 'Bearer ${getToken()}',
          'Content-Type': 'application/json',
        },
      );

  Future<List<PromotionPackageModel>> getPackages() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.targetPackages,
        options: headers(),
      );

      final data = res.data as List<dynamic>;
      return data
          .map((e) => PromotionPackageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CreateCampaignResponse> createCampaign(
      CreateCampaignRequest request) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.targetCampaigns,
        data: request.toJson(),
        options: headers(),
      );

      return CreateCampaignResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<PromotionCampaignModel>> getMyCampaigns() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.targetCampaignsMe,
        options: headers(),
      );

      // GET /target/campaigns/me/ returns a bare JSON array, not a
      // wrapped {items: [...]} envelope.
      final body = res.data;
      final data = body is List ? body : const <dynamic>[];
      return data
          .map(
              (e) => PromotionCampaignModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PromotionCampaignModel?> getActiveCampaignForPost(
      String postId) async {
    final campaigns = await getMyCampaigns();
    try {
      return campaigns.firstWhere(
        (c) => c.postId == postId && c.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> recordImpression(String postId, String placement) async {
    try {
      await _dio.post(
        ApiEndpoints.targetImpressions,
        data: {
          'post_id': postId,
          'placement': placement,
        },
        options: headers(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> cancelCampaign(int campaignId) async {
    try {
      await _dio.post(
        ApiEndpoints.targetCampaignCancel(campaignId),
        data: {},
        options: headers(),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 403 || code == 404 || code == 405) {
        try {
          await _dio.post(
            ApiEndpoints.targetAdminCampaignCancel(campaignId),
            data: {},
            options: headers(),
          );
          return;
        } on DioException catch (e2) {
          throw ErrorHandler.handle(e2);
        }
      }
      throw ErrorHandler.handle(e);
    }
  }
}
