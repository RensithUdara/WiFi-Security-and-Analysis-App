import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';

import '../../api/wifi_service.dart';
import '../../models/wifi_network.dart';
import 'scan_detail_screen.dart';


class ScanTab extends StatefulWidget {
  @override
  _ScanTabState createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final WifiService _wifiService = WifiService();
  List<WiFiNetwork> _networks = [];
  bool _isLoading = true;
  Timer? _scanTimer;

  List<FlSpot> _signalData = List.generate(20, (i) => FlSpot(i.toDouble(), -60));
  Timer? _chartTimer;

  @override
  void initState() {
    super.initState();
    _refreshScan();
    _scanTimer = Timer.periodic(Duration(seconds: 10), (timer) => _refreshScan());
    _startLiveChart();
  }

  void _startLiveChart() {
    _chartTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _signalData.removeAt(0);
        final connectedNetwork = _networks.firstWhere((n) => n.isConnected, orElse: () => WiFiNetwork(ssid: '', bssid: '', frequency: 0, signalStrength: -60, security: '', channel: 0));
        final newStrength = (connectedNetwork.signalStrength.toDouble() + Random().nextInt(5) - 2.5);
        _signalData.add(FlSpot((_signalData.last.x + 1), newStrength));
      });
    });
  }

  Future<void> _refreshScan() async {
    Vibration.vibrate(duration: 50); // Haptic feedback
    setState(() { _isLoading = true; });
    final connectedBssid = await _wifiService.getConnectedBssid();
    final scannedNetworks = await _wifiService.getScannedNetworks(connectedBssid: connectedBssid);
    if (mounted) {
      setState(() {
        _networks = scannedNetworks;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _chartTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasWeakSecurity = _networks.any((n) => n.security == "WEP" || n.security == "OPEN");

    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(
        title: Text("WiFi Scanner"),
        actions: [
          NeumorphicButton(
            onPressed: _isLoading ? null : _refreshScan,
            style: NeumorphicStyle(boxShape: NeumorphicBoxShape.circle()),
            child: _isLoading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Icon(Icons.refresh, color: NeumorphicTheme.defaultTextColor(context)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLiveChart(),
          if(hasWeakSecurity) _buildSecurityBanner(),
          Expanded(child: _buildWifiList()),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: -5,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: Colors.amber.withOpacity(0.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Weakly secured networks detected nearby.',
                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveChart() {
    final connectedNetwork = _networks.firstWhere((n) => n.isConnected, orElse: () => WiFiNetwork(ssid: 'N/A', bssid: '', frequency: 0, signalStrength: 0, security: '', channel: 0));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Added title for the chart
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Connected Device Signal Strength (${connectedNetwork.ssid})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.8),
              ),
            ),
          ),
          Container(
            height: 150,
            child: Neumorphic(
              style: NeumorphicStyle(depth: -8, boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12))),
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16, left: 6),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: _signalData.first.x,
                    maxX: _signalData.last.x,
                    minY: -90,
                    maxY: -30,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _signalData,
                        isCurved: true,
                        color: Colors.blue.shade400,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400.withOpacity(0.3), Colors.blue.shade400.withOpacity(0.0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiList() {
    if (_isLoading && _networks.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (_networks.isEmpty) {
      return Center(
        child: Text("No WiFi networks found.\nEnsure location is enabled and press refresh.", textAlign: TextAlign.center),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshScan,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _networks.length,
        itemBuilder: (context, index) => _buildWifiListItem(_networks[index]),
      ),
    );
  }

  Widget _buildWifiListItem(WiFiNetwork network) {
    Color signalColor;
    if (network.signalStrength > -60) signalColor = Colors.green;
    else if (network.signalStrength > -75) signalColor = Colors.orange;
    else signalColor = Colors.red;

    IconData securityIcon;
    switch(network.security){
      case "WPA3": securityIcon = Icons.lock_rounded; break;
      case "WPA2": securityIcon = Icons.lock_outline_rounded; break;
      case "WEP": securityIcon = Icons.lock_open_rounded; break;
      default: securityIcon = Icons.lock_open_rounded;
    }

    return NeumorphicButton(
      margin: EdgeInsets.only(bottom: 16),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ScanDetailScreen(network: network)
        ));
      },
      padding: const EdgeInsets.all(12),
      style: NeumorphicStyle(
        depth: network.isConnected ? 8 : 4,
        border: network.isConnected
            ? NeumorphicBorder(color: Colors.blue.shade300, width: 1.5)
            : NeumorphicBorder.none(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: signalColor, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Text(network.ssid, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (network.isRogue)
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 22),
              SizedBox(width: 12),
              Icon(securityIcon, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7), size: 22),
              SizedBox(width: 12),
              Text("${network.signalStrength}", style: TextStyle(fontWeight: FontWeight.bold, color: signalColor)),
            ],
          ),
          if (network.isConnected) ...[
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Neumorphic(
                  style: NeumorphicStyle(
                    depth: -2,
                    color: Colors.blue.withOpacity(0.1),
                    boxShape: NeumorphicBoxShape.stadium(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'CONNECTED',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
