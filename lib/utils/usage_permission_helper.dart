import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';

class UsagePermissionHelper {
  // Use a consistent channel name for all communications
  static const _platform = MethodChannel('com.vigilant.app/data_usage');

  // Check if the usage access permission is granted by calling native Android code
  static Future<bool> hasUsagePermission() async {
    try {
      return await _platform.invokeMethod('hasUsagePermission');
    } catch (e) {
      print('Error checking usage permission: $e');
      return false;
    }
  }

  // Navigate to the specific system settings screen to allow usage access
  static Future<void> requestUsagePermission() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      print('Error launching settings: $e');
    }
  }
}
