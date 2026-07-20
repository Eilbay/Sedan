import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/data/repositories/i_iap_repository.dart';
import 'package:optombai/data/repositories/iap_repository.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late final IIapRepository _iapRepository;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _initialized = false;
  bool _available = false;
  bool get isAvailable => _available;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  static const String weeklySubscriptionId = 'business_weekly';
  static const String monthlySubscriptionId = 'business_monthly';

  static const String pit500Id = 'ad_wallet_500';
  static const String pit1000Id = 'ad_wallet_1000';
  static const String pit2000Id = 'ad_wallet_2000';
  static const String pit5000Id = 'ad_wallet_5000';

  static const Set<String> pitProductIds = {
    pit500Id,
    pit1000Id,
    pit2000Id,
    pit5000Id,
  };

  static const Map<String, double> pitProductAmounts = {
    pit500Id: 500,
    pit1000Id: 1000,
    pit2000Id: 2000,
    pit5000Id: 5000,
  };

  final Set<String> _productIds = {
    weeklySubscriptionId,
    monthlySubscriptionId,
    ...pitProductIds,
  };

  // Callbacks for purchase events
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;
  Function()? onPurchasePending;

  // Callback for restored purchases at app startup
  Function(PurchaseDetails)? onRestoredPurchase;

  // Store pending restored purchases until handler is set
  final List<PurchaseDetails> _pendingRestoredPurchases = [];

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _iapRepository = getIt<IIapRepository>();

    debugPrint('IAPService: Starting initialization...');
    _available = await _iap.isAvailable();
    debugPrint('IAPService: Store available: $_available');
    if (!_available) {
      debugPrint(
        'IAPService: Store not available - '
        'check App Store Connect agreements',
      );
      return;
    }

    if (Platform.isIOS) {
      final iosPlatformAddition =
          _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    }

    _listenToPurchaseStream();
    await loadProducts();
  }

  /// Whether the purchase stream is actively listening.
  bool get isPurchaseStreamActive => _subscription != null;

  void _listenToPurchaseStream() {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseDone,
      onError: _onPurchaseStreamError,
    );
    debugPrint('IAPService: Purchase stream subscription created');
  }

  Future<void> loadProducts() async {
    if (!_available) return;

    final response = await _iap.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAPService: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('IAPService: Loaded ${_products.length} products');
    for (final product in _products) {
      debugPrint('IAPService: Product: ${product.id} - ${product.price}');
    }
  }

  ProductDetails? getWeeklyProduct() {
    try {
      return _products.firstWhere((p) => p.id == weeklySubscriptionId);
    } catch (_) {
      return null;
    }
  }

  ProductDetails? getMonthlyProduct() {
    try {
      return _products.firstWhere((p) => p.id == monthlySubscriptionId);
    } catch (_) {
      return null;
    }
  }

  List<ProductDetails> getPitProducts() {
    return _products.where((p) => pitProductIds.contains(p.id)).toList()
      ..sort((a, b) {
        final amountA = pitProductAmounts[a.id] ?? 0;
        final amountB = pitProductAmounts[b.id] ?? 0;
        return amountA.compareTo(amountB);
      });
  }

  ProductDetails? getPitProductByAmount(double amount) {
    final productId = pitProductAmounts.entries
        .where((e) => e.value == amount)
        .map((e) => e.key)
        .firstOrNull;
    if (productId == null) return null;
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  static bool isPitProduct(String productId) {
    return pitProductIds.contains(productId);
  }

  static double? getPitAmount(String productId) {
    return pitProductAmounts[productId];
  }

  Future<bool> buyProduct(ProductDetails product) async {
    debugPrint('IAPService: buyProduct called for ${product.id}');

    if (!_available) {
      onPurchaseError?.call('Покупки недоступны');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('IAPService: Purchase error: $e');
      onPurchaseError?.call('Ошибка покупки: $e');
      return false;
    }
  }

  Future<bool> buyConsumable(ProductDetails product) async {
    debugPrint('IAPService: buyConsumable called for ${product.id}');

    if (!_available) {
      onPurchaseError?.call('Покупки недоступны');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('IAPService: Consumable purchase error: $e');
      onPurchaseError?.call('Ошибка покупки: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      debugPrint(
        'IAPService: Purchase update: ${purchase.productID}, '
        'status: ${purchase.status}',
      );
      _handlePurchase(purchase);
    }
  }

  /// Handles purchase status updates.
  ///
  /// IMPORTANT: For [PurchaseStatus.purchased] and [PurchaseStatus.restored],
  /// [completePurchase] is NOT called here. The caller must call
  /// [finishPurchase] AFTER server-side receipt validation succeeds.
  /// This ensures Apple's requirement: validate first, then finish transaction.
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        debugPrint('IAPService: Purchase pending');
        onPurchasePending?.call();
        break;

      case PurchaseStatus.purchased:
        debugPrint(
          'IAPService: Purchase successful: ${purchase.productID}',
        );
        // Delegate to callback — caller must call finishPurchase() after
        // validating the receipt on the server.
        onPurchaseSuccess?.call(purchase);
        break;

      case PurchaseStatus.restored:
        debugPrint('IAPService: Restored purchase: ${purchase.productID}');
        if (onPurchaseSuccess != null) {
          onPurchaseSuccess?.call(purchase);
        } else if (onRestoredPurchase != null) {
          onRestoredPurchase?.call(purchase);
        } else {
          _pendingRestoredPurchases.add(purchase);
        }
        break;

      case PurchaseStatus.error:
        debugPrint('IAPService: Purchase error: ${purchase.error}');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        onPurchaseError?.call(purchase.error?.message ?? 'Ошибка покупки');
        break;

      case PurchaseStatus.canceled:
        debugPrint('IAPService: Purchase canceled');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        onPurchaseError?.call('Покупка отменена');
        break;
    }
  }

  /// Finishes a purchase transaction with the store.
  ///
  /// Call this AFTER successful server-side receipt validation.
  /// Apple requires all transactions to be finished eventually.
  Future<void> finishPurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
      debugPrint('IAPService: Transaction finished: ${purchase.productID}');
    }
  }

  void setRestoredPurchaseHandler(Function(PurchaseDetails) handler) {
    onRestoredPurchase = handler;

    if (_pendingRestoredPurchases.isNotEmpty) {
      debugPrint(
        'IAPService: Processing ${_pendingRestoredPurchases.length} '
        'pending restored purchases',
      );
      for (final purchase in _pendingRestoredPurchases) {
        handler(purchase);
      }
      _pendingRestoredPurchases.clear();
    }
  }

  bool get hasPendingRestoredPurchases => _pendingRestoredPurchases.isNotEmpty;

  List<String> get pendingRestoredProductIds =>
      _pendingRestoredPurchases.map((p) => p.productID).toList();

  void _onPurchaseDone() {
    debugPrint('IAPService: Purchase stream closed, reconnecting...');
    _listenToPurchaseStream();
  }

  void _onPurchaseStreamError(dynamic error) {
    debugPrint('IAPService: Stream error: $error');
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  Future<IAPValidationResult> validatePurchase({
    required PurchaseDetails purchase,
    required String token,
  }) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final receiptData = purchase.verificationData.serverVerificationData;

    debugPrint('IAPService: Validating purchase ${purchase.productID}');

    final result = await _iapRepository.validateReceipt(
      receiptData: receiptData,
      productId: purchase.productID,
      platform: platform,
      transactionId: purchase.purchaseID ?? '',
      token: token,
      packageName: 'com.eilbay.kitaydan',
    );

    debugPrint('IAPService: Validation result: ${result.isValid}');
    if (!result.isValid) {
      debugPrint('IAPService: Validation error: ${result.error}');
    }

    return result;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
