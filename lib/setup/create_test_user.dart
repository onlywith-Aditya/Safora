// lib/setup/create_test_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTestUser {
  static Future<void> create() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    print('Creating test user...');
    
    try {
      // Create in Auth
      UserCredential userCred = await auth.createUserWithEmailAndPassword(
        email: 'priya@test.com',
        password: 'priya123',
      );
      
      String userId = userCred.user!.uid;
      print('✅ Auth created: $userId');
      
      // Create in Firestore
      await firestore.collection('users').doc(userId).set({
        'fullName': 'Priya Sharma',
        'email': 'priya@test.com',
        'phone': '+919876543210',
        'age': '24',
        'bloodGroup': 'O+',
        'address': 'Andheri West, Mumbai',
        'role': 'user',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'emergencyContacts': [
          {
            'name': 'Rajesh Sharma',
            'phone': '+919876543211',
            'relation': 'Father',
            'isPrimary': true
          },
          {
            'name': 'Anita Desai',
            'phone': '+919876543212',
            'relation': 'Friend',
            'isPrimary': false
          }
        ],
        'settings': {
          'voiceDetection': true,
          'screamDetection': true,
          'fakeCallEnabled': true,
          'locationTracking': true,
          'smsAlerts': true,
          'locationUpdateInterval': 10,
        },
        'safetyStats': {
          'totalSOS': 0,
          'totalFakeCalls': 0,
          'totalSafeRoutes': 0,
        }
      });
      
      print('✅ User document created in Firestore');
      print('📋 Login Credentials:');
      print('   Email: priya@test.com');
      print('   Password: priya123');
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}