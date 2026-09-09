import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/local_storage_service.dart';
import '../../auth/services/auth_service.dart';

class VolunteerService {
  static final VolunteerService _instance = VolunteerService._internal();
  factory VolunteerService() => _instance;
  VolunteerService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _storage = LocalStorageService();

  Map<String, dynamic>? _currentVolunteer;
  Map<String, dynamic>? get currentVolunteer => _currentVolunteer;

  /// Normalizes volunteer data to guarantee required keys are present
  Map<String, dynamic> _normalizeVolunteerData(Map<String, dynamic>? raw, String uid, String email) {
    final cleanEmail = email.trim();
    final defaultName = cleanEmail.split('@').first;

    final name = raw?['name'] ?? raw?['fullName'] ?? defaultName;
    final fullName = raw?['fullName'] ?? raw?['name'] ?? defaultName;
    final phone = raw?['phone'] ?? '+91 98201 12345';
    final idType = raw?['idType'] ?? 'Aadhaar Card';
    final affiliation = raw?['affiliation'] ?? 'College / Campus (NSS-NCC)';
    final institution = raw?['institution'] ?? 'Safora Volunteer Network';
    final isVerified = raw?['isVerified'] ?? true;
    final verificationStatus = raw?['verificationStatus'] ?? 'approved';
    final dutyStatus = raw?['dutyStatus'] ?? 'on_duty';
    final respondedCount = (raw?['respondedCount'] as num?)?.toInt() ?? 0;
    final rating = (raw?['rating'] as num?)?.toDouble() ?? 4.9;
    final coverageRadiusKm = (raw?['coverageRadiusKm'] as num?)?.toDouble() ?? 1.8;

    final normalized = Map<String, dynamic>.from(raw ?? {});
    normalized['uid'] = uid;
    normalized['name'] = name;
    normalized['fullName'] = fullName;
    normalized['email'] = cleanEmail;
    normalized['phone'] = phone;
    normalized['idType'] = idType;
    normalized['affiliation'] = affiliation;
    normalized['institution'] = institution;
    normalized['role'] = 'volunteer';
    normalized['isVerified'] = isVerified;
    normalized['verificationStatus'] = verificationStatus;
    normalized['dutyStatus'] = dutyStatus;
    normalized['respondedCount'] = respondedCount;
    normalized['rating'] = rating;
    normalized['coverageRadiusKm'] = coverageRadiusKm;
    normalized['currentLocation'] = raw?['currentLocation'] ?? {
      'latitude': 19.1136,
      'longitude': 72.8697,
      'area': 'Andheri West, Mumbai',
    };

    return normalized;
  }

