import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vibration/vibration.dart';
import '../../api/device_discovery_service.dart';
import '../../models/discovered_device.dart';
import 'dart:async';

class DevicesTab extends StatefulWidget {
  @override
  _DevicesTabState createState() => _DevicesTabState();
}

class _DevicesTabState extends State<DevicesTab> {
  final DeviceDiscoveryService _service = DeviceDiscoveryService();
  final Set<DiscoveredDevice> _devices = {};
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  void _startScan() {
    Vibration.vibrate(duration: 50); // Haptic feedback
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    _scanSubscription = _service.discoverDevices().listen((device) {
      setState(() {
        _devices.add(device);
      });
    }, onDone: () {
      setState(() {
        _isScanning = false;
      });
    }, onError: (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    });
  }

  Future<void> _scanPorts(DiscoveredDevice device) async {
    Vibration.vibrate(duration: 50); // Haptic feedback
    final deviceInSet = _devices.firstWhere((d) => d.ip == device.ip);

    setState(() {
      deviceInSet.isScanningPorts = true;
      deviceInSet.openPorts = [];
    });

    final openPorts = await _service.scanPorts(device.ip);

    setState(() {
      deviceInSet.openPorts = openPorts;
      deviceInSet.isScanningPorts = false;
      deviceInSet.hasBeenPortScanned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                'Network Devices',
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: _buildScanSection(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: _buildDevicesList(),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildScanSection() {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -4,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NeumorphicTheme.accentColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.device_hub_rounded,
                    color: NeumorphicTheme.accentColor(context),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Discovery',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: NeumorphicTheme.defaultTextColor(context),
                        ),
                      ),
                      Text(
                        _isScanning ? 'Scanning network...' : '${_devices.length} devices found',
                        style: TextStyle(
                          fontSize: 14,
                          color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: _isScanning ? -2 : 4,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(30)),
                      color: _isScanning ? NeumorphicTheme.baseColor(context) : NeumorphicTheme.accentColor(context),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: _isScanning ? null : _startScan,
                        child: Container(
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isScanning) ...[
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      NeumorphicTheme.accentColor(context),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'SCANNING...',
                                  style: TextStyle(
                                    color: NeumorphicTheme.accentColor(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'SCAN NETWORK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    if (_devices.isEmpty && !_isScanning) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.devices_other_rounded,
                    size: 48,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.3),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'No Devices Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the scan button to discover devices on your network',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final deviceList = _devices.toList()..sort((a, b) => a.ip.compareTo(b.ip));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildDeviceCard(deviceList[index]),
        childCount: deviceList.length,
      ),
    );
  }

  Widget _buildDeviceCard(DiscoveredDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 4,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          color: NeumorphicTheme.baseColor(context),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.all(20),
            childrenPadding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: device.isAlive 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: device.isAlive 
                    ? Colors.green.withOpacity(0.3) 
                    : Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getDeviceIcon(device),
                color: device.isAlive ? Colors.green : Colors.red,
                size: 28,
              ),
            ),
            title: Text(
              device.hostname ?? 'Unknown Device',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: NeumorphicTheme.defaultTextColor(context),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  device.ip,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusBadge(
                      device.isAlive ? 'Online' : 'Offline',
                      device.isAlive ? Colors.green : Colors.red,
                    ),
                    if (device.hasBeenPortScanned) ...[
                      SizedBox(width: 8),
                      _buildStatusBadge(
                        '${device.openPorts.length} ports',
                        Colors.blue,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            children: [
              _buildExpansionContent(device),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(DiscoveredDevice device) {
    if (device.hostname?.toLowerCase().contains('router') ?? false) {
      return Icons.router_rounded;
    }
    if (device.hostname?.toLowerCase().contains('phone') ?? false) {
      return Icons.smartphone_rounded;
    }
    if (device.hostname?.toLowerCase().contains('laptop') ?? false) {
      return Icons.laptop_rounded;
    }
    return Icons.computer_rounded;
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExpansionContent(DiscoveredDevice device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.1)),
        SizedBox(height: 16),
        _buildDeviceInfo(device),
        SizedBox(height: 20),
        _buildPortResults(device),
        SizedBox(height: 20),
        _buildPortScanButton(device),
      ],
    );
  }

  Widget _buildDeviceInfo(DiscoveredDevice device) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -2,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: NeumorphicTheme.accentColor(context),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Device Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow('IP Address', device.ip),
            _buildInfoRow('Hostname', device.hostname ?? 'Unknown'),
            _buildInfoRow('Status', device.isAlive ? 'Online' : 'Offline'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: NeumorphicTheme.defaultTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortScanButton(DiscoveredDevice device) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: device.isScanningPorts ? -2 : 3,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
        color: device.isScanningPorts 
          ? NeumorphicTheme.baseColor(context) 
          : NeumorphicTheme.accentColor(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: device.isScanningPorts ? null : () => _scanPorts(device),
          child: Container(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (device.isScanningPorts) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        NeumorphicTheme.accentColor(context),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'SCANNING PORTS...',
                    style: TextStyle(
                      color: NeumorphicTheme.accentColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SCAN PORTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortResults(DiscoveredDevice device) {
    if (device.isScanningPorts) {
      return Neumorphic(
        style: NeumorphicStyle(
          depth: -2,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: NeumorphicTheme.baseColor(context),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    NeumorphicTheme.accentColor(context),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Scanning common ports...',
                style: TextStyle(
                  fontSize: 14,
                  color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!device.hasBeenPortScanned) {
      return Neumorphic(
        style: NeumorphicStyle(
          depth: -2,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: NeumorphicTheme.baseColor(context),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.5),
                size: 18,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Press the button below to scan for open ports',
                  style: TextStyle(
                    fontSize: 14,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Neumorphic(
      style: NeumorphicStyle(
        depth: -2,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: device.openPorts.isEmpty ? Colors.green : Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Port Scan Results',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: device.openPorts.isEmpty 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${device.openPorts.length} open',
                    style: TextStyle(
                      fontSize: 12,
                      color: device.openPorts.isEmpty ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (device.openPorts.isEmpty) ...[
              Text(
                'No common open ports found. This device appears secure.',
                style: TextStyle(
                  fontSize: 13,
                  color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: device.openPorts.map((port) {
                  return Neumorphic(
                    style: NeumorphicStyle(
                      depth: 2,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                      color: _getPortColor(port).withOpacity(0.1),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPortIcon(port),
                            size: 14,
                            color: _getPortColor(port),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '$port',
                            style: TextStyle(
                              color: _getPortColor(port),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getPortDescription(port),
                            style: TextStyle(
                              color: _getPortColor(port).withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPortColor(int port) {
    // Security-critical ports
    if ([22, 23, 3389, 5900].contains(port)) return Colors.red;
    // Web ports
    if ([80, 443, 8080, 8443].contains(port)) return Colors.blue;
    // Database ports
    if ([3306, 5432, 1433, 27017].contains(port)) return Colors.purple;
    // Email ports
    if ([25, 587, 993, 995].contains(port)) return Colors.green;
    // File sharing
    if ([21, 22, 445, 139].contains(port)) return Colors.orange;
    return Colors.grey;
  }

  IconData _getPortIcon(int port) {
    if ([80, 443, 8080, 8443].contains(port)) return Icons.web_rounded;
    if ([22, 23].contains(port)) return Icons.terminal_rounded;
    if ([21, 445, 139].contains(port)) return Icons.folder_shared_rounded;
    if ([25, 587, 993, 995].contains(port)) return Icons.mail_rounded;
    if ([3306, 5432, 1433, 27017].contains(port)) return Icons.storage_rounded;
    return Icons.lan_rounded;
  }

  String _getPortDescription(int port) {
    switch (port) {
      case 21: return 'FTP';
      case 22: return 'SSH';
      case 23: return 'Telnet';
      case 25: return 'SMTP';
      case 80: return 'HTTP';
      case 139: return 'NetBIOS';
      case 443: return 'HTTPS';
      case 445: return 'SMB';
      case 587: return 'SMTP';
      case 993: return 'IMAPS';
      case 995: return 'POP3S';
      case 1433: return 'MSSQL';
      case 3306: return 'MySQL';
      case 3389: return 'RDP';
      case 5432: return 'PostgreSQL';
      case 5900: return 'VNC';
      case 8080: return 'HTTP Alt';
      case 8443: return 'HTTPS Alt';
      case 27017: return 'MongoDB';
      default: return '';
    }
  }
}
