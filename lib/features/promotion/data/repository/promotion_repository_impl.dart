import 'package:optombai/features/promotion/data/data_sources/promotion_remote_data_source.dart';
import 'package:optombai/features/promotion/data/models/create_campaign_request.dart';
import 'package:optombai/features/promotion/data/models/promotion_campaign_model.dart';
import 'package:optombai/features/promotion/data/models/promotion_package_model.dart';
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  PromotionRepositoryImpl(this._dataSource);

  final PromotionRemoteDataSource _dataSource;

  @override
  Future<List<PromotionPackageModel>> getPackages() {
    return _dataSource.getPackages();
  }

  @override
  Future<CreateCampaignResponse> createCampaign(CreateCampaignRequest request) {
    return _dataSource.createCampaign(request);
  }

  @override
  Future<List<PromotionCampaignModel>> getMyCampaigns() {
    return _dataSource.getMyCampaigns();
  }

  @override
  Future<PromotionCampaignModel?> getActiveCampaignForPost(String postId) {
    return _dataSource.getActiveCampaignForPost(postId);
  }

  @override
  Future<void> recordImpression(String postId, String placement) {
    return _dataSource.recordImpression(postId, placement);
  }

  @override
  Future<void> cancelCampaign(int campaignId) =>
      _dataSource.cancelCampaign(campaignId);
}
