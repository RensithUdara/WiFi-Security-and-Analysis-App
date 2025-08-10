import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'scan/scan_tab.dart';
import 'devices/devices_tab.dart';
import 'speed/speed_tab.dart';
import 'usage/usage_tab.dart';
import 'profile/profile_tab.dart'; // Import the new profile tab

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    ScanTab(),
    DevicesTab(),
    SpeedTab(),
    UsageTab(),
    ProfileTab(), // Replaced placeholder with the final tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      color: NeumorphicTheme.baseColor(context),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.wifi_tethering_rounded, 0),
            _buildNavItem(Icons.devices_other_rounded, 1),
            _buildNavItem(Icons.speed_rounded, 2),
            _buildNavItem(Icons.data_usage_rounded, 3),
            _buildNavItem(Icons.person_outline_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return NeumorphicButton(
      onPressed: () => _onItemTapped(index),
      style: NeumorphicStyle(
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.circle(),
        depth: isSelected ? -5 : 5,
        lightSource: LightSource.topLeft,
        color: isSelected ? Color(0xFFCAD8E8) : NeumorphicTheme.baseColor(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Icon(
        icon,
        color: isSelected ? Colors.blue.shade600 : NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
      ),
    );
  }
}
