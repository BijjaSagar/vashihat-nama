import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

import 'services/notification_service.dart';
import 'services/background_alarm_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Firebase init with error handling - don't let it block app startup
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
  } catch (e) {
    debugPrint('Firebase init error (non-fatal): $e');
  }
  
  // Notification init with error handling - don't let it block app startup
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification init error (non-fatal): $e');
  }
  
  // Background heartbeat alarm service init
  try {
    await initBackgroundService();
  } catch (e) {
    debugPrint('Background service init error (non-fatal): $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ever Keep',
      theme: AppTheme.darkTheme, // Apply the new Dark Theme
      home: const SecureLoginScreen(), // Start with the new Secure Login Screen
    );
  }
}
