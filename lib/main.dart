import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final appDocDirectory = await getApplicationDocumentsDirectory();
  await configureNetworkTools(appDocDirectory.path, enableDebugging: true);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: VigilentApp(),
    ),
  );
}

class VigilentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return NeumorphicApp(
      title: 'Vigilent WiFi Manager',
      themeMode: themeManager.themeMode, // Controlled by the ThemeManager
      theme: NeumorphicThemeData(
        baseColor: Color(0xFFE0E5EC),
        lightSource: LightSource.topLeft,
        depth: 8,
        intensity: 0.7,
      ),
      darkTheme: NeumorphicThemeData.dark(
        baseColor: Color(0xFF3E3E3E),
        lightSource: LightSource.topLeft,
        depth: 4,
      ),
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}
