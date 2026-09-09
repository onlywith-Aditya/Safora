import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _keyUser = 'safora_user_data';
  static const String _keyVolunteer = 'safora_volunteer_data';
  static const String _keyRole = 'safora_user_role';
  static const String _keyIsLoggedIn = 'safora_is_logged_in';
  static const String _keyVolunteerDuty = 'safora_volunteer_duty';
  static const String _keyVolunteerHistory = 'safora_volunteer_history';

  // In-memory fallback cache
  final Map<String, dynamic> _memoryCache = {};

  /// Save Regular User Data to Device
  Future<void> saveUserData(Map<String, dynamic> data) async {
    _memoryCache[_keyUser] = data;
    _memoryCache[_keyRole] = 'user';
    _memoryCache[_keyIsLoggedIn] = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(data));
      await prefs.setString(_keyRole, 'user');
      await prefs.setBool(_keyIsLoggedIn, true);
    } catch (_) {
      // Local storage fallback
    }
  }

  /// Get Regular User Data from Device
  Future<Map<String, dynamic>?> getUserData() async {
    if (_memoryCache.containsKey(_keyUser)) {
      return Map<String, dynamic>.from(_memoryCache[_keyUser] as Map);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_keyUser);
      if (userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        _memoryCache[_keyUser] = decoded;
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Save Volunteer Data to Device
  Future<void> saveVolunteerData(Map<String, dynamic> data) async {
    _memoryCache[_keyVolunteer] = data;
    _memoryCache[_keyRole] = 'volunteer';
    _memoryCache[_keyIsLoggedIn] = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyVolunteer, jsonEncode(data));
      await prefs.setString(_keyRole, 'volunteer');
      await prefs.setBool(_keyIsLoggedIn, true);
    } catch (_) {
      // Local storage fallback
    }
  }

  /// Get Volunteer Data from Device
  Future<Map<String, dynamic>?> getVolunteerData() async {
    if (_memoryCache.containsKey(_keyVolunteer)) {
      return Map<String, dynamic>.from(_memoryCache[_keyVolunteer] as Map);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final volJson = prefs.getString(_keyVolunteer);
      if (volJson != null) {
        final decoded = jsonDecode(volJson) as Map<String, dynamic>;
        _memoryCache[_keyVolunteer] = decoded;
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Save Duty Status on Device
  Future<void> setVolunteerDuty(bool isOnDuty) async {
    _memoryCache[_keyVolunteerDuty] = isOnDuty;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVolunteerDuty, isOnDuty);
    } catch (_) {}
  }

  /// Get Duty Status from Device
  Future<bool> getVolunteerDuty() async {
    if (_memoryCache.containsKey(_keyVolunteerDuty)) {
      return _memoryCache[_keyVolunteerDuty] as bool;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final duty = prefs.getBool(_keyVolunteerDuty) ?? false;
      _memoryCache[_keyVolunteerDuty] = duty;
      return duty;
    } catch (_) {
      return false;
    }
  }

  /// Save Volunteer History List
  Future<void> saveVolunteerHistory(List<Map<String, dynamic>> history) async {
    _memoryCache[_keyVolunteerHistory] = history;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyVolunteerHistory, jsonEncode(history));
    } catch (_) {}
  }

  /// Get Volunteer History List
  Future<List<Map<String, dynamic>>> getVolunteerHistory() async {
    if (_memoryCache.containsKey(_keyVolunteerHistory)) {
      final list = _memoryCache[_keyVolunteerHistory] as List;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyVolunteerHistory);
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as List;
        final list = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _memoryCache[_keyVolunteerHistory] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  static const String _keyActiveEmergency = 'safora_active_emergency';

  /// Save Active Emergency Alert
  Future<void> saveActiveEmergency(Map<String, dynamic> emergencyData) async {
    _memoryCache[_keyActiveEmergency] = emergencyData;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveEmergency, jsonEncode(emergencyData));
    } catch (_) {}
  }

  /// Get Active Emergency Alert
  Future<Map<String, dynamic>?> getActiveEmergency() async {
    if (_memoryCache.containsKey(_keyActiveEmergency)) {
      return Map<String, dynamic>.from(_memoryCache[_keyActiveEmergency] as Map);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final emergencyJson = prefs.getString(_keyActiveEmergency);
      if (emergencyJson != null) {
        final decoded = jsonDecode(emergencyJson) as Map<String, dynamic>;
        _memoryCache[_keyActiveEmergency] = decoded;
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  static const String _keyVolunteerEarnings = 'safora_volunteer_earnings';
  static const String _keyEarningsTransactions = 'safora_earnings_transactions';

  /// Save Volunteer Earnings Map { 'total': 3500, 'pending': 500 }
  Future<void> saveVolunteerEarnings(Map<String, dynamic> earnings) async {
    _memoryCache[_keyVolunteerEarnings] = earnings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyVolunteerEarnings, jsonEncode(earnings));
    } catch (_) {}
  }

  /// Get Volunteer Earnings Map
  Future<Map<String, dynamic>> getVolunteerEarnings() async {
    if (_memoryCache.containsKey(_keyVolunteerEarnings)) {
      return Map<String, dynamic>.from(_memoryCache[_keyVolunteerEarnings] as Map);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final earningsJson = prefs.getString(_keyVolunteerEarnings);
      if (earningsJson != null) {
        final decoded = jsonDecode(earningsJson) as Map<String, dynamic>;
        _memoryCache[_keyVolunteerEarnings] = decoded;
        return decoded;
      }
    } catch (_) {}
    return {'total': 3500, 'pending': 0};
  }

  /// Save Earnings Transactions List
  Future<void> saveEarningsTransactions(List<Map<String, dynamic>> txns) async {
    _memoryCache[_keyEarningsTransactions] = txns;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEarningsTransactions, jsonEncode(txns));
    } catch (_) {}
  }

  /// Get Earnings Transactions List
  Future<List<Map<String, dynamic>>> getEarningsTransactions() async {
    if (_memoryCache.containsKey(_keyEarningsTransactions)) {
      final list = _memoryCache[_keyEarningsTransactions] as List;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final txnsJson = prefs.getString(_keyEarningsTransactions);
      if (txnsJson != null) {
        final decoded = jsonDecode(txnsJson) as List;
        final list = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _memoryCache[_keyEarningsTransactions] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Clear all saved data on Device
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }
}


