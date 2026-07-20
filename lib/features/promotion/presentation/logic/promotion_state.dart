part of 'promotion_cubit.dart';

enum PromotionStatus { initial, loading, success, error, insufficientBalance }

class PromotionState {
  const PromotionState({
    this.status = PromotionStatus.initial,
    this.packages = const [],
    this.selectedPackage,
    this.myCampaigns = const [],
    this.activeCampaignForCurrentPost,
    this.errorMessage,
    this.currentPostId,
    this.lastResponse,
  });

  final PromotionStatus status;
  final List<PromotionPackageModel> packages;
  final PromotionPackageModel? selectedPackage;
  final List<PromotionCampaignModel> myCampaigns;
  final PromotionCampaignModel? activeCampaignForCurrentPost;
  final String? errorMessage;
  final String? currentPostId;
  final CreateCampaignResponse? lastResponse;

  double get totalPrice => selectedPackage?.priceTotal ?? 0;

  ReachRange get estimatedReach {
    if (selectedPackage == null) return const ReachRange(from: 0, to: 0);
    return selectedPackage!.reach;
  }

  bool get canPromote => activeCampaignForCurrentPost == null;

  bool get isLoading => status == PromotionStatus.loading;

  PromotionState copyWith({
    PromotionStatus? status,
    List<PromotionPackageModel>? packages,
    PromotionPackageModel? selectedPackage,
    List<PromotionCampaignModel>? myCampaigns,
    PromotionCampaignModel? activeCampaignForCurrentPost,
    String? errorMessage,
    String? currentPostId,
    CreateCampaignResponse? lastResponse,
  }) {
    return PromotionState(
      status: status ?? this.status,
      packages: packages ?? this.packages,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      myCampaigns: myCampaigns ?? this.myCampaigns,
      activeCampaignForCurrentPost:
          activeCampaignForCurrentPost ?? this.activeCampaignForCurrentPost,
      errorMessage: errorMessage,
      currentPostId: currentPostId ?? this.currentPostId,
      lastResponse: lastResponse ?? this.lastResponse,
    );
  }
}
