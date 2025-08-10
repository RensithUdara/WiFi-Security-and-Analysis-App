import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/wifi_network.dart';
import '../../api/firestore_service.dart';

class ScanDetailScreen extends StatefulWidget {
  final WiFiNetwork network;
  const ScanDetailScreen({Key? key, required this.network}) : super(key: key);

  @override
  _ScanDetailScreenState createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;
  bool _isReporting = false;

  void _saveScan() async {
    setState(() { _isSaving = true; });
    try {
      await _firestoreService.saveScan(widget.network);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan saved to your profile!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not save scan.'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() { _isSaving = false; });
    }
  }

  void _reportRogueAP() async {
    setState(() { _isReporting = true; });
    try {
      await _firestoreService.reportRogueAP(widget.network);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rogue AP Reported. Thank you!'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not report AP.'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() { _isReporting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(title: Text(widget.network.ssid)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (widget.network.isRogue) _buildRogueApBanner(context),
            _buildDetailCard(context),
            SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRogueApBanner(BuildContext context) {
    return Neumorphic(
      margin: EdgeInsets.only(bottom: 20),
      style: NeumorphicStyle(
        depth: -5,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        color: Colors.red.withOpacity(0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(FontAwesomeIcons.triangleExclamation, color: Colors.red, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Potential Rogue AP', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Another network with the same name was detected.', style: TextStyle(color: Colors.red.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Neumorphic(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDetailRow(context, FontAwesomeIcons.barcode, 'BSSID', widget.network.bssid),
          _buildDetailRow(context, FontAwesomeIcons.towerBroadcast, 'Frequency', '${widget.network.frequency} GHz'),
          _buildDetailRow(context, FontAwesomeIcons.hashtag, 'Channel', '${widget.network.channel}'),
          _buildDetailRow(context, FontAwesomeIcons.shieldHalved, 'Encryption', widget.network.security),
          _buildDetailRow(context, FontAwesomeIcons.gaugeHigh, 'PHY Speed', 'N/A'), // Not available from package
          _buildDetailRow(context, FontAwesomeIcons.circleQuestion, 'Threat Level', widget.network.isRogue ? 'High' : 'Low',
              valueColor: widget.network.isRogue ? Colors.red : Colors.green),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6)),
          SizedBox(width: 20),
          Text(label, style: TextStyle(fontSize: 16, color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.8))),
          Spacer(),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor ?? NeumorphicTheme.defaultTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if(widget.network.isRogue) ...[
          SizedBox(
            width: double.infinity,
            child: NeumorphicButton(
              onPressed: _isReporting ? null : _reportRogueAP,
              style: NeumorphicStyle(color: Colors.orange.shade700, boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12))),
              padding: EdgeInsets.symmetric(vertical: 16),
              child: _isReporting
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Report this AP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: _isSaving ? null : _saveScan,
            style: NeumorphicStyle(color: Colors.blueAccent, boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12))),
            padding: EdgeInsets.symmetric(vertical: 16),
            child: _isSaving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save Scan to History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

