import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DashboardPreferencesService {
  // Stream controller for broadcasting dashboard preference changes
  static final StreamController<DashboardChangeEvent> _changeController = 
      StreamController<DashboardChangeEvent>.broadcast();
  
  /// Stream that emits events when dashboard preferences change
  static Stream<DashboardChangeEvent> get changeStream => _changeController.stream;
  
  // Hive box and key constants
  static const String _boxName = 'dashboard_preferences';
  static const String _dashboardTypesKey = 'dashboard_payment_types';
  static const String _hasCustomizedKey = 'dashboard_has_customized';
  static const String _migrationCompletedKey = 'migration_completed';
  static const String _userContextKey = 'user_context';

  // Default payment types - easily configurable
  static const List<String> defaultPaymentTypes = [
    'SPP',
    'SWP',
    'Pendaftaran Mahasiswa Baru',
    'Praktek Rumah Sakit',
    'Seragam',
    'Wisuda',
    'KTI dan Wisuda',
  ];

  /// Get the Hive box instance
  Box get _box => Hive.box(_boxName);

  /// Check and perform migration from SharedPreferences to Hive
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final migrationCompleted = _box.get(_migrationCompletedKey, defaultValue: false);
      if (migrationCompleted) {
        return; // Migration already completed
      }

      print('🔄 Starting migration from SharedPreferences to Hive...');
      final prefs = await SharedPreferences.getInstance();
      
      // Migrate dashboard types
      final oldDashboardTypes = prefs.getStringList(_dashboardTypesKey);
      if (oldDashboardTypes != null) {
        await _box.put(_dashboardTypesKey, oldDashboardTypes);
        print('✅ Migrated dashboard types: $oldDashboardTypes');
      }
      
      // Migrate customization flag
      final oldHasCustomized = prefs.getBool(_hasCustomizedKey);
      if (oldHasCustomized != null) {
        await _box.put(_hasCustomizedKey, oldHasCustomized);
        print('✅ Migrated customization flag: $oldHasCustomized');
      }
      
      // Mark migration as completed
      await _box.put(_migrationCompletedKey, true);
      
      // Clean up old SharedPreferences keys
      await prefs.remove(_dashboardTypesKey);
      await prefs.remove(_hasCustomizedKey);
      
      print('✅ Migration from SharedPreferences to Hive completed successfully');
    } catch (e) {
      print('❌ Error during migration: $e');
      // Mark migration as completed even on error to prevent infinite retry
      await _box.put(_migrationCompletedKey, true);
    }
  }

  /// Get current user context for user isolation
  String get _currentUserContext => _box.get(_userContextKey, defaultValue: 'default');

  /// Set current user context for user isolation
  Future<void> setUserContext(String userContext) async {
    await _box.put(_userContextKey, userContext);
  }

  /// Build user-specific key
  String _getUserKey(String baseKey) => '${_currentUserContext}_$baseKey';

  /// Get user's selected payment types for dashboard
  /// Returns default types if not customized yet
  Future<List<String>> getSelectedPaymentTypes() async {
    try {
      // Ensure migration is complete
      await _migrateFromSharedPreferences();
      
      final userKey = _getUserKey(_dashboardTypesKey);
      final hasCustomizedKey = _getUserKey(_hasCustomizedKey);
      
      final hasCustomized = _box.get(hasCustomizedKey, defaultValue: false);

      if (!hasCustomized) {
        // Return default types for new users
        return List<String>.from(defaultPaymentTypes);
      }

      final selectedTypes = _box.get(userKey);
      if (selectedTypes is List) {
        return List<String>.from(selectedTypes);
      }
      
      return List<String>.from(defaultPaymentTypes);
    } catch (e) {
      print('❌ Error getting selected payment types: $e');
      // Fallback to defaults on error
      return List<String>.from(defaultPaymentTypes);
    }
  }

  /// Save user's selected payment types for dashboard
  Future<bool> saveSelectedPaymentTypes(List<String> paymentTypes) async {
    try {
      await _migrateFromSharedPreferences();
      
      final userKey = _getUserKey(_dashboardTypesKey);
      final hasCustomizedKey = _getUserKey(_hasCustomizedKey);
      
      // Atomic write operations
      await _box.put(userKey, paymentTypes);
      await _box.put(hasCustomizedKey, true);
      
      // Notify all listeners about the dashboard change
      _changeController.add(DashboardChangeEvent(
        changeType: DashboardChangeType.paymentTypesUpdated,
        newPaymentTypes: paymentTypes,
        timestamp: DateTime.now(),
      ));
      
      print('✅ Saved payment types for user ${_currentUserContext}: $paymentTypes');
      return true;
    } catch (e) {
      print('❌ Error saving payment types: $e');
      return false;
    }
  }

  /// Check if user has customized their dashboard
  Future<bool> hasUserCustomized() async {
    try {
      await _migrateFromSharedPreferences();
      
      final hasCustomizedKey = _getUserKey(_hasCustomizedKey);
      return _box.get(hasCustomizedKey, defaultValue: false);
    } catch (e) {
      print('❌ Error checking user customization: $e');
      return false;
    }
  }

  /// Reset to default settings
  Future<bool> resetToDefault() async {
    try {
      await _migrateFromSharedPreferences();
      
      final userKey = _getUserKey(_dashboardTypesKey);
      final hasCustomizedKey = _getUserKey(_hasCustomizedKey);
      
      // Atomic delete operations
      await _box.delete(userKey);
      await _box.put(hasCustomizedKey, false);
      
      // Notify about reset to defaults
      _changeController.add(DashboardChangeEvent(
        changeType: DashboardChangeType.resetToDefault,
        newPaymentTypes: defaultPaymentTypes,
        timestamp: DateTime.now(),
      ));
      
      print('✅ Reset to default for user ${_currentUserContext}');
      return true;
    } catch (e) {
      print('❌ Error resetting to default: $e');
      return false;
    }
  }
  
  /// Clear all dashboard preferences for current user (used on logout)
  Future<bool> clearPreferences() async {
    try {
      final userKey = _getUserKey(_dashboardTypesKey);
      final hasCustomizedKey = _getUserKey(_hasCustomizedKey);
      
      // Atomic delete operations for current user only
      await _box.delete(userKey);
      await _box.delete(hasCustomizedKey);
      
      // Notify about preferences cleared
      _changeController.add(DashboardChangeEvent(
        changeType: DashboardChangeType.resetToDefault,
        newPaymentTypes: defaultPaymentTypes,
        timestamp: DateTime.now(),
      ));
      
      print('✅ Cleared preferences for user ${_currentUserContext}');
      return true;
    } catch (e) {
      print('❌ Error clearing preferences: $e');
      return false;
    }
  }

  /// Clear all data for all users (used for complete reset)
  Future<bool> clearAllUserData() async {
    try {
      await _box.clear();
      print('✅ Cleared all user data from Hive');
      return true;
    } catch (e) {
      print('❌ Error clearing all user data: $e');
      return false;
    }
  }
  
  /// Clean up resources when app terminates
  static Future<void> dispose() async {
    _changeController.close();
    try {
      await Hive.box(_boxName).close();
    } catch (e) {
      print('❌ Error closing Hive box: $e');
    }
  }
}

/// Event types for dashboard changes
enum DashboardChangeType {
  paymentTypesUpdated,
  resetToDefault,
}

/// Event fired when dashboard preferences change
class DashboardChangeEvent {
  final DashboardChangeType changeType;
  final List<String> newPaymentTypes;
  final DateTime timestamp;
  
  const DashboardChangeEvent({
    required this.changeType,
    required this.newPaymentTypes,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'DashboardChangeEvent{type: $changeType, paymentTypes: $newPaymentTypes, time: $timestamp}';
  }
}
