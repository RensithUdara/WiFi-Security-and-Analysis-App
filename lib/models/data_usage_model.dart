class DataUsageModel {
  final double wifi; // in MB
  final double mobile; // in MB
  final DateTime date;

  DataUsageModel({
    required this.wifi,
    required this.mobile,
    required this.date,
  });

  // Method to convert our object to a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'wifi_mb': wifi,
      'mobile_mb': mobile,
      'date': date.toIso8601String(),
    };
  }
}
