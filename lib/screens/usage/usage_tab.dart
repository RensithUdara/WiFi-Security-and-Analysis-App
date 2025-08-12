import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../api/data_usage_service.dart';
import '../../api/firestore_service.dart';
import '../../models/data_usage_model.dart';
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
                'Data Usage',
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
                padding: EdgeInsets.only(right: 16),
                child: NeumorphicButton(
                  style: NeumorphicStyle(
                    boxShape: NeumorphicBoxShape.circle(),
                    depth: 3,
                  ),
                  padding: EdgeInsets.all(12),
                  onPressed: _checkPermissionAndFetchData,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: _buildBody(),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
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
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: -4,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
            color: NeumorphicTheme.baseColor(context),
          ),
          child: Container(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Permission Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'To monitor data usage, WiFi Security needs "Usage Access" permission.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'After granting permission, return to the app and tap refresh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Neumorphic(
                        style: NeumorphicStyle(
                          depth: 4,
                          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(25)),
                          color: NeumorphicTheme.accentColor(context),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: UsagePermissionHelper.requestUsagePermission,
                            child: Container(
                              height: 50,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.settings_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'OPEN SETTINGS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Neumorphic(
                      style: NeumorphicStyle(
                        depth: 3,
                        boxShape: NeumorphicBoxShape.circle(),
                        color: NeumorphicTheme.baseColor(context),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: _checkPermissionAndFetchData,
                          child: Container(
                            width: 50,
                            height: 50,
                            child: Icon(
                              Icons.refresh_rounded,
                              color: NeumorphicTheme.defaultTextColor(context),
                              size: 24,
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
        ),
      ),
    );
  }

  Widget _buildUsageView(DataUsageModel? usage) {
    if (usage == null) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                "Could not load data",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeumorphicTheme.defaultTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final mobileUsageMb = usage.mobile;
    final wifiUsageMb = usage.wifi;
    final mobileLimitMb = _mobileDataLimitGb * 1024;
    final wifiLimitMb = _wifiDataLimitGb * 1024;
    final bool mobileLimitExceeded = mobileUsageMb >= mobileLimitMb;
    final bool wifiLimitExceeded = wifiUsageMb >= wifiLimitMb;

    return RefreshIndicator(
      onRefresh: _checkPermissionAndFetchData,
      color: NeumorphicTheme.accentColor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUsageOverview(usage),
          SizedBox(height: 24),
          _buildDataLimitControls(),
          SizedBox(height: 24),
          _buildUsageBreakdown(usage),
          SizedBox(height: 24),
          if (mobileLimitExceeded || wifiLimitExceeded) ...[
            _buildWarningsSection(mobileLimitExceeded, wifiLimitExceeded),
            SizedBox(height: 24),
          ],
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildUsageOverview(DataUsageModel usage) {
    return Row(
      children: [
        Expanded(
          child: _buildUsageCard(
            'WiFi Usage',
            usage.wifi,
            Icons.wifi_rounded,
            Colors.blue,
            _wifiDataLimitGb * 1024,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildUsageCard(
            'Mobile Usage',
            usage.mobile,
            Icons.signal_cellular_alt_rounded,
            Colors.green,
            _mobileDataLimitGb * 1024,
          ),
        ),
      ],
    );
  }

  Widget _buildDataLimitControls() {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -2,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: NeumorphicTheme.accentColor(context),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Data Limits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDataLimitSlider(
                    'Mobile',
                    _mobileDataLimitGb,
                    (val) => setState(() => _mobileDataLimitGb = val),
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildDataLimitSlider(
                    'WiFi',
                    _wifiDataLimitGb,
                    (val) => setState(() => _wifiDataLimitGb = val),
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataLimitSlider(String title, double value, ValueChanged<double> onChanged, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              title == 'Mobile' ? Icons.signal_cellular_alt_rounded : Icons.wifi_rounded,
              color: color,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              '$title Limit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NeumorphicTheme.defaultTextColor(context),
              ),
            ),
            Spacer(),
            Text(
              '${value.toStringAsFixed(1)} GB',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Neumorphic(
          style: NeumorphicStyle(
            depth: -2,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(25)),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
            ),
            child: Slider(
              min: 1,
              max: 100,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageCard(String title, double valueMb, IconData icon, Color color, double limitMb) {
    final usageGb = valueMb / 1024;
    final limitGb = limitMb / 1024;
    final percentage = (valueMb / limitMb * 100).clamp(0, 100);
    final isOverLimit = valueMb >= limitMb;

    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverLimit ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverLimit ? Colors.red : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${usageGb.toStringAsFixed(2)} GB',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NeumorphicTheme.defaultTextColor(context),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'of ${limitGb.toStringAsFixed(1)} GB',
              style: TextStyle(
                fontSize: 12,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.1),
              ),
              child: FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isOverLimit ? Colors.red : color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageBreakdown(DataUsageModel usage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: NeumorphicTheme.defaultTextColor(context),
          ),
        ),
        SizedBox(height: 16),
        _buildOverallPieChart(usage),
      ],
    );
  }

  Widget _buildWarningsSection(bool mobileExceeded, bool wifiExceeded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warnings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        SizedBox(height: 16),
        if (mobileExceeded)
          _buildWarningBanner('Mobile', _mobileDataLimitGb),
        if (mobileExceeded && wifiExceeded)
          SizedBox(height: 12),
        if (wifiExceeded)
          _buildWarningBanner('WiFi', _wifiDataLimitGb),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(25)),
        color: NeumorphicTheme.accentColor(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _saveUsageHistory,
          child: Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'SAVE HISTORY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
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