  /// Login Volunteer with Email & Password and fetch details from Firestore 'volunteers' collection
  Future<AuthResult> loginVolunteer(String email, String password) async {
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
        if (authEx.code == 'user-not-found' || authEx.code == 'invalid-credential') {
          // Check if volunteer exists in Firestore
          try {
            final query = await _firestore
                .collection('volunteers')
                .where('email', isEqualTo: cleanEmail)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 4));

            if (query.docs.isNotEmpty) {
              final cred = await _auth.createUserWithEmailAndPassword(
                email: cleanEmail,
                password: cleanPassword,
              );
              user = cred.user;
            } else {
              return AuthResult(
                isSuccess: false,
                errorMessage: 'Volunteer account not found. Please join as a volunteer.',
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
        Map<String, dynamic>? volunteerDoc;

        // 1. Try fetching document by UID from volunteers collection
        try {
          final doc = await _firestore
              .collection('volunteers')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 4));
          if (doc.exists && doc.data() != null) {
            volunteerDoc = Map<String, dynamic>.from(doc.data()!);
            volunteerDoc['uid'] = user.uid;
          }
        } catch (e) {
          debugPrint('Firestore fetch by uid failed: $e');
        }

        // 2. If not found by doc id, query by email in volunteers collection
        if (volunteerDoc == null) {
          try {
            final query = await _firestore
                .collection('volunteers')
                .where('email', isEqualTo: cleanEmail)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 4));
            if (query.docs.isNotEmpty) {
              volunteerDoc = Map<String, dynamic>.from(query.docs.first.data());
              volunteerDoc['uid'] = user.uid;
            }
          } catch (e) {
            debugPrint('Firestore query by email failed: $e');
          }
        }

        // 3. Fallback: check users collection
        if (volunteerDoc == null) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(user.uid)
                .get()
                .timeout(const Duration(seconds: 4));
            if (userDoc.exists && userDoc.data() != null) {
              volunteerDoc = Map<String, dynamic>.from(userDoc.data()!);
              volunteerDoc['uid'] = user.uid;
            }
          } catch (_) {}
        }

        // 4. Normalize Volunteer Data
        final normalized = _normalizeVolunteerData(volunteerDoc, user.uid, user.email ?? cleanEmail);
        _currentVolunteer = normalized;
        await _storage.saveVolunteerData(normalized);

        // 5. Update last login in Firestore
        try {
          await _firestore.collection('volunteers').doc(user.uid).set(
            {
              'lastLoginAt': FieldValue.serverTimestamp(),
              'email': cleanEmail,
              'name': normalized['name'],
              'fullName': normalized['fullName'],
              'dutyStatus': normalized['dutyStatus'],
              'isVerified': normalized['isVerified'],
            },
            SetOptions(merge: true),
          );
        } catch (_) {}

        return AuthResult(isSuccess: true);
      }

      return AuthResult(isSuccess: false, errorMessage: 'Volunteer login failed', isUserNotFound: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return AuthResult(isSuccess: false, errorMessage: 'Volunteer account not found. Please join as a volunteer.', isUserNotFound: true);
      }
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return AuthResult(isSuccess: false, errorMessage: 'Incorrect password', isUserNotFound: true);
      }
      return AuthResult(isSuccess: false, errorMessage: e.message ?? 'Volunteer login failed', isUserNotFound: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: 'Login error: $e', isUserNotFound: true);
    }
  }

  /// Register Volunteer and save complete profile to 'volunteers' collection in Firestore & Device Storage
  Future<AuthResult> registerVolunteer(Map<String, dynamic> volunteerData) async {
    final cleanEmail = (volunteerData['email'] as String).trim();
    final cleanPassword = (volunteerData['password'] as String).trim();

    String uid = 'vol_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      if (credential.user != null) {
        uid = credential.user!.uid;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final cred = await _auth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          if (cred.user != null) {
            uid = cred.user!.uid;
          }
        } catch (_) {}
      }
    } catch (_) {}

    final completeVolunteerProfile = {
      'uid': uid,
      'fullName': volunteerData['name'] ?? volunteerData['fullName'] ?? 'Volunteer',
      'name': volunteerData['name'] ?? volunteerData['fullName'] ?? 'Volunteer',
      'email': cleanEmail,
      'phone': volunteerData['phone'] ?? '',
      'idType': volunteerData['idType'] ?? 'Aadhaar Card',
      'idPhoto': volunteerData['idPhoto'] ?? '',
      'affiliation': volunteerData['affiliation'] ?? 'College / Campus (NSS-NCC)',
      'institution': volunteerData['institution'] ?? '',
      'role': 'volunteer',
      'isVerified': false,
      'verificationStatus': 'pending',
      'dutyStatus': 'off_duty',
      'respondedCount': 0,
      'rating': 4.9,
      'coverageRadiusKm': 1.8,
      'currentLocation': {
        'latitude': 19.1136,
        'longitude': 72.8697,
        'area': 'Andheri West, Mumbai',
      },
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _storage.saveVolunteerData(completeVolunteerProfile);
    _currentVolunteer = completeVolunteerProfile;

    try {
      final firestoreData = Map<String, dynamic>.from(completeVolunteerProfile);
      firestoreData['createdAt'] = FieldValue.serverTimestamp();
      firestoreData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('volunteers').doc(uid).set(
        firestoreData,
        SetOptions(merge: true),
      );
    } catch (_) {}

    return AuthResult(isSuccess: true);
  }

  /// Fetch volunteer data from local storage or Firestore
  Future<Map<String, dynamic>> loadVolunteerProfile({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    final cleanEmail = user?.email ?? _currentVolunteer?['email'] ?? 'volunteer@safora.app';
    final uid = user?.uid ?? _currentVolunteer?['uid'] ?? 'vol_mock';

    if (!forceRefresh) {
      final localData = await _storage.getVolunteerData();
      if (localData != null) {
        _currentVolunteer = localData;
        return localData;
      }
    }

    if (user != null) {
      try {
        final doc = await _firestore
            .collection('volunteers')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          final normalized = _normalizeVolunteerData(doc.data(), user.uid, cleanEmail);
          _currentVolunteer = normalized;
          await _storage.saveVolunteerData(normalized);
          return normalized;
        }

        // Query by email
        if (cleanEmail.isNotEmpty) {
          final query = await _firestore
              .collection('volunteers')
              .where('email', isEqualTo: cleanEmail)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 4));
          if (query.docs.isNotEmpty) {
            final normalized = _normalizeVolunteerData(query.docs.first.data(), user.uid, cleanEmail);
            _currentVolunteer = normalized;
            await _storage.saveVolunteerData(normalized);
            return normalized;
          }
        }
      } catch (e) {
        debugPrint('Firestore volunteer fetch error: $e');
      }
    }

    final localData = await _storage.getVolunteerData();
    if (localData != null) {
      _currentVolunteer = localData;
      return localData;
    }

    final normalized = _normalizeVolunteerData(null, uid, cleanEmail);
    _currentVolunteer = normalized;
    await _storage.saveVolunteerData(normalized);
    return normalized;
  }

  /// Toggle Duty Status (on_duty / off_duty)
  Future<bool> toggleDutyStatus(bool isOnDuty) async {
    await _storage.setVolunteerDuty(isOnDuty);

    if (_currentVolunteer != null) {
      _currentVolunteer!['dutyStatus'] = isOnDuty ? 'on_duty' : 'off_duty';
      await _storage.saveVolunteerData(_currentVolunteer!);
    }

    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('volunteers').doc(uid).set({
          'dutyStatus': isOnDuty ? 'on_duty' : 'off_duty',
          'isAvailable': isOnDuty,
          'lastDutyToggle': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    return isOnDuty;
  }

  /// Get Duty Status
  Future<bool> getDutyStatus() async {
    return await _storage.getVolunteerDuty();
  }

  /// Real-time stream of incoming active alerts within radius
  Stream<List<Map<String, dynamic>>> getIncomingAlertsStream() {
    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid ?? 'vol_mock';
    try {
      return _firestore
          .collection('emergency_alerts')
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['alertId'] = data['alertId'] ?? doc.id;
              return data;
            })
            .where((alert) {
              final declined = alert['declinedBy'];
              if (declined is List && declined.contains(uid)) {
                return false;
              }
              return true;
            })
            .toList();
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Accept SOS Alert - increments volunteer earnings dynamically
  Future<bool> acceptSosAlert(String alertId, {int earningAmount = 500, String? paymentId}) async {
    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid ?? 'vol_mock';
    final name = _currentVolunteer?['fullName'] ?? 'Aarav Sharma';
    final phone = _currentVolunteer?['phone'] ?? '+91 98201 12345';
    final txnId = paymentId ?? 'PAY_SAFE_${DateTime.now().millisecondsSinceEpoch}';

    // Increase total volunteer earnings upon accepting client deal
    final earnings = await _storage.getVolunteerEarnings();
    final currentTotal = (earnings['total'] as num?)?.toInt() ?? 0;
    earnings['total'] = currentTotal + earningAmount;
    await _storage.saveVolunteerEarnings(earnings);

    // Save transaction to local storage
    final txns = await _storage.getEarningsTransactions();
    txns.insert(0, {
      'id': txnId,
      'title': 'Emergency Protection Deal Accepted',
      'victimName': 'Emergency Assistance',
      'date': 'Today, ${_formatTime(DateTime.now())}',
      'amount': earningAmount,
      'status': 'Settled & Verified',
      'paymentId': txnId,
      'type': 'credit',
    });
    await _storage.saveEarningsTransactions(txns);

    // Increment responded count in volunteer profile
    if (_currentVolunteer != null) {
      final count = (_currentVolunteer!['respondedCount'] ?? 0) as int;
      _currentVolunteer!['respondedCount'] = count + 1;
      await _storage.saveVolunteerData(_currentVolunteer!);
    }

    try {
      await _firestore.collection('emergency_alerts').doc(alertId).set({
        'status': 'accepted',
        'acceptedBy': {
          'volunteerId': uid,
          'volunteerName': name,
          'volunteerPhone': phone,
          'acceptedAt': FieldValue.serverTimestamp(),
          'earningAmount': earningAmount,
          'paymentId': txnId,
        },
      }, SetOptions(merge: true));

      // Also update in sos_alerts for real-time sync with user screen
      await _firestore.collection('sos_alerts').doc(alertId).set({
        'status': 'volunteer_assigned',
        'assignedVolunteer': {
          'volunteerId': uid,
          'name': name,
          'phone': phone,
          'eta': '4 mins',
          'distance': '450m',
          'acceptedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // Update volunteer stats in Firestore
      if (uid.isNotEmpty) {
        await _firestore.collection('volunteers').doc(uid).set({
          'totalEarnings': FieldValue.increment(earningAmount),
          'respondedCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      debugPrint('Accept alert offline mode: $e');
      return true;
    }
  }

  /// Decline Alert
  Future<void> declineSosAlert(String alertId) async {
    try {
      final uid = _currentVolunteer?['uid'] ?? 'vol_mock';
      await _firestore.collection('emergency_alerts').doc(alertId).set({
        'declinedBy': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Log SOS Response to local storage & Firestore
  Future<void> logSosResponse({
    required String victimName,
    required String location,
    required String duration,
    int earnedAmount = 500,
    String? paymentId,
  }) async {
    final history = await _storage.getVolunteerHistory();
    final txnId = paymentId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}';

    final entry = {
      'id': 'RESP_${DateTime.now().millisecondsSinceEpoch}',
      'victimName': victimName,
      'location': location,
      'duration': duration,
      'date': 'Today, ${_formatTime(DateTime.now())}',
      'status': 'Completed',
      'amount': earnedAmount,
      'paymentId': txnId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.insert(0, entry);
    await _storage.saveVolunteerHistory(history);

    // Update transactions with victim name and status
    final txns = await _storage.getEarningsTransactions();
    final existingIndex = txns.indexWhere((t) => t['paymentId'] == txnId || t['id'] == txnId);
    if (existingIndex >= 0) {
      txns[existingIndex]['victimName'] = victimName;
      txns[existingIndex]['title'] = 'Emergency Protection - $victimName';
      txns[existingIndex]['status'] = 'Settled & Verified';
    } else {
      txns.insert(0, {
        'id': txnId,
        'title': 'Emergency Protection - $victimName',
        'victimName': victimName,
        'date': 'Today, ${_formatTime(DateTime.now())}',
        'amount': earnedAmount,
        'status': 'Settled & Verified',
        'paymentId': txnId,
        'type': 'credit',
      });
      // Also ensure earnings reflect this deal if not credited earlier
      final earnings = await _storage.getVolunteerEarnings();
      final currentTotal = (earnings['total'] as num?)?.toInt() ?? 0;
      earnings['total'] = currentTotal + earnedAmount;
      await _storage.saveVolunteerEarnings(earnings);
    }
    await _storage.saveEarningsTransactions(txns);

    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('volunteers').doc(uid).collection('responses').add({
          'victimName': victimName,
          'location': location,
          'duration': duration,
          'status': 'Completed',
          'amount': earnedAmount,
          'paymentId': txnId,
          'completedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  /// Get Volunteer Earnings { 'total': 0, 'pending': 0 }
  Future<Map<String, dynamic>> getVolunteerEarnings() async {
    return await _storage.getVolunteerEarnings();
  }

  /// Settle Pending Earnings to Total Earnings
  Future<Map<String, dynamic>> settlePendingEarnings() async {
    final earnings = await _storage.getVolunteerEarnings();
    final total = (earnings['total'] as num?)?.toInt() ?? 0;
    final pending = (earnings['pending'] as num?)?.toInt() ?? 0;

    if (pending > 0) {
      earnings['total'] = total + pending;
      earnings['pending'] = 0;
      await _storage.saveVolunteerEarnings(earnings);

      // Update transactions
      final txns = await _storage.getEarningsTransactions();
      for (var txn in txns) {
        if (txn['status'] == 'Pending Verification') {
          txn['status'] = 'Settled & Verified';
        }
      }
      await _storage.saveEarningsTransactions(txns);
    }
    return earnings;
  }

  /// Get Earnings Transactions
  Future<List<Map<String, dynamic>>> getEarningsTransactions() async {
    return await _storage.getEarningsTransactions();
  }

  /// Update Volunteer Profile Details
  Future<bool> updateVolunteerProfile({
    required String name,
    required String phone,
    required String institution,
    required String affiliation,
  }) async {
    final updates = {
      'name': name.trim(),
      'fullName': name.trim(),
      'phone': phone.trim(),
      'institution': institution.trim(),
      'affiliation': affiliation.trim(),
    };

    if (_currentVolunteer != null) {
      _currentVolunteer!.addAll(updates);
      await _storage.saveVolunteerData(_currentVolunteer!);
    }

    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;
    if (uid != null) {
      try {
        final firestoreUpdates = Map<String, dynamic>.from(updates);
        firestoreUpdates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('volunteers').doc(uid).set(
          firestoreUpdates,
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
    return true;
  }

  /// Update volunteer live coordinates
  Future<void> updateVolunteerLocation({
    required double latitude,
    required double longitude,
    String? area,
  }) async {
    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('volunteers').doc(uid).set({
          'currentLocation': {
            'latitude': latitude,
            'longitude': longitude,
            'area': area ?? 'Mumbai',
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
