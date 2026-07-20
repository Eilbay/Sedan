import 'package:optombai/data/models/market/market_model.dart';

abstract interface class IMarketRepository {
  Future<List<MarketModel>> getMarkets();

  Future<List<SupplierRequestModel>> getMySupplierRequests(String token);

  Future<void> createSupplierRequest(String token, int marketId);

  Future<Map<String, dynamic>?> getSupplierByUsername(
    String token,
    String username, {
    int limit = 20,
    int offset = 0,
  });
}
