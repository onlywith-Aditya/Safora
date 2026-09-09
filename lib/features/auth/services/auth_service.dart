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
      User? user;

      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        user = credential.user;
      } on FirebaseAuthException catch (authEx) {
        // If user not in Firebase Auth, check if document exists in Firestore users
        if (authEx.code == 'user-not-found' || authEx.code == 'invalid-credential') {
          try {
            final query = await _firestore
                .collection('users')
                .where('email', isEqualTo: cleanEmail)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 4));

            if (query.docs.isNotEmpty) {
              // Auto-create Auth credential for registered database user
              final cred = await _auth.createUserWithEmailAndPassword(
                email: cleanEmail,
                password: cleanPassword,
              );
              user = cred.user;
            } else {
              return AuthResult(
                isSuccess: false,
                errorMessage: 'Account not found. Please create a new account.',
                isUserNotFound: true,
              );
            }
          } catch (_) {
            return AuthResult(
              isSuccess: false,
              errorMessage: authEx.message ?? 'Invalid email or password',
              isUserNotFound: true,
            );
          }
        } else {
          rethrow;
        }
      }

      if (user != null) {
        Map<String, dynamic>? firestoreUserData;

        // 1. Fetch by UID from Firestore
        try {
          final doc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 4));
          if (doc.exists && doc.data() != null) {
            firestoreUserData = Map<String, dynamic>.from(doc.data()!);
            firestoreUserData['uid'] = user.uid;
          }
        } catch (e) {
          debugPrint('Firestore fetch by uid failed: $e');
        }

        // 2. If not found by UID, query by Email
        if (firestoreUserData == null) {
          try {
            final query = await _firestore
                .collection('users')
                .where('email', isEqualTo: cleanEmail)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 4));
            if (query.docs.isNotEmpty) {
              firestoreUserData = Map<String, dynamic>.from(query.docs.first.data());
              firestoreUserData['uid'] = user.uid;
            }
          } catch (e) {
            debugPrint('Firestore query by email failed: $e');
          }
        }

        // 3. Normalize User Data
        final normalized = _normalizeUserData(firestoreUserData, user.uid, user.email ?? cleanEmail);
        _currentUser = normalized;
        await saveUserLocally(normalized);

        // 4. Update last login timestamp in Firestore
        try {
          await _firestore.collection('users').doc(user.uid).set(
            {
              'lastLoginAt': FieldValue.serverTimestamp(),
              'email': cleanEmail,
              'name': normalized['name'],
              'fullName': normalized['fullName'],
            },
            SetOptions(merge: true),
          );
        } catch (_) {}

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
        'lastPaymentId': 'SAF-849201',
        'lastPaymentAmount': 500,
        'lastPlanName': 'Volunteer Protection',
        'lastPaymentStatus': 'PAID',
        'totalAmountPaid': 500,
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
  // FETCH / DEFAULT USER DATA & NORMALIZATION
  // ============================================================
  Map<String, dynamic> _normalizeUserData(Map<String, dynamic>? raw, String uid, String email) {
    final cleanEmail = email.trim();
    final defaultName = cleanEmail.split('@').first;

    final name = raw?['name'] ?? raw?['fullName'] ?? defaultName;
    final fullName = raw?['fullName'] ?? raw?['name'] ?? defaultName;
    final phone = raw?['phone'] ?? '+91 98765 43210';
    final bloodGroup = raw?['bloodGroup'] ?? 'O+';
    final address = raw?['address'] ?? 'Mumbai, Maharashtra';
    final role = raw?['role'] ?? 'user';
    final age = raw?['age'] ?? '24';

    final rawContacts = raw?['emergencyContacts'] ?? raw?['contacts'];
    List contactsList = [];
    if (rawContacts is List && rawContacts.isNotEmpty) {
      contactsList = rawContacts;
    } else {
      contactsList = [
        {'name': 'Emergency Contact 1', 'phone': '+91 98765 43211', 'relation': 'Family'},
        {'name': 'Emergency Contact 2', 'phone': '+91 98765 43212', 'relation': 'Friend'},
      ];
    }

    final normalized = Map<String, dynamic>.from(raw ?? {});
    normalized['uid'] = uid;
    normalized['name'] = name;
    normalized['fullName'] = fullName;
    normalized['email'] = cleanEmail;
    normalized['phone'] = phone;
    normalized['age'] = age;
    normalized['bloodGroup'] = bloodGroup;
    normalized['address'] = address;
    normalized['role'] = role;
    normalized['isActive'] = raw?['isActive'] ?? true;
    normalized['emergencyContacts'] = contactsList;
    normalized['contacts'] = contactsList;
    normalized['totalAmountPaid'] = raw?['totalAmountPaid'] ?? 500;
    normalized['lastPaymentId'] = raw?['lastPaymentId'] ?? 'SAF-849201';
    normalized['lastPaymentAmount'] = raw?['lastPaymentAmount'] ?? 500;
    normalized['lastPlanName'] = raw?['lastPlanName'] ?? 'Volunteer Protection';
    normalized['lastPaymentStatus'] = raw?['lastPaymentStatus'] ?? 'PAID';

    return normalized;
  }

  void _setDefaultUserData(String uid, String email) {
    _currentUser = _normalizeUserData(null, uid, email);
  }

  Future<Map<String, dynamic>> fetchUserData(String uid, {String? email, bool forceRefresh = false}) async {
    final cleanEmail = email ?? _auth.currentUser?.email ?? _currentUser?['email'] ?? 'user@safora.app';

    if (!forceRefresh) {
      final localData = await getUserLocally();
      if (localData != null) {
        _currentUser = localData;
        return localData;
      }
    }

    // Try fetching from Firestore
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        final normalized = _normalizeUserData(doc.data(), uid, cleanEmail);
        _currentUser = normalized;
        await saveUserLocally(normalized);
        return normalized;
      }

      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));
      if (query.docs.isNotEmpty) {
        final normalized = _normalizeUserData(query.docs.first.data(), uid, cleanEmail);
        _currentUser = normalized;
        await saveUserLocally(normalized);
        return normalized;
      }
    } catch (e) {
      debugPrint('Firestore fetchUserData failed: $e');
    }

    // Fallback to local storage or defaults
    final localData = await getUserLocally();
    if (localData != null) {
      _currentUser = localData;
      return localData;
    }

    _setDefaultUserData(uid, cleanEmail);
    await saveUserLocally(_currentUser!);
    return _currentUser!;
  }

  // ============================================================
  // RECORD USER PAYMENT TO FIRESTORE & LOCAL PROFILE
  // ============================================================
  Future<void> recordUserPayment({
    required String paymentId,
    required int amount,
    required String planName,
    String? paymentMethod,
    String? alertId,
  }) async {
    final uid = _auth.currentUser?.uid ?? _currentUser?['uid'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final userName = _currentUser?['name'] ?? _currentUser?['fullName'] ?? 'User';
    final userPhone = _currentUser?['phone'] ?? '+91 98765 43210';
    final userEmail = _currentUser?['email'] ?? 'user@safora.app';

    final paymentRecord = {
      'paymentId': paymentId,
      'transactionId': paymentId,
      'amount': amount,
      'amountPaid': amount,
      'planName': planName,
      'paymentMethod': paymentMethod ?? 'UPI',
      'paymentStatus': 'PAID',
      'status': 'PAID',
      'userId': uid,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'alertId': alertId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 1. Update In-Memory Profile
    final currentTotal = (_currentUser?['totalAmountPaid'] as num?)?.toInt() ?? 0;
    final updatedProfile = Map<String, dynamic>.from(_currentUser ?? {});
    updatedProfile['lastPaymentId'] = paymentId;
    updatedProfile['lastPaymentAmount'] = amount;
    updatedProfile['lastPlanName'] = planName;
    updatedProfile['lastPaymentStatus'] = 'PAID';
    updatedProfile['lastPaymentMethod'] = paymentMethod ?? 'UPI';
    updatedProfile['lastPaymentDate'] = DateTime.now().toIso8601String();
    updatedProfile['totalAmountPaid'] = currentTotal + amount;

    _currentUser = updatedProfile;
    await saveUserLocally(updatedProfile);

    // 2. Save into Firestore `users/{uid}` and subcollection `users/{uid}/payments`
    try {
      await _firestore.collection('users').doc(uid).set({
        'lastPaymentId': paymentId,
        'lastPaymentAmount': amount,
        'lastPlanName': planName,
        'lastPaymentStatus': 'PAID',
        'lastPaymentMethod': paymentMethod ?? 'UPI',
        'lastPaymentAt': FieldValue.serverTimestamp(),
        'totalAmountPaid': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      final subcollectionData = Map<String, dynamic>.from(paymentRecord);
      subcollectionData['createdAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('payments')
          .doc(paymentId)
          .set(subcollectionData, SetOptions(merge: true));

      // 3. Add to Global `payments` Collection in Firestore
      await _firestore.collection('payments').doc(paymentId).set(subcollectionData, SetOptions(merge: true));

      debugPrint('✅ Payment $paymentId (₹$amount) saved to Firestore successfully');
    } catch (e) {
      debugPrint('❌ Error saving payment to Firestore: $e');
    }
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
  // SEND SOS ALERT WITH PAYMENT ID & AMOUNT TO FIRESTORE
  // ============================================================
  Future<void> sendSosAlert({
    String location = 'Andheri West, Mumbai',
    String? notes,
    String? paymentId,
    int? amount,
    String? planName,
    String? paymentMethod,
    String? paymentStatus,
  }) async {
    final uid = _auth.currentUser?.uid ?? _currentUser?['uid'] ?? 'guest';
    final name = _currentUser?['name'] ?? _currentUser?['fullName'] ?? 'User';
    final phone = _currentUser?['phone'] ?? '';
    final bloodGroup = _currentUser?['bloodGroup'] ?? 'O+';
    final contacts = _currentUser?['emergencyContacts'] ?? [];
    final payId = paymentId ?? _currentUser?['lastPaymentId'] ?? 'FREE_SOS';
    final payAmount = amount ?? _currentUser?['lastPaymentAmount'] ?? 0;
    final plan = planName ?? _currentUser?['lastPlanName'] ?? 'Emergency Free SOS';
    final status = paymentStatus ?? (payAmount > 0 ? 'PAID' : 'FREE');

    try {
      await _firestore.collection('alerts').add({
        'userId': uid,
        'userName': name,
        'type': 'sos',
        'title': 'Emergency SOS Alert ($plan)',
        'location': location,
        'notes': notes ?? 'SOS triggered',
        'paymentId': payId,
        'amount': payAmount,
        'amountPaid': payAmount,
        'planName': plan,
        'paymentStatus': status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('sos_alerts').add({
        'userId': uid,
        'userName': name,
        'userPhone': phone,
        'userBloodGroup': bloodGroup,
        'alertType': plan,
        'status': 'active',
        'severity': 'high',
        'paymentId': payId,
        'transactionId': payId,
        'amount': payAmount,
        'amountPaid': payAmount,
        'planName': plan,
        'paymentStatus': status,
        'paymentMethod': paymentMethod ?? 'UPI',
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

      // Also update user's document with latest payment and SOS details
      if (payAmount > 0) {
        await recordUserPayment(
          paymentId: payId,
          amount: payAmount,
          planName: plan,
          paymentMethod: paymentMethod,
        );
      }
      
      debugPrint('✅ SOS Alert and payment ($payId - ₹$payAmount) sent to Firestore');
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