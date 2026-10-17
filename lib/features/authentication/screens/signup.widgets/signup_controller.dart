import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nirmal/data/repositories/authentication_repository.dart';
import 'package:nirmal/features/authentication/screens/login/login_controller.dart';
import 'package:nirmal/features/authentication/screens/signup.widgets/verify_email.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Form ──────────────────────────────────────────────────────────────────
  final signupFormKey = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final phoneNumber = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  final isPrivacyAccepted = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    username.dispose();
    email.dispose();
    phoneNumber.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.onClose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SIGNUP  –  delegates to AuthenticationRepository (fixes Pigeon crash)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> signup() async {
    if (!signupFormKey.currentState!.validate()) return;

    if (!isPrivacyAccepted.value) {
      _snackbar('Privacy Policy', 'Please accept the privacy policy to continue.', color: Colors.orange);
      return;
    }

    isLoading.value = true;
    try {
      // 1 – Create Firebase Auth user via repository (single call path)
      final userCred = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      final user = userCred.user;
      if (user == null) throw 'User creation failed. Please try again.';

      // 2 – Update displayName so it's available before Firestore loads
      final fullName = '${firstName.text.trim()} ${lastName.text.trim()}';
      await user.updateDisplayName(fullName);

      // 3 – Write profile to Firestore
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': fullName,
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'username': username.text.trim().toLowerCase(),
        'email': email.text.trim().toLowerCase(),
        'phone': phoneNumber.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      // 4 – Send verification email
      await user.sendEmailVerification();

      isLoading.value = false;

      // 5 – Start polling via LoginController (single polling owner)
      LoginController.instance.startEmailVerificationPolling();

      Get.offAll(() => VerifyEmailScreen(email: email.text.trim()));
    } catch (e) {
      isLoading.value = false;
      // AuthenticationRepository throws plain String messages
      _snackbar('Signup Failed', e.toString(), color: Colors.red);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TOGGLE HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  void togglePasswordVisibility() => obscurePassword.toggle();
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.toggle();

  // ═════════════════════════════════════════════════════════════════════════
  // VALIDATORS
  // ═════════════════════════════════════════════════════════════════════════

  String? validateName(String? val) {
    if (val == null || val.trim().isEmpty) return 'This field is required';
    if (val.trim().length < 2) return 'Must be at least 2 characters';
    return null;
  }

  String? validateUsername(String? val) {
    if (val == null || val.trim().isEmpty) return 'Username is required';
    if (val.trim().length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val.trim())) {
      return 'Only letters, numbers and underscores allowed';
    }
    return null;
  }

  String? validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(val.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Password is required';
    if (val.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Please confirm your password';
    if (val != password.text) return 'Passwords do not match';
    return null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SNACKBAR
  // ═════════════════════════════════════════════════════════════════════════

  void _snackbar(String title, String message, {Color color = Colors.red}) {
    Get.snackbar(
      title, message,
      backgroundColor: color.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      icon: Icon(
        color == Colors.green
            ? Icons.check_circle_outline
            : color == Colors.orange
                ? Icons.warning_amber_outlined
                : Icons.error_outline,
        color: Colors.white,
      ),
    );
  }
}