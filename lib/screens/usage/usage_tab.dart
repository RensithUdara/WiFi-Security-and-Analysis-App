import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../api/data_usage_service.dart';
import '../../api/firestore_service.dart';
import '../../models/data_usage_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/usage_permission_helper.dart';

class UsageTab extends StatefulWidget {
  @override
  _UsageTabState createState() => _UsageTabState();
}

class _UsageTabState extends State<UsageTab> with WidgetsBindingObserver {
  final DataUsageService _usageService = DataUsageService();
  final FirestoreService _firestoreService = FirestoreService();

  DataUsageModel? _currentUsage;
  bool _isLoading = true;
  bool _permissionGranted = false;
  double _mobileDataLimitGb = 5.0; // Default mobile data limit of 5 GB
  double _wifiDataLimitGb = 50.0;   // Default WiFi data limit of 50 GB

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndFetchData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndFetchData();
    }
  }

  Future<void> _checkPermissionAndFetchData() async {
    setState(() => _isLoading = true);
    final hasPermission = await UsagePermissionHelper.hasUsagePermission();

    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _permissionGranted = false;
      });
      return;
    }

    final usageData = await _usageService.getUsage();
    if (mounted) {
      setState(() {
        _permissionGranted = true;
        _currentUsage = DataUsageModel(
            wifi: usageData['wifi']!,
            mobile: usageData['mobile']!,
            date: DateTime.now()
        );
        _isLoading = false;
      });
    }
  }

  void _saveUsageHistory() async {
    if (_currentUsage == null) return;
    try {
      await _firestoreService.saveUsageHistory(_currentUsage!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usage history saved!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving history: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(
        title: Text("Data Usage"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (!_permissionGranted) {
      return _buildPermissionRequestView();
    }

    return _buildUsageView(_currentUsage);
  }

  Widget _buildPermissionRequestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey),
            SizedBox(height: 20),
            Text('Permission Required', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            SizedBox(height: 12),
            Text('To show data usage, Vigilant needs "Usage Access" permission.\n\nAfter granting it, please return to the app and press the refresh button.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeumorphicButton(
                  onPressed: UsagePermissionHelper.requestUsagePermission,
                  child: Text('Open Settings'),
                ),
                SizedBox(width: 16),
                NeumorphicButton(
                  onPressed: _checkPermissionAndFetchData,
                  style: NeumorphicStyle(boxShape: NeumorphicBoxShape.circle()),
                  padding: const EdgeInsets.all(16),
                  child: Icon(Icons.refresh, color: NeumorphicTheme.defaultTextColor(context)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUsageView(DataUsageModel? usage) {
    if (usage == null) {
      return Center(child: Text("Could not load data."));
    }

    final mobileUsageMb = usage.mobile;
    final wifiUsageMb = usage.wifi;
    final mobileLimitMb = _mobileDataLimitGb * 1024;
    final wifiLimitMb = _wifiDataLimitGb * 1024;
    final bool mobileLimitExceeded = mobileUsageMb >= mobileLimitMb;
    final bool wifiLimitExceeded = wifiUsageMb >= wifiLimitMb;

    return RefreshIndicator(
      onRefresh: _checkPermissionAndFetchData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              Expanded(child: _buildDataLimitSlider('Mobile', _mobileDataLimitGb, (val) => setState(() => _mobileDataLimitGb = val))),
              SizedBox(width: 16),
              Expanded(child: _buildDataLimitSlider('WiFi', _wifiDataLimitGb, (val) => setState(() => _wifiDataLimitGb = val))),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildUsageCard('WiFi Usage', wifiUsageMb, FontAwesomeIcons.wifi)),
              SizedBox(width: 16),
              Expanded(child: _buildUsageCard('Mobile Usage', mobileUsageMb, FontAwesomeIcons.mobileScreenButton)),
            ],
          ),
          SizedBox(height: 24),
          // Added back the original pie chart
          Text("Overall Usage Breakdown", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          _buildOverallPieChart(usage),
          SizedBox(height: 24),
          Text("Usage vs. Limit Breakdown", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          _buildLimitPieChartArea(usage),
          SizedBox(height: 24),
          if (mobileLimitExceeded) _buildWarningBanner('Mobile', _mobileDataLimitGb),
          if (wifiLimitExceeded) SizedBox(height: 12),
          if (wifiLimitExceeded) _buildWarningBanner('WiFi', _wifiDataLimitGb),
          SizedBox(height: 24),
          NeumorphicButton(
            onPressed: _saveUsageHistory,
            child: SizedBox(width: double.infinity, child: Center(child: Text('SAVE HISTORY', style: TextStyle(fontWeight: FontWeight.bold)))),
          )
        ],
      ),
    );
  }

  Widget _buildDataLimitSlider(String title, double value, ValueChanged<double> onChanged) {
    return Neumorphic(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('$title Limit: ${value.toStringAsFixed(1)} GB'),
          NeumorphicSlider(
            min: 1,
            max: 100,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard(String title, double value, IconData icon) {
    return Neumorphic(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7)),
          SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 16)),
          SizedBox(height: 4),
          Text('${value.toStringAsFixed(2)} MB', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOverallPieChart(DataUsageModel usage) {
    final totalUsage = usage.wifi + usage.mobile;
    return Neumorphic(
      padding: const EdgeInsets.all(16),
      style: NeumorphicStyle(depth: -4),
      child: SizedBox(
        height: 200,
        child: totalUsage > 0
            ? PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: usage.wifi,
                title: '${(usage.wifi / totalUsage * 100).toStringAsFixed(0)}%',
                color: Colors.blue.shade400,
                radius: 80,
              ),
              PieChartSectionData(
                value: usage.mobile,
                title: '${(usage.mobile / totalUsage * 100).toStringAsFixed(0)}%',
                color: Colors.green.shade400,
                radius: 80,
              ),
            ],
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        )
            : Center(child: Text("No usage data to display.")),
      ),
    );
  }

  Widget _buildLimitPieChartArea(DataUsageModel usage) {
    return Row(
      children: [
        Expanded(
            child: _buildSingleUsagePieChart(
              title: "Mobile Limit",
              usage: usage.mobile,
              limit: _mobileDataLimitGb * 1024, // convert GB to MB
              color: Colors.green.shade400,
            )
        ),
        SizedBox(width: 16),
        Expanded(
            child: _buildSingleUsagePieChart(
              title: "WiFi Limit",
              usage: usage.wifi,
              limit: _wifiDataLimitGb * 1024, // convert GB to MB
              color: Colors.blue.shade400,
            )
        ),
      ],
    );
  }

  Widget _buildSingleUsagePieChart({required String title, required double usage, required double limit, required Color color}) {
    final double usedPercentage = (usage / limit * 100).clamp(0, 100);
    final double usedValue = usage > limit ? limit : usage;
    final double remainingValue = limit > usage ? limit - usage : 0;

    return Neumorphic(
      padding: const EdgeInsets.all(16),
      style: NeumorphicStyle(depth: -4),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                      value: usedValue,
                      title: '${usedPercentage.toStringAsFixed(0)}%',
                      color: color,
                      radius: 50,
                      titleStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  PieChartSectionData(
                    value: remainingValue,
                    title: '',
                    color: Colors.grey.shade300,
                    radius: 50,
                  ),
                ],
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String type, double limit) {
    return Neumorphic(
      style: NeumorphicStyle(color: Colors.red.withOpacity(0.2)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'You have exceeded your $type data limit of ${limit.toStringAsFixed(1)} GB.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
            ),
          )
        ],
      ),
    );
  }
}
