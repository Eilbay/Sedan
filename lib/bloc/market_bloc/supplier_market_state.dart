import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/market/market_model.dart';

class SupplierMarketState extends Equatable {
  final bool isLoading;
  final List<String> errors;

  final List<MarketModel> markets;
  final MarketModel? selectedMarket;

  final SupplierRequestModel? lastRequest;
  final MarketModel? approvedMarket;

  const SupplierMarketState({
    this.isLoading = false,
    this.errors = const [],
    this.markets = const [],
    this.selectedMarket,
    this.lastRequest,
    this.approvedMarket,
  });

  SupplierMarketState copyWith({
    bool? isLoading,
    List<String>? errors,
    List<MarketModel>? markets,
    MarketModel? selectedMarket,
    SupplierRequestModel? lastRequest,
    MarketModel? approvedMarket,
  }) {
    return SupplierMarketState(
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
      markets: markets ?? this.markets,
      selectedMarket: selectedMarket ?? this.selectedMarket,
      lastRequest: lastRequest ?? this.lastRequest,
      approvedMarket: approvedMarket ?? this.approvedMarket,
    );
  }

  bool get hasApproved => approvedMarket != null;
  bool get isPending => lastRequest?.status == SupplierRequestStatus.pending;
  bool get isRejected => lastRequest?.status == SupplierRequestStatus.rejected;
  bool get canSendRequest => lastRequest == null || isRejected;

  @override
  List<Object?> get props => [
        isLoading,
        errors,
        markets,
        selectedMarket,
        lastRequest,
        approvedMarket,
      ];
}
