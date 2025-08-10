import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const HistoryDetailScreen({Key? key, required this.historyItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSpeedTest = historyItem['type'] == 'speedTest';

    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(
        title: Text(isSpeedTest ? 'Speed Test Details' : 'WiFi Scan Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: isSpeedTest ? _buildSpeedTestDetails(context) : _buildWifiScanDetails(context),
      ),
    );
  }

  List<Widget> _buildSpeedTestDetails(BuildContext context) {
    final timestamp = (historyItem['timestamp'] as Timestamp?)?.toDate();
    return [
      _buildDetailRow(context, FontAwesomeIcons.download, 'Download', '${historyItem['downloadSpeedMbps']?.toStringAsFixed(2)} Mbps'),
      _buildDetailRow(context, FontAwesomeIcons.upload, 'Upload', '${historyItem['uploadSpeedMbps']?.toStringAsFixed(2)} Mbps'),
      _buildDetailRow(context, FontAwesomeIcons.stopwatch, 'Ping', '${historyItem['pingMs']} ms'),
      _buildDetailRow(context, FontAwesomeIcons.server, 'Server', historyItem['server'] ?? 'N/A'),
      _buildDetailRow(context, FontAwesomeIcons.networkWired, 'ISP', historyItem['isp'] ?? 'N/A'),
      _buildDetailRow(context, FontAwesomeIcons.ethernet, 'Connection', historyItem['connectionType'] ?? 'N/A'),
      _buildDetailRow(context, FontAwesomeIcons.solidAddressCard, 'IP Address', historyItem['ipAddress'] ?? 'N/A'),
      if (timestamp != null) _buildDetailRow(context, FontAwesomeIcons.solidClock, 'Date', DateFormat.yMMMd().add_jm().format(timestamp)),
    ];
  }

  List<Widget> _buildWifiScanDetails(BuildContext context) {
    final timestamp = DateTime.tryParse(historyItem['scannedAt'] ?? '');
    return [
      _buildDetailRow(context, FontAwesomeIcons.wifi, 'SSID', historyItem['ssid'] ?? 'N/A'),
      _buildDetailRow(context, FontAwesomeIcons.barcode, 'BSSID', historyItem['bssid'] ?? 'N/A'),
      _buildDetailRow(context, FontAwesomeIcons.towerBroadcast, 'Frequency', '${historyItem['frequency']} GHz'),
      _buildDetailRow(context, FontAwesomeIcons.signal, 'Signal', '${historyItem['signalStrength']} dBm'),
      _buildDetailRow(context, FontAwesomeIcons.shieldHalved, 'Security', historyItem['security'] ?? 'N/A'),
      _buildDetailRow(context, FontAwesomeIcons.hashtag, 'Channel', '${historyItem['channel']}'),
      if (timestamp != null) _buildDetailRow(context, FontAwesomeIcons.solidClock, 'Date', DateFormat.yMMMd().add_jm().format(timestamp)),
    ];
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Neumorphic(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6)),
          SizedBox(width: 20),
          Text(label, style: TextStyle(fontSize: 16, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.8))),
          Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
