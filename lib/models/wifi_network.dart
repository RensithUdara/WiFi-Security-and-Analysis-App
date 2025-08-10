import 'package:wifi_scan/wifi_scan.dart';

class WiFiNetwork {
  final String ssid;
  final String bssid;
  final double frequency; // in GHz
  final int signalStrength; // dBm
  final String security;
  final int channel;
  final int? phySpeed; // PHY speed is not provided by wifi_scan, will be null
  final bool isConnected;
  final bool isRogue;

  WiFiNetwork({
    required this.ssid,
    required this.bssid,
    required this.frequency,
    required this.signalStrength,
    required this.security,
    required this.channel,
    this.phySpeed, // Nullable
    this.isConnected = false,
    this.isRogue = false,
  });

  // Factory constructor to create a WiFiNetwork from a WiFiAccessPoint
  factory WiFiNetwork.fromAccessPoint(WiFiAccessPoint ap, {bool isRogue = false, bool isConnected = false}) {
    final frequencyInGhz = ap.frequency / 1000;

    String securityType = "OPEN";
    if (ap.capabilities.contains("WPA3")) securityType = "WPA3";
    else if (ap.capabilities.contains("WPA2")) securityType = "WPA2";
    else if (ap.capabilities.contains("WPA")) securityType = "WPA";
    else if (ap.capabilities.contains("WEP")) securityType = "WEP";

    return WiFiNetwork(
      ssid: ap.ssid.isEmpty ? "[Hidden Network]" : ap.ssid,
      bssid: ap.bssid,
      frequency: frequencyInGhz,
      signalStrength: ap.level,
      security: securityType,
      channel: _getChannelFromFrequency(ap.frequency),
      isRogue: isRogue,
      isConnected: isConnected, // Now correctly assigned
    );
  }

  static int _getChannelFromFrequency(int freqInMhz) {
    if (freqInMhz >= 2412 && freqInMhz <= 2484) {
      return ((freqInMhz - 2412) ~/ 5) + 1;
    } else if (freqInMhz >= 5180 && freqInMhz <= 5825) {
      return ((freqInMhz - 5180) ~/ 5) + 36;
    }
    return 0;
  }

  // Method to convert our object to a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'frequency': frequency,
      'signalStrength': signalStrength,
      'security': security,
      'channel': channel,
      'isRogue': isRogue,
      'scannedAt': DateTime.now().toIso8601String(),
    };
  }
}
