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
      appBar: NeumorphicAppBar(title: Text("Internet Speed Test")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(height: 24),
              _buildSpeedometer(),
              SizedBox(height: 16),
              Text(_status, style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              _buildStats(),
              SizedBox(height: 24),
              _buildActionButton(),
              SizedBox(height: 24),
              if (_status == 'Speed test finished' || _status == 'Test Stopped') ...[
                Text("Historical Download Speed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _buildHistoryChart(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedometer() {
    final isDarkMode = NeumorphicTheme.isUsingDark(context);
    return CustomPaint(
      size: Size(250, 250),
      painter: SpeedometerPainter(speed: _currentSpeed, isDarkMode: isDarkMode),
      child: SizedBox(
        width: 250,
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_currentSpeed.toStringAsFixed(2), style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
              Text('Mbps', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildStatCard('Download', '${_downloadSpeed.toStringAsFixed(2)} Mbps'),
        _buildStatCard('Upload', '${_uploadSpeed.toStringAsFixed(2)} Mbps'),
        _buildStatCard('Ping', '${_ping}ms'),
        if (_isTesting || _status == 'Speed test finished') ...[
          _buildStatCard('Server', _server.isNotEmpty ? _server : '...'),
          _buildStatCard('ISP', _isp.isNotEmpty ? _isp : '...'),
          _buildStatCard('IP Address', _ip.isNotEmpty ? _ip : '...'),
        ]
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return SizedBox(
      width: 110,
      child: Neumorphic(
        style: NeumorphicStyle(depth: 4, boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12))),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7))),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isTesting) {
      return NeumorphicButton(
        onPressed: _stopTest,
        style: NeumorphicStyle(boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(50)), depth: 5, color: Colors.redAccent),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Text('STOP TEST', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      );
    }

    if (_status == 'Speed test finished' || _status == 'Test Stopped' || _status == 'Error Occurred') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NeumorphicButton(
            onPressed: () => _resetState(clearStatus: true),
            style: NeumorphicStyle(boxShape: NeumorphicBoxShape.circle()),
            padding: const EdgeInsets.all(20),
            child: Icon(Icons.refresh, size: 30),
          ),
          if (_status == 'Speed test finished')
            NeumorphicButton(
              onPressed: _saveResult,
              style: NeumorphicStyle(color: Colors.blueAccent, boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12))),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              child: Text('Save Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      );
    }

    return NeumorphicButton(
      onPressed: _startTest,
      style: NeumorphicStyle(boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(50)), depth: 5, color: Colors.green),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Text('START TEST', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
