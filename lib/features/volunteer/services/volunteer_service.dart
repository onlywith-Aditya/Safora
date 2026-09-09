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
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user != null) {
        Map<String, dynamic>? volunteerDoc;

        // 1. Try fetching document by UID from volunteers collection
        try {
          final doc = await _firestore.collection('volunteers').doc(user.uid).get();
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
                .get();
            if (query.docs.isNotEmpty) {
              volunteerDoc = Map<String, dynamic>.from(query.docs.first.data());
              volunteerDoc['uid'] = query.docs.first.id;
            }
          } catch (e) {
            debugPrint('Firestore query by email failed: $e');
          }
        }

        // 3. If found in Firestore, save to local storage
        if (volunteerDoc != null) {
          _currentVolunteer = volunteerDoc;
          await _storage.saveVolunteerData(volunteerDoc);

          try {
            await _firestore.collection('volunteers').doc(volunteerDoc['uid']).set(
              {'lastLoginAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true),
            );
          } catch (_) {}

          return AuthResult(isSuccess: true);
        }

        // 4. If doc is missing from Firestore, check device local storage
        final localData = await _storage.getVolunteerData();
        if (localData != null && (localData['email'] == cleanEmail || localData['uid'] == user.uid)) {
          _currentVolunteer = localData;
          return AuthResult(isSuccess: true);
        }

        // 5. Default fallback profile for newly verified / imported volunteers
        final defaultVol = {
          'uid': user.uid,
          'fullName': cleanEmail.split('@').first,
          'name': cleanEmail.split('@').first,
          'email': cleanEmail,
          'phone': '+91 98765 43210',
          'idType': 'Aadhaar Card',
          'affiliation': 'College / Campus (NSS-NCC)',
          'institution': 'Safora Volunteer Network',
          'role': 'volunteer',
          'isVerified': true,
          'verificationStatus': 'approved',
          'dutyStatus': 'on_duty',
          'respondedCount': 14,
          'rating': 4.9,
          'coverageRadiusKm': 1.8,
          'currentLocation': {
            'latitude': 19.1136,
            'longitude': 72.8697,
            'area': 'Andheri West, Mumbai',
          },
        };

        _currentVolunteer = defaultVol;
        await _storage.saveVolunteerData(defaultVol);
        return AuthResult(isSuccess: true);
      }

      return AuthResult(isSuccess: false, errorMessage: 'Login failed', isUserNotFound: true);
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
      'respondedCount': 14,
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
    if (!forceRefresh) {
      final localData = await _storage.getVolunteerData();
      if (localData != null) {
        _currentVolunteer = localData;
        return localData;
      }
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('volunteers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          _currentVolunteer = Map<String, dynamic>.from(doc.data()!);
          _currentVolunteer!['uid'] = user.uid;
          await _storage.saveVolunteerData(_currentVolunteer!);
          return _currentVolunteer!;
        }

        // Query by email
        if (user.email != null && user.email!.isNotEmpty) {
          final query = await _firestore
              .collection('volunteers')
              .where('email', isEqualTo: user.email!.trim())
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            _currentVolunteer = Map<String, dynamic>.from(query.docs.first.data());
            _currentVolunteer!['uid'] = query.docs.first.id;
            await _storage.saveVolunteerData(_currentVolunteer!);
            return _currentVolunteer!;
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

    _currentVolunteer = {
      'uid': user?.uid ?? 'vol_mock_101',
      'fullName': 'Aarav Sharma',
      'name': 'Aarav Sharma',
      'email': user?.email ?? 'aarav.sharma@nss.org',
      'phone': '+91 98201 12345',
      'idType': 'Aadhaar Card',
      'affiliation': 'College / Campus (NSS-NCC)',
      'institution': 'St. Xavier\'s College, Mumbai',
      'role': 'volunteer',
      'isVerified': true,
      'verificationStatus': 'approved',
      'dutyStatus': 'on_duty',
      'respondedCount': 14,
      'rating': 4.9,
      'coverageRadiusKm': 1.8,
      'currentLocation': {
        'latitude': 19.1136,
        'longitude': 72.8697,
        'area': 'Andheri West, Mumbai',
      },
    };
    await _storage.saveVolunteerData(_currentVolunteer!);
    return _currentVolunteer!;
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
    try {
      return _firestore
          .collection('emergency_alerts')
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Accept SOS Alert
  Future<bool> acceptSosAlert(String alertId, {int earningAmount = 500, String? paymentId}) async {
    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid ?? 'vol_mock';
    final name = _currentVolunteer?['fullName'] ?? 'Aarav Sharma';
    final phone = _currentVolunteer?['phone'] ?? '+91 98201 12345';

    try {
      await _firestore.collection('emergency_alerts').doc(alertId).set({
        'status': 'accepted',
        'acceptedBy': {
          'volunteerId': uid,
          'volunteerName': name,
          'volunteerPhone': phone,
          'acceptedAt': FieldValue.serverTimestamp(),
          'earningAmount': earningAmount,
          'paymentId': paymentId ?? 'PAY_SAFE_${DateTime.now().millisecondsSinceEpoch}',
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

    // Update Earnings (Step 5: Earn Money)
    final earnings = await _storage.getVolunteerEarnings();
    final currentPending = (earnings['pending'] as num?)?.toInt() ?? 0;
    earnings['pending'] = currentPending + earnedAmount;
    await _storage.saveVolunteerEarnings(earnings);

    // Add to transaction log
    final txns = await _storage.getEarningsTransactions();
    txns.insert(0, {
      'id': txnId,
      'title': 'Emergency Protection Response',
      'victimName': victimName,
      'date': 'Today, ${_formatTime(DateTime.now())}',
      'amount': earnedAmount,
      'status': 'Pending Verification',
      'paymentId': txnId,
      'type': 'credit',
    });
    await _storage.saveEarningsTransactions(txns);

    // Increment responded count in volunteer profile
    if (_currentVolunteer != null) {
      final count = (_currentVolunteer!['respondedCount'] ?? 14) as int;
      _currentVolunteer!['respondedCount'] = count + 1;
      await _storage.saveVolunteerData(_currentVolunteer!);
    }

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

  /// Get Volunteer Earnings { 'total': 3500, 'pending': 500 }
  Future<Map<String, dynamic>> getVolunteerEarnings() async {
    return await _storage.getVolunteerEarnings();
  }

  /// Settle Pending Earnings to Total Earnings
  Future<Map<String, dynamic>> settlePendingEarnings() async {
    final earnings = await _storage.getVolunteerEarnings();
    final total = (earnings['total'] as num?)?.toInt() ?? 3500;
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
    final txns = await _storage.getEarningsTransactions();
    if (txns.isEmpty) {
      // Default initial mock transactions
      return [
        {
          'id': 'TXN_982310',
          'title': 'Volunteer Protection Assistance',
          'victimName': 'Pooja Deshmukh',
          'date': 'Yesterday, 9:42 PM',
          'amount': 500,
          'status': 'Settled & Verified',
          'paymentId': 'PAY_SAF_883921',
          'type': 'credit',
        },
        {
          'id': 'TXN_982104',
          'title': 'Priority Protection Escort',
          'victimName': 'Ananya Verma',
          'date': '3 Sep, 11:15 PM',
          'amount': 1000,
          'status': 'Settled & Verified',
          'paymentId': 'PAY_SAF_774102',
          'type': 'credit',
        },
        {
          'id': 'TXN_981902',
          'title': 'Volunteer Protection Assistance',
          'victimName': 'Ritu Sharma',
          'date': '28 Aug, 8:20 PM',
          'amount': 500,
          'status': 'Settled & Verified',
          'paymentId': 'PAY_SAF_663201',
          'type': 'credit',
        },
        {
          'id': 'TXN_981540',
          'title': 'Priority Protection Escort',
          'victimName': 'Meera Patel',
          'date': '22 Aug, 10:05 PM',
          'amount': 1000,
          'status': 'Settled & Verified',
          'paymentId': 'PAY_SAF_552190',
          'type': 'credit',
        },
        {
          'id': 'TXN_981200',
          'title': 'Volunteer Protection Assistance',
          'victimName': 'Neha Gupta',
          'date': '15 Aug, 7:50 PM',
          'amount': 500,
          'status': 'Settled & Verified',
          'paymentId': 'PAY_SAF_441029',
          'type': 'credit',
        },
      ];
    }
    return txns;
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
