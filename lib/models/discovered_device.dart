class DiscoveredDevice {
  final String ip;
  String? hostname;
  final bool isAlive;
  List<int> openPorts;
  bool isScanningPorts;
  bool hasBeenPortScanned;

  DiscoveredDevice({
    required this.ip,
    this.hostname,
    this.isAlive = true,
    this.openPorts = const [],
    this.isScanningPorts = false,
    this.hasBeenPortScanned = false,
  });
}