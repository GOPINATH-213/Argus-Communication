import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/storage/hive_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/name_collection_screen.dart';
import 'features/home/screens/home_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HiveService.init();
  } catch (e) {
    debugPrint("Failed to initialize Hive: $e");
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env: $e");
  }

  try {
    await NotificationService.init();

    final reminderTime = HiveService.getReminderTime();
    final parts = reminderTime.split(':');

    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 20;
      final minute = int.tryParse(parts[1]) ?? 0;

      await NotificationService.scheduleDailyReminder(hour, minute);
    }
  } catch (e) {
    debugPrint("Notification initialization failed: $e");
  }

  runApp(const ProviderScope(child: ArgusApp()));
}

class ArgusApp extends StatelessWidget {
  const ArgusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Argus Communication',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/onboarding': (context) => const NameCollectionScreen(),
        '/home': (context) => const HomeDashboard(),
      },
    );
  }
}
