import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';

import 'package:nirmal/features/authentication/screens/login/login.dart';
import 'package:nirmal/features/authentication/screens/onboarding/onboarding.dart';
import 'package:nirmal/features/authentication/screens/signup.widgets/signup.dart';
import 'package:nirmal/features/authentication/screens/signup.widgets/verify_email.dart';
import 'package:nirmal/features/shop/screens/home/home.dart';
import 'package:provider/provider.dart';

import 'package:nirmal/utils/constants/colors.dart';
import 'package:nirmal/utils/theme/theme.dart';
import 'package:nirmal/features/shop/screens/settings/settings_controller.dart';

// Import your screens (adjust paths as needed)

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to themeMode from the global SettingsController
    final themeMode = context.select<SettingsController, ThemeMode>(
      (ctrl) => ctrl.themeMode,
    );

    return GetMaterialApp(
      title: 'Nirmal',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      
      // Start with splash screen that decides where to go
      home: const SplashScreen(),
      // Define named routes for later navigation
      getPages: [
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/verify-email', page: () => const VerifyEmailScreen()),
        // Add more routes as needed
      ],
    );
  }
}

/// Splash screen that decides initial route based on first launch and auth state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideWhereToGo();
  }

  Future<void> _decideWhereToGo() async {
    // Small delay to let the splash screen show (optional)
    await Future.delayed(const Duration(milliseconds: 500));

    // 1. Check if it's the first launch using GetStorage
    final box = GetStorage();
    final isFirstTime = box.read('IsFirstTime') ?? true;

    if (isFirstTime) {
      // First launch → go to onboarding
      Get.offNamed('/onboarding');
      return;
    }

    // 2. Check if user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is authenticated → go to home
      Get.offNamed('/home');
    } else {
      // Not logged in → go to login
      Get.offNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a beautiful loading screen while deciding
    return Scaffold(
      backgroundColor: TColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optional: your app logo here
            // Image.asset('assets/logo.png', width: 120),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}