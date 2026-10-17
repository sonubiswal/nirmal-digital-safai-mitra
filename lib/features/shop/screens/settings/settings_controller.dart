import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';               // ✅ added for snackbar
import 'package:shared_preferences/shared_preferences.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum AppearanceMode { light, dark, system }

enum AppLanguage { english, hindi, marathi, gujarati, tamil, telugu }

extension AppearanceModeLabel on AppearanceMode {
  String get label {
    switch (this) {
      case AppearanceMode.light:   return 'Light';
      case AppearanceMode.dark:    return 'Dark';
      case AppearanceMode.system:  return 'System';
    }
  }
  ThemeMode get themeMode {
    switch (this) {
      case AppearanceMode.light:   return ThemeMode.light;
      case AppearanceMode.dark:    return ThemeMode.dark;
      case AppearanceMode.system:  return ThemeMode.system;
    }
  }
}

extension AppLanguageLabel on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.english:   return 'English';
      case AppLanguage.hindi:     return 'हिन्दी (Hindi)';
      case AppLanguage.marathi:   return 'मराठी (Marathi)';
      case AppLanguage.gujarati:  return 'ગુજરાતી (Gujarati)';
      case AppLanguage.tamil:     return 'தமிழ் (Tamil)';
      case AppLanguage.telugu:    return 'తెలుగు (Telugu)';
    }
  }
  String get code {
    switch (this) {
      case AppLanguage.english:   return 'en';
      case AppLanguage.hindi:     return 'hi';
      case AppLanguage.marathi:   return 'mr';
      case AppLanguage.gujarati:  return 'gu';
      case AppLanguage.tamil:     return 'ta';
      case AppLanguage.telugu:    return 'te';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class SettingsController extends ChangeNotifier {
  static const _keyAppearance        = 'appearance_mode';
  static const _keyAppLanguage       = 'app_language';
  static const _keyNotifications     = 'notifications_enabled';

  // ── Appearance / Language / Notifications (local prefs) ──────────────────
  AppearanceMode _appearanceMode    = AppearanceMode.system;
  AppLanguage    _appLanguage       = AppLanguage.english;
  bool           _notificationsEnabled = true;
  bool           _isFeedbackLoading = false;
  String?        _feedbackError;

  // ── Profile (read-only, sourced from Firebase Auth + Firestore) ───────────
  // These are populated by loadProfileFromFirebase() and never edited here.
  String _userName   = '';
  String _userEmail  = '';
  String _userPhone  = '';
  String _userRole   = 'user';    // 'user' | 'admin'
  bool   _isProfileLoading = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  AppearanceMode get appearanceMode       => _appearanceMode;
  AppLanguage    get appLanguage          => _appLanguage;
  bool           get notificationsEnabled => _notificationsEnabled;
  bool           get isFeedbackLoading    => _isFeedbackLoading;
  String?        get feedbackError        => _feedbackError;
  ThemeMode      get themeMode            => _appearanceMode.themeMode;

  // Profile – read only
  String get userName          => _userName;
  String get userEmail         => _userEmail;
  String get userPhone         => _userPhone;
  String get userRole          => _userRole;
  bool   get isProfileLoading  => _isProfileLoading;
  bool   get isAdmin           => _userRole == 'admin';

  String get userInitials {
    final parts = _userName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final appearanceIndex = prefs.getInt(_keyAppearance) ?? 2;
    _appearanceMode = AppearanceMode.values[appearanceIndex.clamp(0, AppearanceMode.values.length - 1)];

    final appLangIndex = prefs.getInt(_keyAppLanguage) ?? 0;
    _appLanguage = AppLanguage.values[appLangIndex.clamp(0, AppLanguage.values.length - 1)];

    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;

    notifyListeners();

    // Also pull fresh profile from Firebase
    await loadProfileFromFirebase();
  }

  // ── Profile – load from Firebase (read-only in Settings) ─────────────────

  /// Pulls name, email, phone, role from Firestore.
  /// Settings screen shows this as view-only — editing happens in ProfileScreen.
  Future<void> loadProfileFromFirebase() async {
    _isProfileLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isProfileLoading = false;
        notifyListeners();
        return;
      }

      // Always reload so emailVerified + displayName are fresh
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser!;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshed.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _userName  = data['name']  as String? ?? refreshed.displayName ?? '';
        _userEmail = data['email'] as String? ?? refreshed.email ?? '';
        _userPhone = data['phone'] as String? ?? '';
        _userRole  = data['role']  as String? ?? 'user';
      } else {
        // Fallback to Auth data if Firestore doc missing
        _userName  = refreshed.displayName ?? '';
        _userEmail = refreshed.email ?? '';
        _userPhone = refreshed.phoneNumber ?? '';
        _userRole  = 'user';
      }
    } catch (_) {
      // Silently fail – profile stays blank/stale
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  /// Called by ProfileScreen after it saves changes so Settings header
  /// reflects the latest values instantly without another Firestore fetch.
  void refreshProfileLocally({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) {
    _userName  = name;
    _userEmail = email;
    _userPhone = phone;
    _userRole  = role;
    notifyListeners();
  }

  // ── Appearance ────────────────────────────────────────────────────────────

  Future<void> setAppearanceMode(AppearanceMode mode) async {
    if (_appearanceMode == mode) return;
    _appearanceMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAppearance, mode.index);
  }

  // ── Language ──────────────────────────────────────────────────────────────

  Future<void> setAppLanguage(AppLanguage lang) async {
    if (_appLanguage == lang) return;
    _appLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAppLanguage, lang.index);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  // ── Feedback → Firebase Firestore ─────────────────────────────────────────

  Future<bool> submitFeedback(String message) async {
    if (message.trim().isEmpty) {
      _feedbackError = 'Please enter your feedback before submitting.';
      notifyListeners();
      return false;
    }

    _isFeedbackLoading = true;
    _feedbackError = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('feedback').add({
        'message':   message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        if (uid != null) 'userId': uid,
        'platform':  'flutter',
      });

      // ✅ Show success snackbar
      Get.snackbar(
        'Success',
        'Thank you for your feedback!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      _isFeedbackLoading = false;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _isFeedbackLoading = false;
      _feedbackError = e.message ?? 'Failed to send feedback. Try again.';
      notifyListeners();
      return false;
    } catch (_) {
      _isFeedbackLoading = false;
      _feedbackError = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearFeedbackError() {
    if (_feedbackError != null) {
      _feedbackError = null;
      notifyListeners();
    }
  }
}