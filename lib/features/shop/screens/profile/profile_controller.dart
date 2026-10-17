import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


const String kAdminSecretCode = 'Admin@1';

enum UserRole { user, admin }

class UserProfile {
  final String uid;
  String name;
  String email;
  String phone;
  UserRole role;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid:   uid,
      name:  map['name']  as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role:  (map['role'] as String?) == 'admin' ? UserRole.admin : UserRole.user,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':  name,
    'email': email,
    'phone': phone,
    'role':  role == UserRole.admin ? 'admin' : 'user',
  };
}

class ProfileController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  UserProfile? profile;
  bool         isLoading      = false;
  String?      error;

  bool         roleVerifying  = false;
  String?      roleError;

  bool get isAdmin => profile?.role == UserRole.admin;

  String get initials {
    final name = profile?.name ?? '';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> loadProfile() async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        profile = UserProfile.fromMap(doc.data()!, uid);
      } else {
        final user = _auth.currentUser!;
        profile = UserProfile(
          uid:   uid,
          name:  user.displayName ?? '',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          role:  UserRole.user,
        );
        await _firestore.collection('users').doc(uid).set(profile!.toMap());
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await _firestore.collection('users').doc(uid).set({
        'name':  name,
        'email': email,
        'phone': phone,
        'role':  profile?.role == UserRole.admin ? 'admin' : 'user',
      }, SetOptions(merge: true));

      profile?.name  = name;
      profile?.email = email;
      profile?.phone = phone;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyAndChangeRole(UserRole newRole, String? enteredCode) async {
    roleVerifying = true;
    roleError     = null;
    notifyListeners();

    try {
      if (newRole == UserRole.admin) {
        if (enteredCode == null || enteredCode.trim() != kAdminSecretCode) {
          roleError = 'Incorrect secret code. Please check with your developer.';
          return false;
        }
      }

      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final roleStr = newRole == UserRole.admin ? 'admin' : 'user';
      await _firestore.collection('users').doc(uid).update({'role': roleStr});
      profile?.role = newRole;
      return true;
    } catch (e) {
      roleError = e.toString();
      return false;
    } finally {
      roleVerifying = false;
      notifyListeners();
    }
  }

  void clearRoleError() {
    roleError = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    profile = null;
    notifyListeners();
    // Navigation to login screen removed as requested
  }

  Future<bool> deleteAccount() async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).delete();
      }
      await _auth.currentUser?.delete();
      profile = null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}