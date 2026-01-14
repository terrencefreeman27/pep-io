import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Service for managing premium subscription state via RevenueCat
/// This handles the business logic for premium features:
/// - Unlimited protocols (free users limited to 3)
/// - Medium & Large widgets
/// - AI Insights feature
class PremiumService extends ChangeNotifier {
  /// Maximum protocols for free users
  static const int freeProtocolLimit = 3;
  
  /// RevenueCat entitlement identifier (must match RevenueCat dashboard)
  static const String premiumEntitlementId = 'Pep io Pro';
  
  bool _isPremium = false;
  bool _isLoading = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  
  /// Get subscription expiry date if available
  DateTime? get subscriptionExpiry {
    final entitlement = _customerInfo?.entitlements.all[premiumEntitlementId];
    if (entitlement?.expirationDate != null) {
      return DateTime.tryParse(entitlement!.expirationDate!);
    }
    return null;
  }
  
  /// Check if user can create more protocols
  bool canCreateProtocol(int currentProtocolCount) {
    if (_isPremium) return true;
    return currentProtocolCount < freeProtocolLimit;
  }
  
  /// Get remaining protocols user can create
  int remainingProtocols(int currentProtocolCount) {
    if (_isPremium) return -1; // -1 means unlimited
    return (freeProtocolLimit - currentProtocolCount).clamp(0, freeProtocolLimit);
  }
  
  /// Check if user can use medium/large widgets
  bool get canUseMediumWidget => _isPremium;
  bool get canUseLargeWidget => _isPremium;
  
  /// Check if user can access AI Insights
  bool get canAccessAIInsights => _isPremium;
  
  /// Initialize the service and listen to RevenueCat updates
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener(_handleCustomerInfoUpdate);
      
      // Get current customer info
      final customerInfo = await Purchases.getCustomerInfo();
      _handleCustomerInfoUpdate(customerInfo);
      
      // Load available offerings
      await loadOfferings();
    } catch (e) {
      debugPrint('PremiumService: Error initializing: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Handle customer info updates from RevenueCat
  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    final entitlement = customerInfo.entitlements.all[premiumEntitlementId];
    final newIsPremium = entitlement?.isActive ?? false;
    
    if (newIsPremium != _isPremium) {
      _isPremium = newIsPremium;
      debugPrint('PremiumService: Premium status changed to $_isPremium');
      notifyListeners();
    }
  }
  
  /// Load available subscription offerings
  Future<void> loadOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      debugPrint('PremiumService: Loaded ${_offerings?.all.length ?? 0} offerings');
    } catch (e) {
      debugPrint('PremiumService: Error loading offerings: $e');
    }
  }
  
  /// Get available packages for purchase
  List<Package> get availablePackages {
    return _offerings?.current?.availablePackages ?? [];
  }
  
  /// Get monthly package if available
  Package? get monthlyPackage {
    return _offerings?.current?.monthly;
  }
  
  /// Get yearly package if available
  Package? get yearlyPackage {
    return _offerings?.current?.annual;
  }
  
  /// Purchase a subscription package
  Future<bool> purchasePackage(Package package) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _handleCustomerInfoUpdate(customerInfo);
      return _isPremium;
    } on PurchasesErrorCode catch (e) {
      debugPrint('PremiumService: Purchase error: $e');
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false; // User cancelled, not an error
      }
      rethrow;
    } catch (e) {
      debugPrint('PremiumService: Purchase failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final customerInfo = await Purchases.restorePurchases();
      _handleCustomerInfoUpdate(customerInfo);
      return _isPremium;
    } catch (e) {
      debugPrint('PremiumService: Restore failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get price string for a package
  String getPriceString(Package package) {
    return package.storeProduct.priceString;
  }
  
  /// Get formatted subscription period
  String getSubscriptionPeriod(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'month';
      case PackageType.annual:
        return 'year';
      case PackageType.weekly:
        return 'week';
      case PackageType.lifetime:
        return 'lifetime';
      default:
        return '';
    }
  }
  
  // ============================================
  // DEBUG/TESTING METHODS (Remove in production)
  // ============================================
  
  /// Toggle premium status for testing (only works in debug mode)
  Future<void> debugTogglePremium() async {
    if (kDebugMode) {
      _isPremium = !_isPremium;
      debugPrint('PremiumService: Debug toggle - Premium is now $_isPremium');
      notifyListeners();
    }
  }
}

/// Premium feature types
enum PremiumFeature {
  unlimitedProtocols,
  mediumWidget,
  largeWidget,
  aiInsights,
  advancedAnalytics,
  calendarSync,
  prioritySupport,
}

extension PremiumFeatureExtension on PremiumFeature {
  String get title {
    switch (this) {
      case PremiumFeature.unlimitedProtocols:
        return 'Unlimited Protocols';
      case PremiumFeature.mediumWidget:
        return 'Medium Widget';
      case PremiumFeature.largeWidget:
        return 'Large Widget';
      case PremiumFeature.aiInsights:
        return 'AI Insights';
      case PremiumFeature.advancedAnalytics:
        return 'Advanced Analytics';
      case PremiumFeature.calendarSync:
        return 'Calendar Sync';
      case PremiumFeature.prioritySupport:
        return 'Priority Support';
    }
  }
  
  String get description {
    switch (this) {
      case PremiumFeature.unlimitedProtocols:
        return 'Track unlimited protocols simultaneously';
      case PremiumFeature.mediumWidget:
        return 'Medium-sized home screen widget';
      case PremiumFeature.largeWidget:
        return 'Large home screen widget with full details';
      case PremiumFeature.aiInsights:
        return 'AI-powered insights for your protocols';
      case PremiumFeature.advancedAnalytics:
        return 'Deep insights into your progress';
      case PremiumFeature.calendarSync:
        return 'Sync doses to Apple Calendar';
      case PremiumFeature.prioritySupport:
        return 'Get help when you need it';
    }
  }
}
