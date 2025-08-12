import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final appDocDirectory = await getApplicationDocumentsDirectory();
  await configureNetworkTools(appDocDirectory.path, enableDebugging: true);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: WiFiSecurityApp(),
    ),
  );
}

class WiFiSecurityApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return NeumorphicApp(
      title: 'WiFi Security',
      themeMode: themeManager.themeMode,
      theme: NeumorphicThemeData(
        baseColor: Color(0xFFF0F4F8),
        lightSource: LightSource.topLeft,
        depth: 10,
        intensity: 0.8,
        shadowLightColor: Colors.white,
        shadowDarkColor: Color(0xFFD1D9E6).withOpacity(0.5),
        variantColor: Color(0xFFE8F2FF),
        accentColor: Color(0xFF4A90E2),
        defaultTextColor: Color(0xFF2C3E50),
      ),
      darkTheme: NeumorphicThemeData.dark(
        baseColor: Color(0xFF2C2C2E),
        lightSource: LightSource.topLeft,
        depth: 8,
        intensity: 0.6,
        shadowLightColor: Color(0xFF404040),
        shadowDarkColor: Color(0xFF1C1C1E),
        variantColor: Color(0xFF3A3A3C),
        accentColor: Color(0xFF64B5F6),
        defaultTextColor: Color(0xFFE8E8E8),
      ),
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}
