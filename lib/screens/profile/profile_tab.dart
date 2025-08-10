import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:async/async.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_manager.dart';
import '../auth/login_screen.dart';
import 'history_detail_screen.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _auth = FirebaseAuth.instance;

  // A key to allow us to manually refresh the StreamBuilder
  Key _historyListKey = UniqueKey();

  void _refreshHistory() {
    setState(() {
      _historyListKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(
        title: Text('Profile & History'),
        actions: [
          // Added a refresh button to the AppBar
          StreamBuilder<User?>(
              stream: _auth.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return NeumorphicButton(
                    onPressed: _refreshHistory,
                    style: NeumorphicStyle(boxShape: NeumorphicBoxShape.circle()),
                    child: Icon(Icons.refresh, color: NeumorphicTheme.defaultTextColor(context)),
                  );
                }
                return SizedBox.shrink(); // Hide button if logged out
              }
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return _buildLoggedInView(snapshot.data!);
          }
          return _buildLoggedOutView();
        },
      ),
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.2)),
          SizedBox(height: 16),
          Text('Sign in to save and view your history.', style: TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          NeumorphicButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen()));
            },
            child: Text('SIGN IN'),
          )
        ],
      ),
    );
  }

  Widget _buildLoggedInView(User user) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Neumorphic(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Neumorphic(
                  style: NeumorphicStyle(boxShape: NeumorphicBoxShape.circle(), depth: 4),
                  child: CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName ?? 'Vigilant User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user.email ?? 'No email'),
                    ],
                  ),
                ),
                Consumer<ThemeManager>(
                  builder: (context, themeManager, child) => NeumorphicSwitch(
                    value: themeManager.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeManager.toggleTheme(value);
                    },
                  ),
                ),
                SizedBox(width: 8),
                NeumorphicButton(
                  onPressed: () => _auth.signOut(),
                  style: NeumorphicStyle(boxShape: NeumorphicBoxShape.circle()),
                  child: Icon(Icons.logout, color: Colors.red),
                )
              ],
            ),
          ),
        ),
        Divider(),
        Expanded(child: _buildHistoryList(user.uid)),
      ],
    );
  }

  Widget _buildHistoryList(String uid) {
    final speedTestStream = FirebaseFirestore.instance.collection('users').doc(uid).collection('speedTestHistory').snapshots();
    final scanHistoryStream = FirebaseFirestore.instance.collection('users').doc(uid).collection('scanHistory').snapshots();
    final usageHistoryStream = FirebaseFirestore.instance.collection('users').doc(uid).collection('usageHistory').snapshots();

    final combinedStream = StreamZip([speedTestStream, scanHistoryStream, usageHistoryStream]);

    return StreamBuilder<List<QuerySnapshot>>(
      key: _historyListKey, // Using the key to force rebuild on refresh
      stream: combinedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> historyItems = [];
        if (snapshot.hasData) {
          final speedTestDocs = snapshot.data![0].docs;
          for (var doc in speedTestDocs) {
            historyItems.add({...(doc.data() as Map<String, dynamic>), 'type': 'speedTest'});
          }

          final scanHistoryDocs = snapshot.data![1].docs;
          for (var doc in scanHistoryDocs) {
            historyItems.add({...(doc.data() as Map<String, dynamic>), 'type': 'wifiScan'});
          }

          final usageHistoryDocs = snapshot.data![2].docs;
          for (var doc in usageHistoryDocs) {
            historyItems.add({...(doc.data() as Map<String, dynamic>), 'type': 'usageHistory'});
          }
        }

        historyItems.sort((a, b) {
          DateTime getDate(Map<String, dynamic> item) {
            if (item['timestamp'] != null) return (item['timestamp'] as Timestamp).toDate();
            if (item['scannedAt'] != null) return DateTime.tryParse(item['scannedAt'] ?? '') ?? DateTime(1970);
            if (item['date'] != null) return DateTime.tryParse(item['date'] ?? '') ?? DateTime(1970);
            return DateTime(1970);
          }
          return getDate(b).compareTo(getDate(a));
        });

        if (historyItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 80, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.2)),
                SizedBox(height: 16),
                Text('No History Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Your saved scans and tests will appear here.', style: TextStyle(color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyItems.length,
          itemBuilder: (context, index) {
            final item = historyItems[index];
            if (item['type'] == 'speedTest') {
              return _buildHistoryItem(
                icon: FontAwesomeIcons.tachometerAlt,
                title: 'Speed Test',
                subtitle: '↓ ${item['downloadSpeedMbps']?.toStringAsFixed(2)} Mbps • ↑ ${item['uploadSpeedMbps']?.toStringAsFixed(2)} Mbps',
                date: (item['timestamp'] as Timestamp?)?.toDate(),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistoryDetailScreen(historyItem: item))),
              );
            } else if (item['type'] == 'wifiScan') {
              return _buildHistoryItem(
                icon: FontAwesomeIcons.wifi,
                title: 'WiFi Scan: ${item['ssid']}',
                subtitle: 'Security: ${item['security']} • Signal: ${item['signalStrength']} dBm',
                date: DateTime.tryParse(item['scannedAt'] ?? ''),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistoryDetailScreen(historyItem: item))),
              );
            } else {
              return _buildHistoryItem(
                  icon: FontAwesomeIcons.chartPie,
                  title: 'Data Usage Log',
                  subtitle: 'WiFi: ${item['wifi_mb']?.toStringAsFixed(2)} MB • Mobile: ${item['mobile_mb']?.toStringAsFixed(2)} MB',
                  date: DateTime.tryParse(item['date'] ?? ''),
                  onTap: () {} // No detail view for usage logs yet
              );
            }
          },
        );
      },
    );
  }

  Widget _buildHistoryItem({required IconData icon, required String title, required String subtitle, DateTime? date, VoidCallback? onTap}) {
    return NeumorphicButton(
      margin: const EdgeInsets.only(bottom: 12),
      onPressed: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7))),
              ],
            ),
          ),
          if (date != null)
            Text(
              DateFormat('MMM d, yy').format(date),
              style: TextStyle(fontSize: 12, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.5)),
            ),
        ],
      ),
    );
  }
}
