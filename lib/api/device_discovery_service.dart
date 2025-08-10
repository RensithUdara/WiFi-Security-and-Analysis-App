import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_tools/network_tools.dart';
import '../models/discovered_device.dart';

class DeviceDiscoveryService {
  final NetworkInfo _networkInfo = NetworkInfo();

  // Discover devices on the local network
  Stream<DiscoveredDevice> discoverDevices() async* {
    final String? ip = await _networkInfo.getWifiIP();
    if (ip == null) {
      throw Exception("Could not get device IP. Ensure you are connected to Wi-Fi.");
    }

    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    // This uses the HostScannerService singleton to find devices
    final stream = HostScannerService.instance.getAllPingableDevices(subnet, firstHostId: 1, lastHostId: 254);

    await for (final host in stream) {
      // Await the hostName Future here before creating the object
      final String? hostName = await host.hostName;
      // Directly creating the DiscoveredDevice object now, instead of using the factory
      yield DiscoveredDevice(
          ip: host.address,
          hostname: hostName,
          isAlive: true
      );
    }
  }

  // Scan a specific device for a curated list of common open ports
  Future<List<int>> scanPorts(String ip) async {
    final List<int> openPorts = [];

    // A curated list for speed and stability
    final List<int> portsToScan = [
      21,   // FTP
      22,   // SSH
      23,   // Telnet
      25,   // SMTP
      53,   // DNS
      80,   // HTTP
      110,  // POP3
      139,  // NetBIOS
      143,  // IMAP
      443,  // HTTPS
      445,  // SMB
      993,  // IMAPS
      995,  // POP3S
      1723, // PPTP
      3306, // MySQL
      3389, // RDP
      5432, // PostgreSQL
      5900, // VNC
      8080, // HTTP Alt
    ];

    // CORRECTED APPROACH: Using the PortScannerService instance to scan for open ports.
    // This is more reliable than the static method which was causing build issues.
    final stream = PortScannerService.instance.scanPortsForSingleDevice(ip);

    await for (final host in stream) {
      // The ActiveHost object contains a list of OpenPort objects
      for (final openPort in host.openPorts) {
        // We only add the ports that we are interested in checking.
        if (portsToScan.contains(openPort.port)) {
          openPorts.add(openPort.port);
        }
      }
    }

    openPorts.sort();
    return openPorts;
  }
}
