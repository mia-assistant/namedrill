import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/purchase_service.dart';

/// Provider for the PurchaseService singleton
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService.instance;
});

/// State for purchase operations
enum PurchaseStatus {
  idle,
  loading,
  success,
  error,
}

class PurchaseState {
  final bool isPremium;
  final PurchaseStatus status;
  final String? errorMessage;
  final String? successMessage;
  final String priceString;
  final bool isInitialized;

  const PurchaseState({
    this.isPremium = false,
    this.status = PurchaseStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.priceString = '\$4.99',
    this.isInitialized = false,
  });

  PurchaseState copyWith({
    bool? isPremium,
    PurchaseStatus? status,
    String? errorMessage,
    String? successMessage,
    String? priceString,
    bool? isInitialized,
  }) {
    return PurchaseState(
      isPremium: isPremium ?? this.isPremium,
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      priceString: priceString ?? this.priceString,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Riverpod provider for managing purchase state
final purchaseStateProvider = StateNotifierProvider<PurchaseStateNotifier, PurchaseState>((ref) {
  return PurchaseStateNotifier(ref);
});

class PurchaseStateNotifier extends StateNotifier<PurchaseState> {
  final Ref _ref;
  StreamSubscription<bool>? _premiumSubscription;

  PurchaseStateNotifier(this._ref) : super(const PurchaseState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final purchaseService = _ref.read(purchaseServiceProvider);
    
    try {
      await purchaseService.initialize();
      
      // Listen for premium status changes
      _premiumSubscription = purchaseService.premiumStatusStream.listen((isPremium) {
        state = state.copyWith(isPremium: isPremium);
      });
      
      // Check initial premium status
      final isPremium = purchaseService.isPremium;
      final price = await purchaseService.getPremiumPrice();
      
      state = state.copyWith(
        isPremium: isPremium,
        priceString: price,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        errorMessage: 'Failed to initialize purchases',
      );
    }
  }

  /// Refresh premium status
  Future<void> refreshPremiumStatus() async {
    final purchaseService = _ref.read(purchaseServiceProvider);
    final isPremium = await purchaseService.checkPremium();
    state = state.copyWith(isPremium: isPremium);
  }

  /// Purchase premium
  Future<bool> purchasePremium() async {
    state = state.copyWith(
      status: PurchaseStatus.loading,
      errorMessage: null,
      successMessage: null,
    );
    
    final purchaseService = _ref.read(purchaseServiceProvider);
    final result = await purchaseService.purchasePremium();
    
    if (result.success) {
      state = state.copyWith(
        isPremium: true,
        status: PurchaseStatus.success,
        successMessage: 'Premium unlocked! Thank you for your support!',
      );
      return true;
    } else {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: result.error,
      );
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    state = state.copyWith(
      status: PurchaseStatus.loading,
      errorMessage: null,
      successMessage: null,
    );
    
    final purchaseService = _ref.read(purchaseServiceProvider);
    final result = await purchaseService.restorePurchases();
    
    if (result.success) {
      state = state.copyWith(
        isPremium: true,
        status: PurchaseStatus.success,
        successMessage: result.message ?? 'Purchases restored successfully!',
      );
      return true;
    } else {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: result.error,
      );
      return false;
    }
  }

  /// Clear any error/success messages
  void clearMessages() {
    state = state.copyWith(
      status: PurchaseStatus.idle,
      errorMessage: null,
      successMessage: null,
    );
  }

  @override
  void dispose() {
    _premiumSubscription?.cancel();
    super.dispose();
  }
}

/// Convenience provider for checking if user is premium from store
final isPremiumStoreProvider = Provider<bool>((ref) {
  final purchaseState = ref.watch(purchaseStateProvider);
  return purchaseState.isPremium;
});
