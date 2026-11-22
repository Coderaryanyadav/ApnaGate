import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        debugPrint('✅ Google Mobile Ads initialized successfully');
      }
    } catch (e) {
      debugPrint('⚠️ Google Mobile Ads initialization skipped or failed: $e');
    }
  }
}
