import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat In-App Purchase Service for NameDrill
/// 
/// ## Setup Instructions:
/// 
/// 1. Create a RevenueCat account at https://app.revenuecat.com
/// 
/// 2. Create a new project in RevenueCat dashboard
/// 
/// 3. Configure your app stores:
///    - **App Store Connect**: Create an in-app purchase product with ID 'namedrill_premium'
///      (non-consumable, $4.99). Add the App Store shared secret to RevenueCat.
///    - **Google Play Console**: Create an in-app product with ID 'namedrill_premium'
///      (one-time purchase, $4.99). Link your Google Play service credentials.
/// 
/// 4. In RevenueCat dashboard:
///    - Create a Product: 'namedrill_premium' (map to both stores)
///    - Create an Entitlement: 'premium' 
///    - Create an Offering: 'default' containing the premium product
/// 
/// 5. Get your API keys from RevenueCat > Project Settings > API Keys:
///    - Copy the Apple API Key (for iOS)
///    - Copy the Google API Key (for Android)
/// 
/// 6. Replace the placeholder keys below with your actual keys

class PurchaseService {
  // ==========================================================================
  // IMPORTANT: Replace these with your actual RevenueCat API keys
  // Get them from: RevenueCat Dashboard > Project Settings > API Keys
  // ==========================================================================
  static const String _appleApiKey = 'YOUR_REVENUECAT_APPLE_API_KEY';
  static const String _googleApiKey = 'YOUR_REVENUECAT_GOOGLE_API_KEY';
  
  /// The entitlement ID configured in RevenueCat dashboard
  static const String _premiumEntitlementId = 'premium';
  
  /// The product ID for the premium one-time purchase
  static const String premiumProductId = 'namedrill_premium';

  static PurchaseService? _instance;
  static PurchaseService get instance => _instance ??= PurchaseService._();
  
  PurchaseService._();

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;
  
  /// Stream controller for purchase state changes
  final _purchaseStateController = StreamController<bool>.broadcast();
  
  /// Stream of premium status changes
  Stream<bool> get premiumStatusStream => _purchaseStateController.stream;

  /// Initialize RevenueCat SDK
  /// Call this early in app startup (e.g., in main.dart)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Configure RevenueCat based on platform
      late PurchasesConfiguration configuration;
      
      if (defaultTargetPlatform == TargetPlatform.iOS || 
          defaultTargetPlatform == TargetPlatform.macOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else {
        debugPrint('PurchaseService: Unsupported platform');
        return;
      }
      
      await Purchases.configure(configuration);
      
      // Listen for customer info updates
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _purchaseStateController.add(isPremiumFromInfo(customerInfo));
      });
      
      // Get initial customer info
      _customerInfo = await Purchases.getCustomerInfo();
      
      _isInitialized = true;
      debugPrint('PurchaseService: Initialized successfully');
    } catch (e) {
      debugPrint('PurchaseService: Failed to initialize - $e');
    }
  }

  /// Check if user has premium entitlement from CustomerInfo
  bool isPremiumFromInfo(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(_premiumEntitlementId);
  }

  /// Check if user currently has premium access
  Future<bool> isPremium() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _customerInfo = customerInfo;
      return isPremiumFromInfo(customerInfo);
    } catch (e) {
      debugPrint('PurchaseService: Error checking premium status - $e');
      // Fall back to cached info if available
      if (_customerInfo != null) {
        return isPremiumFromInfo(_customerInfo!);
      }
      return false;
    }
  }

  /// Get the current offerings (products available for purchase)
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('PurchaseService: Error getting offerings - $e');
      return null;
    }
  }

  /// Get the premium package from the default offering
  Future<Package?> getPremiumPackage() async {
    final offerings = await getOfferings();
    
    if (offerings == null || offerings.current == null) {
      debugPrint('PurchaseService: No current offering available');
      return null;
    }
    
    // Try to find the lifetime/premium package
    return offerings.current!.lifetime ?? 
           offerings.current!.availablePackages.firstOrNull;
  }

  /// Purchase the premium product
  /// Returns true if purchase was successful, false otherwise
  Future<PurchaseOperationResult> purchasePremium() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final package = await getPremiumPackage();
      
      if (package == null) {
        return PurchaseOperationResult(
          success: false,
          error: 'Premium package not available. Please try again later.',
        );
      }
      
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;
      _customerInfo = customerInfo;
      
      final isPremium = isPremiumFromInfo(customerInfo);
      _purchaseStateController.add(isPremium);
      
      return PurchaseOperationResult(
        success: isPremium,
        error: isPremium ? null : 'Purchase completed but premium not activated.',
      );
    } on PurchasesErrorCode catch (e) {
      return _handlePurchaseError(e);
    } catch (e) {
      debugPrint('PurchaseService: Purchase error - $e');
      return PurchaseOperationResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Restore previous purchases
  /// Returns true if premium was restored, false otherwise
  Future<PurchaseOperationResult> restorePurchases() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      
      final isPremium = isPremiumFromInfo(customerInfo);
      _purchaseStateController.add(isPremium);
      
      if (isPremium) {
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
    } on PurchasesErrorCode catch (e) {
      return _handlePurchaseError(e);
    } catch (e) {
      debugPrint('PurchaseService: Restore error - $e');
      return PurchaseOperationResult(
        success: false,
        error: 'Failed to restore purchases. Please try again.',
      );
    }
  }

  /// Get formatted price string for display
  Future<String> getPremiumPrice() async {
    final package = await getPremiumPackage();
    return package?.storeProduct.priceString ?? '\$4.99';
  }

  PurchaseOperationResult _handlePurchaseError(PurchasesErrorCode errorCode) {
    String message;
    
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        message = 'Purchase was cancelled.';
        break;
      case PurchasesErrorCode.storeProblemError:
        message = 'There was a problem with the app store. Please try again.';
        break;
      case PurchasesErrorCode.purchaseNotAllowedError:
        message = 'Purchases are not allowed on this device.';
        break;
      case PurchasesErrorCode.purchaseInvalidError:
        message = 'The purchase was invalid. Please try again.';
        break;
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        message = 'This product is not available for purchase.';
        break;
      case PurchasesErrorCode.productAlreadyPurchasedError:
        message = 'You already own this product. Try restoring purchases.';
        break;
      case PurchasesErrorCode.networkError:
        message = 'Network error. Please check your connection and try again.';
        break;
      default:
        message = 'An error occurred. Please try again.';
    }
    
    debugPrint('PurchaseService: Error code $errorCode - $message');
    return PurchaseOperationResult(success: false, error: message);
  }

  /// Clean up resources
  void dispose() {
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
