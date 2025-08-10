import 'package:flutter/services.dart';

class DataUsageService {
  // Use a consistent channel name that matches the native code
  static const _platform = MethodChannel('com.vigilant.app/data_usage');

  // Call the native method to get data usage stats.
  Future<Map<String, double>> getUsage() async {
    try {
      // Invoke the method 'getDataUsage' on our platform channel.
      final Map<dynamic, dynamic>? result = await _platform.invokeMethod('getDataUsage');

      if (result == null) {
        return {'wifi': 0.0, 'mobile': 0.0};
      }

      // Convert the result to the correct type and handle bytes to MB conversion
      return {
        'wifi': (result['wifi'] as num).toDouble() / (1024 * 1024),
        'mobile': (result['mobile'] as num).toDouble() / (1024 * 1024),
      };
    } on PlatformException catch (e) {
      print("Failed to get data usage: '${e.message}'.");
      return {'wifi': 0.0, 'mobile': 0.0};
    }
  }
}
