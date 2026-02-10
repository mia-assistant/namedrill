import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Native In-App Purchase Service for NameDrill
///
/// Uses the official `in_app_purchase` plugin for direct
/// App Store / Google Play integration.
///
/// Product IDs:
///   iOS:     namedrill_premium
///   Android: namedrill_premium
class PurchaseService {
  // ---------------------------------------------------------------------------
  // Product identifiers
  // ---------------------------------------------------------------------------
  static const String _iosProductId = 'namedrill_premium';
  static const String _androidProductId = 'namedrill_premium';

  static String get productId =>
      Platform.isIOS ? _iosProductId : _androidProductId;

  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static PurchaseService? _instance;
  static PurchaseService get instance => _instance ??= PurchaseService._();

  PurchaseService._();

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isInitialized = false;
  bool _isAvailable = false;

  ProductDetails? _productDetails;
  bool _isPremium = false;

  /// Stream of premium-status changes
  final _purchaseStateController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _purchaseStateController.stream;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('PurchaseService: Store not available');
        _isInitialized = true;
        return;
      }

      // Listen for purchase updates
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) =>
            debugPrint('PurchaseService: purchaseStream error – $error'),
      );

      // Query the product
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isNotEmpty) {
        _productDetails = response.productDetails.first;
        debugPrint(
            'PurchaseService: Found product ${_productDetails!.id} – ${_productDetails!.price}');
      } else {
        debugPrint(
            'PurchaseService: Product not found. Errors: ${response.error}');
      }

      // Restore past purchases so we know current status
      await _iap.restorePurchases();

      _isInitialized = true;
      debugPrint('PurchaseService: Initialized successfully');
    } catch (e) {
      debugPrint('PurchaseService: Failed to initialize – $e');
      _isInitialized = true; // avoid retrying infinitely
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase stream handler
  // ---------------------------------------------------------------------------
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.productID != productId) return;

    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        _isPremium = true;
        _purchaseStateController.add(true);
        debugPrint(
            'PurchaseService: Premium ${purchase.status == PurchaseStatus.restored ? "restored" : "purchased"}');
        break;

      case PurchaseStatus.error:
        debugPrint(
            'PurchaseService: Purchase error – ${purchase.error?.message}');
        break;

      case PurchaseStatus.pending:
        debugPrint('PurchaseService: Purchase pending…');
        break;

      case PurchaseStatus.canceled:
        debugPrint('PurchaseService: Purchase cancelled');
        break;
    }

    // Complete the purchase so the store is happy
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether the store reported premium ownership
  bool get isPremium => _isPremium;

  /// Check freshest status (re-queries restore)
  Future<bool> checkPremium() async {
    if (!_isInitialized) await initialize();
    await _iap.restorePurchases();
    // Give the stream a tick to process
    await Future.delayed(const Duration(milliseconds: 500));
    return _isPremium;
  }

  /// Get the formatted price string for display
  String get priceString => _productDetails?.price ?? '';

  /// Purchase the premium product.
  Future<PurchaseOperationResult> purchasePremium() async {
    if (!_isInitialized) await initialize();

    if (!_isAvailable) {
      return PurchaseOperationResult(
        success: false,
        error: 'Store is not available on this device.',
      );
    }

    if (_productDetails == null) {
      return PurchaseOperationResult(
        success: false,
        error: 'Premium product not found. Please try again later.',
      );
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: _productDetails!);
      // Non-consumable purchase
      final started =
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      if (!started) {
        return PurchaseOperationResult(
          success: false,
          error: 'Could not initiate purchase. Please try again.',
        );
      }

      // Wait for the purchase stream to deliver a result (timeout 60 s)
      return await _waitForPurchaseResult();
    } catch (e) {
      debugPrint('PurchaseService: Purchase error – $e');
      return PurchaseOperationResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Restore previous purchases.
  Future<PurchaseOperationResult> restorePurchases() async {
    if (!_isInitialized) await initialize();

    if (!_isAvailable) {
      return PurchaseOperationResult(
        success: false,
        error: 'Store is not available on this device.',
      );
    }

    try {
      _isPremium = false; // reset before checking
      await _iap.restorePurchases();

      // Give the stream time to process restored purchases
      await Future.delayed(const Duration(seconds: 2));

      if (_isPremium) {
        return PurchaseOperationResult(
          success: true,
          message: 'Premium restored successfully!',
        );
      } else {
        return PurchaseOperationResult(
          success: false,
          error: 'No previous purchases found.',
        );
      }
    } catch (e) {
      debugPrint('PurchaseService: Restore error – $e');
      return PurchaseOperationResult(
        success: false,
        error: 'Failed to restore purchases. Please try again.',
      );
    }
  }

  /// Get formatted price string for display
  Future<String> getPremiumPrice() async {
    if (!_isInitialized) await initialize();
    return priceString;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Waits up to 60 s for the purchase stream to emit a result.
  Future<PurchaseOperationResult> _waitForPurchaseResult() async {
    final completer = Completer<PurchaseOperationResult>();
    late StreamSubscription<List<PurchaseDetails>> sub;

    sub = _iap.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        if (p.productID != productId) continue;

        if (p.status == PurchaseStatus.purchased) {
          if (!completer.isCompleted) {
            completer.complete(PurchaseOperationResult(
              success: true,
              message: 'Premium unlocked! Thank you!',
            ));
          }
          sub.cancel();
        } else if (p.status == PurchaseStatus.error) {
          if (!completer.isCompleted) {
            completer.complete(PurchaseOperationResult(
              success: false,
              error: p.error?.message ?? 'Purchase failed.',
            ));
          }
          sub.cancel();
        } else if (p.status == PurchaseStatus.canceled) {
          if (!completer.isCompleted) {
            completer.complete(PurchaseOperationResult(
              success: false,
              error: 'Purchase was cancelled.',
            ));
          }
          sub.cancel();
        }
      }
    });

    // Timeout after 60 seconds
    Future.delayed(const Duration(seconds: 60), () {
      if (!completer.isCompleted) {
        completer.complete(PurchaseOperationResult(
          success: false,
          error:
              'Purchase timed out. If you were charged, try Restore Purchase.',
        ));
        sub.cancel();
      }
    });

    return completer.future;
  }

  /// Clean up resources
  void dispose() {
    _subscription?.cancel();
    _purchaseStateController.close();
  }
}

/// Result of a purchase or restore operation
class PurchaseOperationResult {
  final bool success;
  final String? error;
  final String? message;

  PurchaseOperationResult({
    required this.success,
    this.error,
    this.message,
  });
}
