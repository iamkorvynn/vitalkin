import 'package:flutter/material.dart';

import 'db/app_database.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const VitalKinApp());
}

class VitalKinApp extends StatefulWidget {
  const VitalKinApp({super.key});

  @override
  State<VitalKinApp> createState() => _VitalKinAppState();
}

class _VitalKinAppState extends State<VitalKinApp> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final done = await AppDatabase.instance.isOnboardingDone();
    if (mounted) setState(() => _onboardingDone = done);
  }

  Future<void> _finishOnboarding() async {
    await AppDatabase.instance.setOnboardingDone();
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalKin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _onboardingDone == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _onboardingDone!
              ? const HomeScreen()
              : OnboardingScreen(onDone: _finishOnboarding),
    );
  }
}
