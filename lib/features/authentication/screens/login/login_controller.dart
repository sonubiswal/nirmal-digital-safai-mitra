import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nirmal/data/repositories/authentication_repository.dart';
import 'package:nirmal/features/authentication/screens/signup.widgets/verify_email.dart';
import 'package:nirmal/home_menu.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Form ──────────────────────────────────────────────────────────────────
  final loginFormKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  final rememberMe = false.obs;
  final obscurePassword = true.obs;
  final isLoading = false.obs;

  // ── Internal ──────────────────────────────────────────────────────────────
  Timer? _verificationTimer;
  static const _pollInterval = Duration(seconds: 3);

  @override
  void onClose() {
    _verificationTimer?.cancel();
    email.dispose();
    password.dispose();
    super.onClose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // LOGIN  –  delegates to AuthenticationRepository (single source of truth)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      // AuthenticationRepository throws a plain String on FirebaseAuthException
      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      // Reload to get fresh emailVerified flag – local cache is always stale
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user == null) {
        isLoading.value = false;
        _snackbar('Error', 'Login failed. Please try again.', color: Colors.red);
        return;
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        startEmailVerificationPolling();
        isLoading.value = false;
        Get.offAll(() => VerifyEmailScreen(email: user.email));
        _snackbar(
          'Verify Email',
          'A verification link was sent to ${user.email}.',
          color: Colors.orange,
        );
        return;
      }

      isLoading.value = false;
      Get.offAll(() => const NavigationMenu());
    } catch (e) {
      isLoading.value = false;
      _snackbar('Login Failed', e.toString(), color: Colors.red);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EMAIL VERIFICATION POLLING
  // ═════════════════════════════════════════════════════════════════════════

  void startEmailVerificationPolling() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(_pollInterval, (_) => _checkVerified());
  }

  Future<void> _checkVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) { _verificationTimer?.cancel(); return; }

      await user.reload();
      final refreshed = _auth.currentUser!;

      if (refreshed.emailVerified) {
        _verificationTimer?.cancel();
        await _db.collection('users').doc(refreshed.uid).update({'emailVerified': true});
        _snackbar('Email Verified', 'Your email has been verified!', color: Colors.green);
        Get.offAll(() => const NavigationMenu());
      }
    } catch (_) {
      // Silently ignore network blips during polling
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.sendEmailVerification();
      _snackbar('Email Sent', 'A new verification link was sent to ${user.email}', color: Colors.blue);
    } catch (e) {
      _snackbar('Error', e.toString(), color: Colors.red);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> sendPasswordResetEmail(String emailAddress) async {
    if (emailAddress.trim().isEmpty) {
      _snackbar('Email Required', 'Please enter your email address.', color: Colors.orange);
      return;
    }
    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: emailAddress.trim());
      isLoading.value = false;
      _snackbar('Reset Email Sent', 'Password reset instructions sent to $emailAddress', color: Colors.green);
    } catch (e) {
      isLoading.value = false;
      _snackbar('Error', e.toString(), color: Colors.red);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    _verificationTimer?.cancel();
    await AuthenticationRepository.instance.logout();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TOGGLE HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  void togglePasswordVisibility() => obscurePassword.toggle();

  // ═════════════════════════════════════════════════════════════════════════
  // VALIDATORS
  // ═════════════════════════════════════════════════════════════════════════

  String? validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Password is required';
    if (val.length < 6) return 'Password must be at least 6 characters';
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