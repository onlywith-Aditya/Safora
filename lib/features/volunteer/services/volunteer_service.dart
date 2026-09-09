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
          'affiliation': 'Community Guardian',
          'institution': 'Safora Network',
          'role': 'volunteer',
          'isVerified': true,
          'verificationStatus': 'approved',
          'dutyStatus': 'off_duty',
          'respondedCount': 14,
          'rating': 4.9,
          'coverageRadiusKm': 1.8,
          'createdAt': DateTime.now().toIso8601String(),
        };
        _currentVolunteer = defaultVol;
        await _storage.saveVolunteerData(defaultVol);

        try {
          await _firestore.collection('volunteers').doc(user.uid).set(
            defaultVol,
            SetOptions(merge: true),
          );
        } catch (_) {}

        return AuthResult(isSuccess: true);
      }

      return AuthResult(isSuccess: false, errorMessage: 'Volunteer login failed', isUserNotFound: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'No volunteer account found with this email. Please register below.',
          isUserNotFound: true,
        );
      }
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Incorrect password. Please verify and try again.',
          isUserNotFound: true,
        );
      }
      return AuthResult(isSuccess: false, errorMessage: e.message ?? 'Login failed', isUserNotFound: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: 'Volunteer login error: $e', isUserNotFound: true);
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

  /// Load volunteer profile
  Future<Map<String, dynamic>> loadVolunteerProfile() async {
    final localData = await _storage.getVolunteerData();
    if (localData != null) {
      _currentVolunteer = localData;
      return localData;
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('volunteers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          _currentVolunteer = doc.data();
          await _storage.saveVolunteerData(_currentVolunteer!);
          return _currentVolunteer!;
        }
      } catch (_) {}
    }

    _currentVolunteer = {
      'uid': 'vol_demo_01',
      'fullName': 'Arjun Mehta',
      'name': 'Arjun Mehta',
      'email': 'arjun.volunteer@safora.app',
      'phone': '+91 98765 43210',
      'idType': 'Aadhaar Card',
      'idPhoto': 'govt_id_arjun.jpg',
      'affiliation': 'College / Campus (NSS-NCC)',
      'institution': "St. Xavier's College",
      'role': 'volunteer',
      'isVerified': true,
      'verificationStatus': 'approved',
      'dutyStatus': 'off_duty',
      'respondedCount': 14,
      'rating': 4.9,
      'coverageRadiusKm': 1.8,
    };
    await _storage.saveVolunteerData(_currentVolunteer!);
    return _currentVolunteer!;
  }

  /// Update Volunteer Profile Details
  Future<void> updateVolunteerProfile(Map<String, dynamic> updatedFields) async {
    if (_currentVolunteer == null) {
      await loadVolunteerProfile();
    }

    _currentVolunteer!.addAll(updatedFields);
    _currentVolunteer!['updatedAt'] = DateTime.now().toIso8601String();

    await _storage.saveVolunteerData(_currentVolunteer!);

    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;
    if (uid != null) {
      try {
        final data = Map<String, dynamic>.from(updatedFields);
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('volunteers').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  /// Update Duty Status
  Future<void> updateDutyStatus(bool isOnDuty) async {
    await _storage.setVolunteerDuty(isOnDuty);

    if (_currentVolunteer != null) {
      _currentVolunteer!['dutyStatus'] = isOnDuty ? 'on_duty' : 'off_duty';
      await _storage.saveVolunteerData(_currentVolunteer!);
    }

    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('volunteers').doc(uid).set(
          {
            'dutyStatus': isOnDuty ? 'on_duty' : 'off_duty',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  /// Stream of all active SOS alerts sent by females from user / emergency sections
  Stream<List<Map<String, dynamic>>> getActiveFemaleSosAlertsStream() {
    try {
      return _firestore
          .collection('sos_alerts')
          .orderBy('createdAt', descending: true)
          .limit(25)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return _getFallbackSosAlerts();
        }
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }).handleError((e) {
        debugPrint('SOS Alerts stream error: $e');
        return _getFallbackSosAlerts();
      });
    } catch (_) {
      return Stream.value(_getFallbackSosAlerts());
    }
  }

  List<Map<String, dynamic>> _getFallbackSosAlerts() {
    return [
      {
        'id': 'sos_demo_01',
        'userId': 'usr_sneha',
        'userName': 'Sneha Kapoor',
        'userPhone': '+91 98201 44521',
        'alertType': 'Manual SOS',
        'status': 'active',
        'severity': 'high',
        'location': {
          'address': 'Andheri West (Near Metro Pillar 42), Mumbai',
          'distance': '420m away',
          'eta': '3 mins',
        },
        'timeAgo': '2 min ago',
      },
      {
        'id': 'sos_demo_02',
        'userId': 'usr_priya',
        'userName': 'Priya Sharma',
        'userPhone': '+91 98765 43210',
        'alertType': 'One-Tap Emergency',
        'status': 'active',
        'severity': 'high',
        'location': {
          'address': 'DN Nagar Metro Station, Exit 2',
          'distance': '650m away',
          'eta': '5 mins',
        },
        'timeAgo': '5 min ago',
      },
      {
        'id': 'sos_demo_03',
        'userId': 'usr_ananya',
        'userName': 'Ananya Roy',
        'userPhone': '+91 91234 56789',
        'alertType': 'Safe Route Panic',
        'status': 'active',
        'severity': 'medium',
        'location': {
          'address': 'Lokhandwala Complex, 4th Cross',
          'distance': '890m away',
          'eta': '7 mins',
        },
        'timeAgo': '8 min ago',
      },
    ];
  }

  /// Accept an SOS Alert
  Future<void> acceptSosAlert(Map<String, dynamic> alert) async {
    final alertId = alert['id'] as String?;
    final volunteerName = _currentVolunteer?['name'] ?? 'Arjun Mehta';
    final volunteerUid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;

    if (alertId != null && !alertId.startsWith('sos_demo_')) {
      try {
        await _firestore.collection('sos_alerts').doc(alertId).update({
          'status': 'responding',
          'responderId': volunteerUid,
          'responderName': volunteerName,
          'respondedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  /// Get Volunteer History list (past accepted emergencies)
  Future<List<Map<String, dynamic>>> getVolunteerHistory() async {
    final localHistory = await _storage.getVolunteerHistory();
    if (localHistory.isNotEmpty) {
      return localHistory;
    }

    final defaultHistory = [
      {
        'id': 'res_01',
        'victimName': 'Sneha Kapoor',
        'location': 'Andheri West (Near Metro Pillar 42)',
        'alertType': 'Manual SOS',
        'responseTime': '3 mins',
        'status': 'Resolved',
        'timestamp': 'Today, 01:45 AM',
        'distance': '420m',
      },
      {
        'id': 'res_02',
        'victimName': 'Pooja Sharma',
        'location': 'DN Nagar Metro Station, Exit 2',
        'alertType': 'Emergency Trigger',
        'responseTime': '4 mins',
        'status': 'Resolved',
        'timestamp': 'Yesterday, 09:20 PM',
        'distance': '650m',
      },
      {
        'id': 'res_03',
        'victimName': 'Ananya Roy',
        'location': 'Lokhandwala Complex, 4th Cross',
        'alertType': 'Safe Walk Assistance',
        'responseTime': '2 mins',
        'status': 'Resolved',
        'timestamp': '05 Sep 2026, 11:15 PM',
        'distance': '310m',
      },
      {
        'id': 'res_04',
        'victimName': 'Riya Patel',
        'location': 'Versova Beach Link Road',
        'alertType': 'Manual SOS',
        'responseTime': '5 mins',
        'status': 'Resolved',
        'timestamp': '02 Sep 2026, 08:40 PM',
        'distance': '850m',
      },
    ];

    await _storage.saveVolunteerHistory(defaultHistory);
    return defaultHistory;
  }

  /// Log response to an SOS event in Firestore & increment stats & add to history
  Future<void> logSosResponse({required String victimName, required String location}) async {
    final currentCount = (_currentVolunteer?['respondedCount'] as int?) ?? 14;
    final newCount = currentCount + 1;

    if (_currentVolunteer != null) {
      _currentVolunteer!['respondedCount'] = newCount;
      await _storage.saveVolunteerData(_currentVolunteer!);
    }

    final history = await getVolunteerHistory();
    final newEntry = {
      'id': 'res_${DateTime.now().millisecondsSinceEpoch}',
      'victimName': victimName,
      'location': location,
      'alertType': 'Manual SOS',
      'responseTime': '3 mins',
      'status': 'Resolved',
      'timestamp': 'Just now',
      'distance': '420m',
    };
    final updatedHistory = [newEntry, ...history];
    await _storage.saveVolunteerHistory(updatedHistory);

    final uid = _currentVolunteer?['uid'] ?? _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('volunteers').doc(uid).set(
          {
            'respondedCount': newCount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _firestore.collection('volunteers').doc(uid).collection('responses').add({
          'victimName': victimName,
          'location': location,
          'status': 'resolved',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  /// Logout Volunteer
  Future<void> logoutVolunteer() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await _storage.clearAll();
    _currentVolunteer = null;
  }
}
