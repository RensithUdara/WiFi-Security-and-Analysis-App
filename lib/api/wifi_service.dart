import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart'; // Import the new package
import '../models/wifi_network.dart';

class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo(); // Create an instance of NetworkInfo

  Future<bool> _requestPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Updated method to get the BSSID of the currently connected WiFi network
  Future<String?> getConnectedBssid() async {
    try {
      // Use the instance to call the method from the new package
      return await _networkInfo.getWifiBSSID();
    } catch (e) {
      print("Could not get BSSID: $e");
      return null;
    }
  }


  Future<List<WiFiNetwork>> getScannedNetworks({String? connectedBssid}) async {
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) {
      print("Cannot start scan: $canScan");
      if(canScan == CanStartScan.noLocationPermissionRequired) {
        await _requestPermissions();
      }
      return [];
    }

    try {
      await WiFiScan.instance.startScan();
      final List<WiFiAccessPoint> accessPoints = await WiFiScan.instance.getScannedResults();
      return _processAccessPoints(accessPoints, connectedBssid: connectedBssid);
    } on PlatformException catch (e) {
      print("Failed to scan networks: '${e.message}'");
      return [];
    }
  }

  List<WiFiNetwork> _processAccessPoints(List<WiFiAccessPoint> accessPoints, {String? connectedBssid}) {
    final ssidGroups = <String, List<WiFiAccessPoint>>{};
    for (var ap in accessPoints) {
      if (ap.ssid.isNotEmpty) {
        (ssidGroups[ap.ssid] ??= []).add(ap);
      }
    }

    final List<WiFiNetwork> networks = [];
    for (var ap in accessPoints) {
      bool isRogue = false;
      if (ssidGroups.containsKey(ap.ssid) && ssidGroups[ap.ssid]!.length > 1) {
        isRogue = true;
      }

      // FIX: Make comparison case-insensitive to handle format differences
      final bool isConnected = connectedBssid != null &&
          ap.bssid.toLowerCase() == connectedBssid.toLowerCase();

      networks.add(WiFiNetwork.fromAccessPoint(ap, isRogue: isRogue, isConnected: isConnected));
    }

    networks.sort((a, b) {
      if (a.isConnected) return -1;
      if (b.isConnected) return 1;
      return b.signalStrength.compareTo(a.signalStrength);
    });
    return networks;
  }
}
