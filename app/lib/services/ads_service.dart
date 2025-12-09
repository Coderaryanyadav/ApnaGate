import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 📱 Ads Service - Google AdMob Integration
/// 
/// SETUP INSTRUCTIONS:
/// 1. Get your AdMob App ID from: https://apps.admob.com/
/// 2. Add to AndroidManifest.xml:
///    <meta-data
///        android:name="com.google.android.gms.ads.APPLICATION_ID"
///        android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
/// 
/// 3. Add to Info.plist (iOS):
/// 3. Add to Info.plist (iOS):
///    `key` GADApplicationIdentifier `/key`
///    `string` ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX `/string`
/// 
/// 4. Replace TEST IDs below with your production ad unit IDs

class AdsService {
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Get Banner Ad Unit ID based on platform
  /// 
  /// TODO: Replace with your production ad unit IDs
  /// Get them from: https://apps.admob.com/ > Apps > Ad units
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // 🔴 REPLACE THIS WITH YOUR ANDROID BANNER AD UNIT ID
      // Format: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
      const String productionId = 'ca-app-pub-3940256099942544/6300978111'; // Currently TEST ID
      return productionId;
    } else if (Platform.isIOS) {
      // 🔴 REPLACE THIS WITH YOUR iOS BANNER AD UNIT ID
      // Format: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
      const String productionId = 'ca-app-pub-3940256099942544/2934735716'; // Currently TEST ID
      return productionId;
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  /// Get Interstitial Ad Unit ID (if needed in future)
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  /// Get Rewarded Ad Unit ID (if needed in future)
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  /// Check if using test ads
  static bool get isUsingTestAds {
    return bannerAdUnitId.contains('3940256099942544');
  }
}
