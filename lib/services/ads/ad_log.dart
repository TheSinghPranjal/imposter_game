import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Error text for logcat / Xcode. Includes the SDK code and message.
String describeAdsError(Object error) {
  if (error is FormError) {
    return 'code=${error.errorCode} message=${error.message}';
  }
  if (error is AdError) {
    return 'code=${error.code} domain=${error.domain} message=${error.message}';
  }
  if (error is PlatformException) {
    return 'code=${error.code} message=${error.message ?? ''}';
  }
  return error.toString();
}
