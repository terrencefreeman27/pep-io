# Premium Features Setup Guide

This document explains how to set up in-app purchases for pep.io's premium features.

## Premium Features

The following features are locked behind the premium subscription:

1. **Unlimited Protocols** - Free users can create up to 3 protocols
2. **Medium & Large Widgets** - Premium users get access to larger home screen widgets
3. **AI Insights** - AI-powered protocol recommendations (coming soon)

## RevenueCat Integration (Recommended)

RevenueCat is the recommended solution for handling subscriptions as it:
- Handles both iOS (StoreKit) and Android (Google Play Billing)
- Provides a unified API
- Can connect to Stripe for web payments
- Offers analytics and webhooks

### Step 1: RevenueCat Account Setup

1. Create an account at [RevenueCat](https://www.revenuecat.com/)
2. Create a new project for pep.io
3. Note your **API Keys** (public keys for iOS and Android)

### Step 2: App Store Connect (iOS)

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to your app → Subscriptions
3. Create a Subscription Group (e.g., "Premium")
4. Add products:
   - `com.pepio.premium.monthly` - Monthly subscription
   - `com.pepio.premium.yearly` - Yearly subscription
5. Configure pricing, descriptions, and review information
6. In RevenueCat, connect your App Store Connect account and import products

### Step 3: Google Play Console (Android)

1. Go to [Google Play Console](https://play.google.com/console/)
2. Navigate to your app → Monetization → Products → Subscriptions
3. Create subscriptions matching iOS product IDs
4. Configure pricing and billing periods
5. In RevenueCat, connect your Google Play account and import products

### Step 4: Flutter Integration

1. The `purchases_flutter` package is already added to `pubspec.yaml`

2. Initialize RevenueCat in `main.dart`:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize RevenueCat
  await Purchases.setLogLevel(LogLevel.debug);
  
  PurchasesConfiguration configuration;
  if (Platform.isIOS) {
    configuration = PurchasesConfiguration('YOUR_REVENUECAT_IOS_API_KEY');
  } else if (Platform.isAndroid) {
    configuration = PurchasesConfiguration('YOUR_REVENUECAT_ANDROID_API_KEY');
  }
  
  await Purchases.configure(configuration);
  
  // ... rest of main()
}
```

3. Update `PremiumService` to use RevenueCat:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumService extends ChangeNotifier {
  // ...
  
  Future<void> initialize() async {
    // Listen to customer info updates
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updatePremiumStatus(customerInfo);
    });
    
    // Check current status
    final customerInfo = await Purchases.getCustomerInfo();
    _updatePremiumStatus(customerInfo);
  }
  
  void _updatePremiumStatus(CustomerInfo customerInfo) {
    final isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
    if (isPremium != _isPremium) {
      _isPremium = isPremium;
      notifyListeners();
    }
  }
  
  Future<List<Package>> getAvailablePackages() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }
  
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false; // User cancelled
      }
      rethrow;
    }
  }
  
  Future<bool> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();
    return customerInfo.entitlements.all['premium']?.isActive ?? false;
  }
}
```

4. Update `UpgradeScreen` to show real products:

```dart
Future<void> _handlePurchase(BuildContext context) async {
  setState(() => _isPurchasing = true);
  
  try {
    final offerings = await Purchases.getOfferings();
    final package = _selectedPlan == PlanType.yearly
        ? offerings.current?.annual
        : offerings.current?.monthly;
    
    if (package != null) {
      final customerInfo = await Purchases.purchasePackage(package);
      if (customerInfo.entitlements.all['premium']?.isActive == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Welcome to Premium!')),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchase failed: $e')),
    );
  } finally {
    setState(() => _isPurchasing = false);
  }
}
```

### Step 5: Stripe Integration (Web/Optional)

If you want to offer web subscriptions via Stripe:

1. Create a Stripe account at [stripe.com](https://stripe.com)
2. In RevenueCat, go to Project Settings → Integrations → Stripe
3. Connect your Stripe account
4. RevenueCat will sync subscription data between platforms

## Testing

### Sandbox Testing (iOS)

1. In App Store Connect, create a Sandbox Tester account
2. On your test device, sign out of the App Store
3. When prompted during purchase, sign in with sandbox account

### Test Tracks (Android)

1. In Google Play Console, add testers to Internal Testing track
2. Testers can use test cards provided by Google

### Debug Mode

During development, you can toggle premium status manually:

```dart
// In debug mode only
final premiumService = context.read<PremiumService>();
await premiumService.debugTogglePremium(); // Toggle for testing
```

## Environment Variables

For production, store API keys securely:

```dart
// Use environment variables or a secure config
const revenueCatApiKey = String.fromEnvironment('REVENUECAT_API_KEY');
```

## Entitlements in RevenueCat

Create an entitlement called `premium` in RevenueCat dashboard that:
- Includes both monthly and yearly subscription products
- Can be checked via `customerInfo.entitlements.all['premium']?.isActive`

## Support

For issues with:
- RevenueCat: [docs.revenuecat.com](https://docs.revenuecat.com/)
- App Store subscriptions: [Apple Developer Documentation](https://developer.apple.com/documentation/storekit)
- Google Play billing: [Google Play Billing](https://developer.android.com/google/play/billing)
