import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:speed_checker_plugin/speed_checker_plugin.dart';
import 'package:vibration/vibration.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../api/firestore_service.dart';
import 'dart:async';
import 'dart:math';

class SpeedTab extends StatefulWidget {
  @override
  _SpeedTabState createState() => _SpeedTabState();
}

class _SpeedTabState extends State<SpeedTab> {
  final _plugin = SpeedCheckerPlugin();
  final _firestoreService = FirestoreService();
  StreamSubscription<SpeedTestResult>? _subscription;

  String _status = 'Press Start';
  int _ping = 0;
  String _server = '';
  String _connectionType = '';
  double _currentSpeed = 0;
  int _percent = 0;
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  String _ip = '';
  String _isp = '';
  bool _isTesting = false;

  void _startTest() {
    Vibration.vibrate(duration: 50);
    if (_isTesting) return;

    _resetState(clearStatus: false);
    setState(() {
      _isTesting = true;
      _status = 'Testing...';
    });

    _subscription?.cancel();
    _subscription = _plugin.speedTestResultStream.listen((result) {
      if (!mounted) return;
      setState(() {
        _status = result.status;
        _ping = result.ping;
        _percent = result.percent;
        _currentSpeed = result.currentSpeed;
        _downloadSpeed = result.downloadSpeed;
        _uploadSpeed = result.uploadSpeed;
        _server = result.server;
        _connectionType = result.connectionType;
        _ip = result.ip;
        _isp = result.isp;

        if (result.status == 'Speed test finished') {
          _isTesting = false;
        }
      });
      if (result.error.isNotEmpty) {
        if (mounted) {
          setState(() {
            _status = "Error Occurred";
            _isTesting = false;
          });
        }
      }
    }, onDone: () {
      if (mounted) {
        setState(() {
          _isTesting = false;
          if (_status != 'Speed test finished' && _status != 'Error Occurred') {
            _status = 'Test Stopped';
          }
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _status = "Error Occurred";
          _isTesting = false;
        });
      }
    });

    _plugin.startSpeedTest();
  }

  void _stopTest() {
    Vibration.vibrate(duration: 50);
    _plugin.stopTest();
  }

