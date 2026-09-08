import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Register Volunteer and save complete profile to 'volunteers' collection in Firestore & Device Storage
  /// Note: Data is saved ONLY here at the final submit stage, not on every input/button click.
  Future<AuthResult> registerVolunteer(Map<String, dynamic> volunteerData) async {
    final cleanEmail = (volunteerData['email'] as String).trim();
    final cleanPassword = (volunteerData['password'] as String).trim();

    String uid = 'vol_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Create Firebase Auth account if online
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
    } catch (_) {
      // Offline fallback
    }

    // 2. Prepare comprehensive Volunteer Document Data
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

    // 3. Save to Device Local Storage
    await _storage.saveVolunteerData(completeVolunteerProfile);
    _currentVolunteer = completeVolunteerProfile;

    // 4. Save to Cloud Firestore in separate 'volunteers' collection
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
  Future<Map<String, dynamic>> loadVolunteerProfile() async {
    // 1. Try local storage first (instant)
    final localData = await _storage.getVolunteerData();
    if (localData != null) {
      _currentVolunteer = localData;
      return localData;
    }

    // 2. Try Firestore if user is signed in
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

    // 3. Fallback default profile
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

    // 1. Update in local storage
    await _storage.saveVolunteerData(_currentVolunteer!);

    // 2. Update in Firestore
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

  /// Update Duty Status in Device Storage and Firestore
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

  /// Get Volunteer History list (past accepted emergencies)
  Future<List<Map<String, dynamic>>> getVolunteerHistory() async {
    final localHistory = await _storage.getVolunteerHistory();
    if (localHistory.isNotEmpty) {
      return localHistory;
    }

    // Default rich sample history
    final defaultHistory = [
      {
        'id': 'res_01',
        'victimName': 'Sneha K.',
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

    // Add entry to history
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

        // Add to responses sub-collection
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
