import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sejahtera_ng/core/providers/theme_provider.dart';
import 'package:my_sejahtera_ng/core/screens/splash_screen.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/digital_health/services/notification_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env"); // Load env file
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    await NotificationService().init();
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    debugPrint('Initialization Error: $e');
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('App Initialization Error'), backgroundColor: Colors.red),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Fail: $e\n\nStackTrace:\n$stackTrace',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeId = ref.watch(themeProvider);
    
    // Enforce Clean Minimalist Theme for the Revamp
    final themeData = AppTheme.lightTheme;

    return MaterialApp(
      title: 'Smart HealthCare',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      // Temporarily disable darkTheme switch for custom themes to force the selected one
      // In a real app we might handle light/dark for each theme
      themeMode: ThemeMode.light, 
      home: const SplashScreen(),
    );
  }
}
