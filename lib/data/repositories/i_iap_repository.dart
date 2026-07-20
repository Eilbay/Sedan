import 'package:optombai/data/repositories/iap_repository.dart';

abstract interface class IIapRepository {
  Future<IAPValidationResult> validateReceipt({
    required String receiptData,
    required String productId,
    required String platform,
    required String transactionId,
    required String token,
    required String packageName,
  });
}
