// lib/setup/create_collections.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateCollections {
  static Future<void> createAll() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    print('🚀 Creating collections...');
    
    // 1. Create Admin Document
    try {
      // Get admin UID
      UserCredential adminCred = await auth.signInWithEmailAndPassword(
        email: 'admin@safeguard.ai',
        password: 'Admin@123',
      );
      
      String adminId = adminCred.user!.uid;
      
      await firestore.collection('admins').doc(adminId).set({
        'name': 'Admin User',
        'email': 'admin@safeguard.ai',
        'phone': '+919999999999',
        'role': 'admin',
        'permissions': [
          'view_users',
          'view_alerts',
          'manage_alerts',
          'view_locations',
          'export_data'
        ],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'stats': {
          'totalAlertsResolved': 0,
          'totalUsersViewed': 0,
          'totalActions': 0
        }
      });
      print('✅ Admin document created: $adminId');
      
      // Sign out admin
      await auth.signOut();
      
    } catch (e) {
      print('❌ Admin creation error: $e');
    }
    
    // 2. Create Test User Document
    try {
      UserCredential userCred = await auth.signInWithEmailAndPassword(
        email: 'test@user.com',
        password: 'test123',
      );
      
      String userId = userCred.user!.uid;
      
      await firestore.collection('users').doc(userId).set({
        'fullName': 'Test User',
        'email': 'test@user.com',
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
          'whatsappAlerts': true,
          'locationUpdateInterval': 10
        },
        'safetyStats': {
          'totalSOS': 0,
          'totalFakeCalls': 0,
          'totalSafeRoutes': 0
        }
      });
      print('✅ User document created: $userId');
      
      await auth.signOut();
      
    } catch (e) {
      print('❌ User creation error: $e');
    }
    
    // 3. Create Safe Places Collection
    try {
      final safePlaces = [
        {
          'name': 'Andheri Police Station',
          'type': 'police_station',
          'address': 'Andheri West, Mumbai',
          'location': {'lat': 19.1197, 'lng': 72.8464},
          'phone': '+912226109500',
          'isOpen24x7': true,
          'verified': true,
          'safetyRating': 4.8,
          'totalReviews': 150,
          'createdAt': FieldValue.serverTimestamp()
        },
        {
          'name': 'Cooper Hospital',
          'type': 'hospital',
          'address': 'Juhu, Mumbai',
          'location': {'lat': 19.1075, 'lng': 72.8365},
          'phone': '+912226207254',
          'isOpen24x7': true,
          'verified': true,
          'safetyRating': 4.5,
          'totalReviews': 100,
          'createdAt': FieldValue.serverTimestamp()
        }
      ];
      
      for (var place in safePlaces) {
        await firestore.collection('safe_places').add(place);
      }
      print('✅ Safe places created: ${safePlaces.length}');
      
    } catch (e) {
      print('❌ Safe places error: $e');
    }
    
    // 4. Create Risk Zones Collection
    try {
      final riskZones = [
        {
          'name': 'Andheri Station Area',
          'riskLevel': 'high',
          'riskScore': 85,
          'area': {
            'center': {'lat': 19.1197, 'lng': 72.8464},
            'radius': 500
          },
          'factors': ['poor_lighting', 'high_crime_rate', 'crowded'],
          'incidents': 12,
          'createdAt': FieldValue.serverTimestamp()
        }
      ];
      
      for (var zone in riskZones) {
        await firestore.collection('risk_zones').add(zone);
      }
      print('✅ Risk zones created: ${riskZones.length}');
      
    } catch (e) {
      print('❌ Risk zones error: $e');
    }
    
    print('✅ ALL COLLECTIONS CREATED!');
  }
}