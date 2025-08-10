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
      appBar: NeumorphicAppBar(
        title: Text("Network Devices"),
      ),
      body: _buildBody(),
      floatingActionButton: NeumorphicFloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        tooltip: 'Scan for Devices',
        child: _isScanning
            ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : Icon(Icons.search, size: 28),
      ),
    );
  }

  Widget _buildBody() {
    if (_devices.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.device_hub_rounded, size: 80, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.2)),
            SizedBox(height: 16),
            Text(
              'No Devices Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Press the search button to find devices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    final deviceList = _devices.toList()..sort((a,b) => a.ip.compareTo(b.ip));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: deviceList.length,
      itemBuilder: (context, index) {
        return _buildDeviceCard(deviceList[index]);
      },
    );
  }

  Widget _buildDeviceCard(DiscoveredDevice device) {
    return Neumorphic(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Neumorphic(
          style: NeumorphicStyle(
            depth: 4,
            boxShape: NeumorphicBoxShape.circle(),
            color: device.isAlive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.computer_rounded,
              color: device.isAlive ? Colors.green.shade600 : Colors.red.shade600,
            ),
          ),
        ),
        title: Text(device.hostname ?? 'Unknown Device', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(device.ip),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: _buildExpansionContent(device),
          )
        ],
      ),
    );
  }

  Widget _buildExpansionContent(DiscoveredDevice device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPortResults(device),
        SizedBox(height: 16),
        NeumorphicButton(
          onPressed: device.isScanningPorts ? null : () => _scanPorts(device),
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: Text(
                device.isScanningPorts ? 'SCANNING...' : 'SCAN PORTS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortResults(DiscoveredDevice device) {
    if (device.isScanningPorts) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 16),
            Text('Scanning common ports...'),
          ],
        ),
      );
    }

    if (!device.hasBeenPortScanned) {
      return Text('Press the button to scan for open ports.');
    }

    if (device.openPorts.isEmpty) {
      return Text('No common open ports found.');
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: device.openPorts.map((port) {
        return Neumorphic(
          style: NeumorphicStyle(
            depth: -2,
            boxShape: NeumorphicBoxShape.stadium(),
            color: Colors.blue.withOpacity(0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Text('$port', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}
