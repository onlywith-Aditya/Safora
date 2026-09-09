import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/local_storage_service.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool isUserNotFound;

  AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.isUserNotFound = false,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _storage = LocalStorageService();

  static const String _prefUserKey = 'safora_cached_user';

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;
  User? get currentFirebaseUser => _auth.currentUser;

  // ============================================================
  // LOCAL STORAGE
  // ============================================================
  Future<void> saveUserLocally(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanMap = Map<String, dynamic>.from(userData);
      cleanMap.removeWhere((key, value) => value is FieldValue);
      await prefs.setString(_prefUserKey, jsonEncode(cleanMap));
      await _storage.saveUserData(cleanMap);
    } catch (e) {
      debugPrint('Error saving locally: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserLocally() async {
    try {
      final local = await _storage.getUserData();
      if (local != null) return local;

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefUserKey);
      if (userJson != null && userJson.isNotEmpty) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading local: $e');
    }
    return null;
  }

  Future<void> clearUserLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserKey);
      await _storage.clearAll();
    } catch (e) {
      debugPrint('Error clearing local: $e');
    }
  }

  // ============================================================
  // AUTO LOGIN
  // ============================================================
  Future<bool> tryAutoLogin() async {
    try {
      // 1. Check local storage
      final localUser = await getUserLocally();
      if (localUser != null) {
        _currentUser = localUser;
        return true;
      }

      // 2. Check Firebase auth session
      final user = _auth.currentUser;
      if (user != null) {
        await fetchUserData(user.uid, email: user.email);
        return true;
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
    }
    return false;
  }

  // ============================================================
  // LOGIN
  // ============================================================
  Future<AuthResult> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Please enter both email and password',
        isUserNotFound: true,
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user != null) {
        _setDefaultUserData(user.uid, user.email ?? cleanEmail);
        await saveUserLocally(_currentUser!);

        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = Map<String, dynamic>.from(doc.data()!);
            data['uid'] = user.uid;
            _currentUser = data;
            await saveUserLocally(data);
          }
        } catch (e) {
          debugPrint('Firestore fetch failed (using local): $e');
        }

        return AuthResult(isSuccess: true);
      }

      return AuthResult(isSuccess: false, errorMessage: 'Login failed', isUserNotFound: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return AuthResult(isSuccess: false, errorMessage: 'Account does not exist. Please register.', isUserNotFound: true);
      }
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return AuthResult(isSuccess: false, errorMessage: 'Incorrect password', isUserNotFound: true);
      }
      return AuthResult(isSuccess: false, errorMessage: e.message ?? 'Login failed', isUserNotFound: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: 'Login error: $e', isUserNotFound: true);
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================
  Future<AuthResult> register(Map<String, dynamic> userData) async {
    final cleanEmail = (userData['email'] as String).trim();
    final cleanPassword = (userData['password'] as String).trim();
    final displayName = (userData['name'] ?? userData['fullName'] ?? 'User').toString().trim();
    final contactsList = (userData['contacts'] ?? userData['emergencyContacts'] ?? []) as List;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult(isSuccess: false, errorMessage: 'Registration failed');
      }

      final userProfileData = {
        'uid': user.uid,
        'fullName': displayName,
        'name': displayName,
        'email': cleanEmail,
        'phone': userData['phone'] ?? '',
        'age': userData['age'] ?? '',
        'bloodGroup': userData['bloodGroup'] ?? 'O+',
        'address': userData['address'] ?? '',
        'role': 'user',
        'isActive': true,
        'emergencyContacts': contactsList,
        'contacts': contactsList,
        'settings': {
          'voiceDetection': true,
          'locationTracking': true,
          'smsAlerts': true,
          'whatsappAlerts': true,
        },
        'safetyStats': {
          'totalSOS': 0,
          'totalFakeCalls': 0,
        },
      };

      _currentUser = Map<String, dynamic>.from(userProfileData);
      await saveUserLocally(userProfileData);

      try {
        final firestoreData = Map<String, dynamic>.from(userProfileData);
        firestoreData['createdAt'] = FieldValue.serverTimestamp();
        firestoreData['lastLoginAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).set(firestoreData, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore save failed (offline mode): $e');
      }

      return AuthResult(isSuccess: true);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Registration failed';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already registered. Please login.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak. Minimum 6 characters.';
      }
      return AuthResult(isSuccess: false, errorMessage: msg);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  // ============================================================
  // FETCH / DEFAULT USER DATA
  // ============================================================
  void _setDefaultUserData(String uid, String email) {
    final defaultName = email.split('@').first;
    _currentUser = {
      'uid': uid,
      'name': defaultName,
      'fullName': defaultName,
      'email': email,
      'phone': '+91 98765 43210',
      'age': '24',
      'bloodGroup': 'O+',
      'address': 'Mumbai, Maharashtra',
      'role': 'user',
      'isActive': true,
      'contacts': [
        {'name': 'Emergency Contact 1', 'phone': '+91 98765 43211', 'relation': 'Family'},
        {'name': 'Emergency Contact 2', 'phone': '+91 98765 43212', 'relation': 'Friend'},
      ],
      'emergencyContacts': [
        {'name': 'Emergency Contact 1', 'phone': '+91 98765 43211', 'relation': 'Family'},
        {'name': 'Emergency Contact 2', 'phone': '+91 98765 43212', 'relation': 'Friend'},
      ],
      'settings': {
        'voiceDetection': true,
        'locationTracking': true,
        'smsAlerts': true,
      },
      'safetyStats': {
        'totalSOS': 0,
        'totalFakeCalls': 0,
      },
    };
  }

  Future<void> fetchUserData(String uid, {String? email}) async {
    final localData = await getUserLocally();
    if (localData != null) {
      _currentUser = localData;
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = doc.data();
        await saveUserLocally(_currentUser!);
        return;
      }
    } catch (_) {}

    _setDefaultUserData(uid, email ?? 'user@safora.app');
    await saveUserLocally(_currentUser!);
  }

  // ============================================================
  // UPDATE CONTACTS
  // ============================================================
  Future<bool> updateContacts(List<Map<String, dynamic>> contacts) async {
    final uid = _auth.currentUser?.uid ?? _currentUser?['uid'];
    
    if (_currentUser != null) {
      _currentUser!['contacts'] = contacts;
      _currentUser!['emergencyContacts'] = contacts;
      await saveUserLocally(_currentUser!);
    }
    
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'contacts': contacts,
          'emergencyContacts': contacts,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Contacts update error: $e');
      }
    }
    
    return true;
  }

  // ============================================================
  // UPDATE USER PROFILE
  // ============================================================
  Future<bool> updateUserProfile({
    required String name,
    required String phone,
    required String bloodGroup,
    required String address,
    String? age,
  }) async {
    final uid = _auth.currentUser?.uid ?? _currentUser?['uid'];
    
    final updates = {
      'name': name.trim(),
      'fullName': name.trim(),
      'phone': phone.trim(),
      'bloodGroup': bloodGroup.trim(),
      'address': address.trim(),
      if (age != null) 'age': age.trim(),
    };
    
    if (_currentUser != null) {
      _currentUser!.addAll(updates);
      await saveUserLocally(_currentUser!);
    }
    
    if (uid != null) {
      try {
        final firestoreUpdates = Map<String, dynamic>.from(updates);
        firestoreUpdates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(uid).set(firestoreUpdates, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Profile update error: $e');
      }
    }
    
    return true;
  }

  // ============================================================
  // GET ALERTS STREAM
  // ============================================================
  Stream<List<Map<String, dynamic>>> getAlertsStream() {
    try {
      return _firestore
          .collection('alerts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Alerts stream error: $e');
      return Stream.value([]);
    }
  }

  // ============================================================
  // SEND SOS ALERT
  // ============================================================
  Future<void> sendSosAlert({
    String location = 'Andheri West, Mumbai',
    String? notes,
  }) async {
    final uid = _auth.currentUser?.uid ?? _currentUser?['uid'] ?? 'guest';
    final name = _currentUser?['name'] ?? _currentUser?['fullName'] ?? 'User';
    final phone = _currentUser?['phone'] ?? '';
    final bloodGroup = _currentUser?['bloodGroup'] ?? 'O+';
    final contacts = _currentUser?['emergencyContacts'] ?? [];

    try {
      await _firestore.collection('alerts').add({
        'userId': uid,
        'userName': name,
        'type': 'sos',
        'title': 'Emergency SOS Alert',
        'location': location,
        'notes': notes ?? 'SOS triggered',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('sos_alerts').add({
        'userId': uid,
        'userName': name,
        'userPhone': phone,
        'userBloodGroup': bloodGroup,
        'alertType': 'manual',
        'status': 'active',
        'severity': 'high',
        'location': {
          'lat': 19.0760,
          'lng': 72.8777,
          'address': location,
          'capturedAt': FieldValue.serverTimestamp(),
        },
        'emergencyContacts': contacts,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ SOS Alert sent successfully');
    } catch (e) {
      debugPrint('❌ SOS Alert error: $e');
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await clearUserLocally();
    _currentUser = null;
  }
}