  void _saveResult() async {
    Vibration.vibrate(duration: 50);
    try {
      await _firestoreService.saveSpeedTestResult(
        downloadSpeed: _downloadSpeed,
        uploadSpeed: _uploadSpeed,
        ping: _ping,
        server: _server,
        connectionType: _connectionType,
        ip: _ip,
        isp: _isp,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speed test result saved!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving result: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetState({bool clearStatus = true}) {
    Vibration.vibrate(duration: 50);
    setState(() {
      if (clearStatus) _status = 'Press Start';
      _ping = 0;
      _server = '';
      _connectionType = '';
      _currentSpeed = 0;
      _percent = 0;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ip = '';
      _isp = '';
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _plugin.dispose();
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
                'Speed Test',
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
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSpeedGauge(),
                  SizedBox(height: 32),
                  _buildSpeedStats(),
                  SizedBox(height: 32),
                  _buildControlButtons(),
                  SizedBox(height: 24),
                  _buildConnectionInfo(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedGauge() {
    return Container(
      height: 280,
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: -8,
          boxShape: NeumorphicBoxShape.circle(),
          color: NeumorphicTheme.baseColor(context),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                NeumorphicTheme.baseColor(context),
                NeumorphicTheme.baseColor(context).withOpacity(0.9),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring progress
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: _isTesting ? _percent / 100.0 : 0,
                  strokeWidth: 8,
                  backgroundColor: NeumorphicTheme.defaultTextColor(context).withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isTesting 
                      ? NeumorphicTheme.accentColor(context)
                      : NeumorphicTheme.defaultTextColor(context).withOpacity(0.3),
                  ),
                ),
              ),
              // Inner content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentSpeed.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: NeumorphicTheme.defaultTextColor(context),
                    ),
                  ),
                  Text(
                    'Mbps',
                    style: TextStyle(
                      fontSize: 16,
                      color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_isTesting) ...[
                    SizedBox(height: 12),
                    Text(
                      '${_percent}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('Error')) return Colors.red;
    if (_status.contains('finished')) return Colors.green;
    if (_isTesting) return NeumorphicTheme.accentColor(context);
    return NeumorphicTheme.defaultTextColor(context).withOpacity(0.6);
  }

  Widget _buildSpeedStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.download_rounded,
            label: 'Download',
            value: '${_downloadSpeed.toStringAsFixed(1)} Mbps',
            color: Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.upload_rounded,
            label: 'Upload',
            value: '${_uploadSpeed.toStringAsFixed(1)} Mbps',
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_rounded,
            label: 'Ping',
            value: '${_ping} ms',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 3,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
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
            SizedBox(height: 12),
            Text(
              label,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        if (!_isTesting) ...[
          Expanded(
            flex: 2,
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: 4,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(30)),
                color: NeumorphicTheme.accentColor(context),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _startTest,
                  child: Container(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'START TEST',
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
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.refresh_rounded,
              label: 'RESET',
              onTap: () => _resetState(),
              color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
            ),
          ),
        ] else ...[
          Expanded(
            child: _buildActionButton(
              icon: Icons.stop_rounded,
              label: 'STOP TEST',
              onTap: _stopTest,
              color: Colors.red,
            ),
          ),
        ],
        if (!_isTesting && _downloadSpeed > 0) ...[
          SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.save_rounded,
              label: 'SAVE',
              onTap: _saveResult,
              color: Colors.green,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 3,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionInfo() {
    if (_server.isEmpty && _ip.isEmpty && _isp.isEmpty) {
      return SizedBox.shrink();
    }

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
                  Icons.info_outline_rounded,
                  color: NeumorphicTheme.accentColor(context),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Connection Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_server.isNotEmpty)
              _buildInfoRow('Server', _server),
            if (_ip.isNotEmpty)
              _buildInfoRow('IP Address', _ip),
            if (_isp.isNotEmpty)
              _buildInfoRow('ISP', _isp),
            if (_connectionType.isNotEmpty)
              _buildInfoRow('Connection', _connectionType),
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
                fontSize: 14,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: NeumorphicTheme.defaultTextColor(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SizedBox.shrink();
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('speedTestHistory')
        .orderBy('timestamp', descending: true)
        .limit(15)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox.shrink();
        }

        final docs = snapshot.data!.docs.reversed.toList();
        List<FlSpot> spots = [];
        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          final speed = (data['downloadSpeedMbps'] as num?)?.toDouble() ?? 0.0;
          spots.add(FlSpot(i.toDouble(), speed));
        }

        return Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Neumorphic(
            style: NeumorphicStyle(depth: -4),
            padding: const EdgeInsets.all(8),
            child: LineChart(
              LineChartData(
                  titlesData: FlTitlesData(show: false),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.2)),
                    )
                  ]
              ),
            ),
          ),
        );
      },
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double speed;
  final bool isDarkMode;

  SpeedometerPainter({required this.speed, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const angle = 3 * pi / 2;
    const startAngle = 3 * pi / 4;
    const maxSpeed = 100.0;

    final backgroundPaint = Paint()..color = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300..strokeWidth = 15..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, angle, false, backgroundPaint);

    double speedValue = (speed > maxSpeed) ? maxSpeed : speed;
    final progressPaint = Paint()..shader = LinearGradient(colors: [Colors.lightBlue.shade200, Colors.blue.shade600]).createShader(Rect.fromCircle(center: center, radius: radius))..strokeWidth = 15..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    double progressAngle = (speedValue / maxSpeed) * angle;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, progressAngle, false, progressPaint);

    final needlePaint = Paint()..color = Colors.red.shade700;
    double needleAngle = startAngle + progressAngle;
    Offset needleEnd = Offset(center.dx + (radius - 10) * cos(needleAngle), center.dy + (radius - 10) * sin(needleAngle));
    canvas.drawLine(center, needleEnd, needlePaint..strokeWidth = 3);
    canvas.drawCircle(center, 5, needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
