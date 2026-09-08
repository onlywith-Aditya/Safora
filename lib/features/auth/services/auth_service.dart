import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _storage = LocalStorageService();

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  User? get currentFirebaseUser => _auth.currentUser;

  /// Check if user is already signed in and restore session
  Future<bool> tryAutoLogin() async {
    // 1. Try local storage first
    final localUser = await _storage.getUserData();
    if (localUser != null) {
      _currentUser = localUser;
      return true;
    }

    final user = _auth.currentUser;
    if (user != null) {
      await fetchUserData(user.uid, email: user.email);
      return true;
    }
    return false;
  }

  /// Login with Email and Password using Firebase Auth
  Future<AuthResult> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user != null) {
        await fetchUserData(user.uid, email: user.email);
        return AuthResult(isSuccess: true);
      }
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Account not exist create account',
        isUserNotFound: true,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-email') {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Account not exist create account',
          isUserNotFound: true,
        );
      }
      return AuthResult(
        isSuccess: false,
        errorMessage: e.message ?? 'Account not exist create account',
        isUserNotFound: true,
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Account not exist create account',
        isUserNotFound: true,
      );
    }
  }

  /// Register new user with Firebase Auth and save details to Cloud Firestore & Local Storage
  Future<AuthResult> register(Map<String, dynamic> userData) async {
    final cleanEmail = (userData['email'] as String).trim();
    final cleanPassword = (userData['password'] as String).trim();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user != null) {
        // Save profile in Firestore
        final userProfileData = {
          'uid': user.uid,
          'name': userData['name'] ?? 'User',
          'email': cleanEmail,
          'phone': userData['phone'] ?? '',
          'age': userData['age'] ?? '',
          'bloodGroup': userData['bloodGroup'] ?? 'O+',
          'address': userData['address'] ?? '',
          'contacts': userData['contacts'] ?? [],
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Save to Local Device Storage
        await _storage.saveUserData(userProfileData);

        try {
          final firestoreData = Map<String, dynamic>.from(userProfileData);
          firestoreData['createdAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('users').doc(user.uid).set(
            firestoreData,
            SetOptions(merge: true),
          );
        } catch (_) {
          // If Firestore is offline/unconfigured, keep local profile
        }

        _currentUser = userProfileData;
        return AuthResult(isSuccess: true);
      }
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Registration failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: e.message ?? 'Registration failed',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetch user profile from Firestore or construct from Firebase User
  Future<void> fetchUserData(String uid, {String? email}) async {
    // 1. Try device storage
    final localData = await _storage.getUserData();
    if (localData != null) {
      _currentUser = localData;
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = doc.data();
        await _storage.saveUserData(_currentUser!);
        return;
      }
    } catch (_) {
      // Fallback if network or firestore rules block read
    }

    _currentUser = {
      'uid': uid,
      'name': _auth.currentUser?.displayName ?? (email?.split('@').first ?? 'Priya Sharma'),
      'email': email ?? _auth.currentUser?.email ?? 'user@safora.app',
      'phone': '+91 98765 43210',
      'bloodGroup': 'O+',
      'address': '402, Sunshine Apartments, Andheri West, Mumbai',
      'contacts': [
        {'name': 'Rajesh Sharma', 'phone': '+91 98765 43210', 'relation': 'Father'},
        {'name': 'Anita Verma', 'phone': '+91 91234 56744', 'relation': 'Sister'},
      ],
    };
    await _storage.saveUserData(_currentUser!);
  }

  /// Log out
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await _storage.clearAll();
    _currentUser = null;
  }
}
