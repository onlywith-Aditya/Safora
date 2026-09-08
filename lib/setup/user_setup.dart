// lib/features/auth/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? age,
    String? bloodGroup,
    String? address,
    required List<Map<String, String>> emergencyContacts,
  }) async {
    try {
      // Step 1: Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = userCredential.user;
      
      if (user != null) {
        // Step 2: Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          // Personal Information
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'age': age ?? '',
          'bloodGroup': bloodGroup ?? '',
          'address': address ?? '',
          
          // Account Information
          'role': 'user',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          
          // Emergency Contacts
          'emergencyContacts': emergencyContacts,
          
          // App Settings (Default)
          'settings': {
            'voiceDetection': true,
            'screamDetection': true,
            'fakeCallEnabled': true,
            'locationTracking': true,
            'smsAlerts': true,
            'whatsappAlerts': true,
            'locationUpdateInterval': 10,
          },
          
          // Safety Statistics
          'safetyStats': {
            'totalSOS': 0,
            'totalFakeCalls': 0,
            'totalSafeRoutes': 0,
          },
        });
        
        return {
          'success': true,
          'message': 'User registered successfully',
          'userId': user.uid,
        };
      }
      
      return {
        'success': false,
        'message': 'User creation failed',
      };
      
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _handleAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = userCredential.user;
      
      if (user != null) {
        // Update last login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        
        // Get user data
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        return {
          'success': true,
          'userId': user.uid,
          'userData': userDoc.data(),
        };
      }
      
      return {
        'success': false,
        'message': 'Login failed',
      };
      
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _handleAuthError(e),
      };
    }
  }
  
  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  
  // Update user location
  Future<void> updateUserLocation({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'currentLocation': {
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? age,
    String? bloodGroup,
    String? address,
  }) async {
    Map<String, dynamic> updates = {};
    
    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (age != null) updates['age'] = age;
    if (bloodGroup != null) updates['bloodGroup'] = bloodGroup;
    if (address != null) updates['address'] = address;
    
    updates['updatedAt'] = FieldValue.serverTimestamp();
    
    await _firestore.collection('users').doc(userId).update(updates);
  }
  
  // Add emergency contact
  Future<void> addEmergencyContact({
    required String userId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'emergencyContacts': FieldValue.arrayUnion([
        {
          'name': name,
          'phone': phone,
          'relation': relation,
          'isPrimary': false,
        }
      ]),
    });
  }
  
  // Delete emergency contact
  Future<void> deleteEmergencyContact({
    required String userId,
    required Map<String, dynamic> contact,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'emergencyContacts': FieldValue.arrayRemove([contact]),
    });
  }
  
  // Handle auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already registered. Please login.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Minimum 6 characters.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      default:
        return 'Error: ${e.message}';
    }
  }
}