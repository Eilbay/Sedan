import 'package:optombai/data/models/pit/pit_model.dart';

abstract interface class IPitRepository {
  Future<PitModel> getMyPit(String token);

  Future<PitInitResponse> initPit({
    required double amount,
    required String provider,
    String currency = 'KGS',
    required String token,
  });

  Future<IAPPitResponse> pitViaIAP({
    required String receiptData,
    required String productId,
    required String platform,
    required String transactionId,
    required String token,
  });
}
