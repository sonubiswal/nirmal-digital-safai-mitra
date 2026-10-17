import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nirmal/data/repositories/authentication_repository.dart';
import 'package:nirmal/features/authentication/screens/login/login_controller.dart';
import 'package:nirmal/features/authentication/screens/signup.widgets/signup_controller.dart';
import 'package:nirmal/utils/notification_service.dart';
import 'package:provider/provider.dart';

import 'package:nirmal/common/widgets/network_manager.dart';


import 'package:nirmal/features/shop/screens/profile/profile_controller.dart';
import 'package:nirmal/features/shop/screens/settings/settings_controller.dart';
import 'app.dart';

void main() async {
  // Ensure widgets binding is initialized
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve splash screen until initialization completes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize local storage
  await GetStorage.init();

  // Initialize Firebase
  await Firebase.initializeApp();

  // ---------------------------------------------------------------------------
  // Firebase App Check
  //
  // Using DEBUG provider to avoid:
  // - Too many requests
  // - App Check token errors
  // - X-Firebase-Locale warnings
  //
  // In RELEASE MODE replace with:
  // AndroidProvider.playIntegrity
  // ---------------------------------------------------------------------------
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,     // ✔ SAFE FOR DEVELOPMENT
    appleProvider: AppleProvider.debug,
  );

  // Initialize notification service
  await NotificationService.initialize();

  // Enable Firestore offline caching
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  // ---------------------------------------------------------------------------
  // GetX – Core dependencies (permanent = survive route changes)
  // ---------------------------------------------------------------------------
  Get.put(NetworkManager(), permanent: true);
  Get.put(AuthenticationRepository(), permanent: true);
  Get.put(LoginController(), permanent: true);
  Get.put(SignupController(), permanent: true);

  // ---------------------------------------------------------------------------
  // Load user settings (Provider)
  // ---------------------------------------------------------------------------
  final settingsController = SettingsController();
  await settingsController.loadFromPrefs();

  // ---------------------------------------------------------------------------
  // Load user profile (Provider + GetX)
  // ---------------------------------------------------------------------------
  final profileController = ProfileController();
  await profileController.loadProfile(); // Will run even if user is null
  Get.put(profileController);

  // ---------------------------------------------------------------------------
  // Remove splash screen AFTER all async tasks complete
  // (AuthenticationRepository will also remove it safely)
  // ---------------------------------------------------------------------------
  FlutterNativeSplash.remove();

  // ---------------------------------------------------------------------------
  // Run the main app with providers
  // ---------------------------------------------------------------------------
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(
            value: settingsController),
        ChangeNotifierProvider<ProfileController>.value(
            value: profileController),
      ],
      child: const App(),
    ),
  );
}