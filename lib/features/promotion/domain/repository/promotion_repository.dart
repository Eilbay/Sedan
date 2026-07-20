import 'package:optombai/features/promotion/data/models/create_campaign_request.dart';
import 'package:optombai/features/promotion/data/models/promotion_campaign_model.dart';
import 'package:optombai/features/promotion/data/models/promotion_package_model.dart';

abstract class PromotionRepository {
  Future<List<PromotionPackageModel>> getPackages();
  Future<CreateCampaignResponse> createCampaign(CreateCampaignRequest request);
  Future<List<PromotionCampaignModel>> getMyCampaigns();
  Future<PromotionCampaignModel?> getActiveCampaignForPost(String postId);
  Future<void> recordImpression(String postId, String placement);
  Future<void> cancelCampaign(int campaignId);
}
