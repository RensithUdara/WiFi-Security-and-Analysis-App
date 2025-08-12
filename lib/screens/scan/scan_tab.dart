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
    final connectedNetwork = _networks.firstWhere((n) => n.isConnected, orElse: () => WiFiNetwork(ssid: 'No Connection', bssid: '', frequency: 0, signalStrength: 0, security: '', channel: 0));

    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: NeumorphicTheme.baseColor(context),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'WiFi Scanner',
                style: TextStyle(
                  color: NeumorphicTheme.defaultTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NeumorphicTheme.baseColor(context),
                      NeumorphicTheme.baseColor(context).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 20, top: 8),
                child: Neumorphic(
                  style: NeumorphicStyle(
                    shape: NeumorphicShape.flat,
                    boxShape: NeumorphicBoxShape.circle(),
                    depth: _isLoading ? -2 : 4,
                    color: _isLoading 
                      ? NeumorphicTheme.accentColor(context).withOpacity(0.1)
                      : NeumorphicTheme.baseColor(context),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _refreshScan,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                NeumorphicTheme.accentColor(context),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            color: NeumorphicTheme.defaultTextColor(context),
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatusCards(connectedNetwork),
                _buildLiveChart(),
                if (hasWeakSecurity) _buildSecurityBanner(),
                SizedBox(height: 8),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: _buildWifiList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(WiFiNetwork connectedNetwork) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              icon: Icons.wifi_rounded,
              title: 'Connected',
              value: connectedNetwork.ssid != 'No Connection' ? connectedNetwork.ssid : 'Not Connected',
              color: connectedNetwork.ssid != 'No Connection' ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              icon: Icons.signal_wifi_4_bar_rounded,
              title: 'Signal',
              value: connectedNetwork.signalStrength != 0 ? '${connectedNetwork.signalStrength} dBm' : 'N/A',
              color: _getSignalColor(connectedNetwork.signalStrength),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              icon: Icons.router_rounded,
              title: 'Networks',
              value: '${_networks.length}',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        lightSource: LightSource.topLeft,
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: NeumorphicTheme.defaultTextColor(context),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(int signalStrength) {
    if (signalStrength >= -50) return Colors.green;
    if (signalStrength >= -70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSecurityBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: -3,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          color: Colors.red.withOpacity(0.05),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.orange.withOpacity(0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Alert',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Weak or open networks detected nearby. Avoid connecting to unsecured networks.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.red.shade600,
                  size: 16,
                ),
              ],
            ),
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
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NeumorphicTheme.accentColor(context)),
                ),
                SizedBox(height: 16),
                Text(
                  'Scanning for networks...',
                  style: TextStyle(
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_networks.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.3),
                ),
                SizedBox(height: 16),
                Text(
                  "No WiFi networks found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ensure location is enabled and pull down to refresh",
                  style: TextStyle(
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildWifiListItem(_networks[index]),
        childCount: _networks.length,
      ),
    );
  }

  Widget _buildWifiListItem(WiFiNetwork network) {
    Color signalColor = _getSignalColor(network.signalStrength);
    
    IconData securityIcon;
    Color securityColor;
    String securityText;
    
    switch(network.security) {
      case "WPA3":
        securityIcon = Icons.verified_user_rounded;
        securityColor = Colors.green;
        securityText = "WPA3";
        break;
      case "WPA2":
        securityIcon = Icons.lock_rounded;
        securityColor = Colors.blue;
        securityText = "WPA2";
        break;
      case "WEP":
        securityIcon = Icons.no_encryption_rounded;
        securityColor = Colors.orange;
        securityText = "WEP";
        break;
      default:
        securityIcon = Icons.lock_open_rounded;
        securityColor = Colors.red;
        securityText = "Open";
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: network.isConnected ? 6 : 3,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          color: network.isConnected 
            ? NeumorphicTheme.accentColor(context).withOpacity(0.05)
            : NeumorphicTheme.baseColor(context),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ScanDetailScreen(network: network)
            ));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: network.isConnected ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: NeumorphicTheme.accentColor(context).withOpacity(0.3),
                width: 2,
              ),
            ) : null,
            child: Column(
              children: [
                Row(
                  children: [
                    // WiFi Signal Icon with strength indicator
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: signalColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getWifiIcon(network.signalStrength),
                        color: signalColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Network Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  network.ssid,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: NeumorphicTheme.defaultTextColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (network.isConnected)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'CONNECTED',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              // Security Badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: securityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      securityIcon,
                                      size: 12,
                                      color: securityColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      securityText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: securityColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              
                              // Channel Info
                              Text(
                                'Ch ${network.channel}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                                ),
                              ),
                              
                              Spacer(),
                              
                              // Signal Strength
                              Text(
                                '${network.signalStrength} dBm',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: signalColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
                    // Action/Status Indicators
                    Column(
                      children: [
                        if (network.isRogue)
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.4),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWifiIcon(int signalStrength) {
    if (signalStrength >= -50) return Icons.wifi_rounded;
    if (signalStrength >= -70) return Icons.wifi_2_bar_rounded;
    return Icons.wifi_1_bar_rounded;
  }
}
