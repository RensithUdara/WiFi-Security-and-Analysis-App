import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
class ComingSoonPlaceholder extends StatelessWidget {
  final String title;
  const ComingSoonPlaceholder({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicIcon(
              Icons.hourglass_empty_rounded,
              size: 80,
              style: NeumorphicStyle(
                  color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.5),
                  depth: 10,
                  intensity: 0.8
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NeumorphicTheme.defaultTextColor(context),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This feature is under construction.',
              style: TextStyle(
                fontSize: 16,
                color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
