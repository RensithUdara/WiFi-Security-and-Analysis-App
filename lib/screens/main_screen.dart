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
      height: 85,
      decoration: BoxDecoration(
        color: NeumorphicTheme.baseColor(context),
        boxShadow: [
          BoxShadow(
            color: NeumorphicTheme.baseColor(context).withOpacity(0.8),
            offset: Offset(0, -8),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.wifi_find_rounded, 'Scan', 0),
              _buildNavItem(Icons.devices_rounded, 'Devices', 1),
              _buildNavItem(Icons.speed_rounded, 'Speed', 2),
              _buildNavItem(Icons.analytics_rounded, 'Usage', 3),
              _buildNavItem(Icons.account_circle_outlined, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Neumorphic(
                style: NeumorphicStyle(
                  shape: NeumorphicShape.flat,
                  boxShape: NeumorphicBoxShape.circle(),
                  depth: isSelected ? -4 : 2,
                  lightSource: LightSource.topLeft,
                  color: isSelected 
                    ? NeumorphicTheme.accentColor(context).withOpacity(0.1)
                    : NeumorphicTheme.baseColor(context),
                  shadowLightColor: Colors.white.withOpacity(0.9),
                  shadowDarkColor: Colors.grey.withOpacity(0.3),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected 
                      ? NeumorphicTheme.accentColor(context)
                      : NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                    ? NeumorphicTheme.accentColor(context)
                    : NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
