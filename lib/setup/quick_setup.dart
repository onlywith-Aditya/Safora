// 1. Create a simple setup file
// lib/setup/quick_setup.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuickSetup {
  static Future<void> run() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Create Admin
    try {
      final adminCred = await auth.createUserWithEmailAndPassword(
        email: 'admin@safeguard.ai',
        password: 'Admin@123',
      );
      
      await firestore.collection('admins').doc(adminCred.user!.uid).set({
        'name': 'Admin',
        'email': 'admin@safeguard.ai',
        'role': 'admin',
        'isActive': true,
      });
      print('✅ Admin created');
    } catch (e) {
      print('Admin exists');
    }
    
    // Create Test User
    try {
      final userCred = await auth.createUserWithEmailAndPassword(
        email: 'user@test.com',
        password: 'test123',
      );
      
      await firestore.collection('users').doc(userCred.user!.uid).set({
        'fullName': 'Test User',
        'email': 'user@test.com',
        'phone': '+919876543210',
        'role': 'user',
        'isActive': true,
      });
      print('✅ Test user created');
    } catch (e) {
      print('User exists');
    }
    
    print('✅ Database setup complete!');
  }
}