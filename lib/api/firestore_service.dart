import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wifi_network.dart';
import '../models/data_usage_model.dart'; // Import the data usage model

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user or sign in anonymously
  Future<User> _getUser() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    return _auth.currentUser!;
  }

  // Save a scanned network to a user's history
  Future<void> saveScan(WiFiNetwork network) async {
    try {
      final user = await _getUser();
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('scanHistory')
          .add(network.toJson());
    } catch (e) {
      print("Error saving scan to Firestore: $e");
      throw Exception("Could not save scan.");
    }
  }

  // Report a potential rogue AP
  Future<void> reportRogueAP(WiFiNetwork network) async {
    try {
      await _db
          .collection('rogueAPReports')
          .add(network.toJson());
    } catch (e) {
      print("Error reporting rogue AP: $e");
      throw Exception("Could not report AP.");
    }
  }

  // Updated method to save speed test results from the new plugin
  Future<void> saveSpeedTestResult({
    required double downloadSpeed,
    required double uploadSpeed,
    required int ping,
    required String server,
    required String connectionType,
    required String ip,
    required String isp,
  }) async {
    try {
      final user = await _getUser();
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('speedTestHistory')
          .add({
        'downloadSpeedMbps': downloadSpeed,
        'uploadSpeedMbps': uploadSpeed,
        'pingMs': ping,
        'server': server,
        'connectionType': connectionType,
        'ipAddress': ip,
        'isp': isp,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving speed test result: $e");
      throw Exception("Could not save result.");
    }
  }

  // New method to save data usage history
  Future<void> saveUsageHistory(DataUsageModel usage) async {
    try {
      final user = await _getUser();
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('usageHistory')
          .add(usage.toJson());
    } catch (e) {
      print("Error saving usage history: $e");
      throw Exception("Could not save usage history.");
    }
  }
}
