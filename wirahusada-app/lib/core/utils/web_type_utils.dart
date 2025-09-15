import 'package:flutter/foundation.dart';

/// Utilities for handling Flutter web type conversion issues
/// Specifically addresses JSArray to Dart List conversion problems
class WebTypeUtils {
  /// Safely converts any response data to the expected Dart types
  /// This handles Flutter web JSArray conversion issues
  static dynamic convertWebResponse(dynamic response) {
    if (!kIsWeb) {
      // On non-web platforms, return as-is
      return response;
    }

    // Handle JSArray conversion on Flutter web
    if (response == null) {
      return null;
    }

    // Convert JSArray to List for Flutter web
    if (response.runtimeType.toString().contains('JSArray')) {
      try {
        // Force conversion to List<dynamic>
        return List<dynamic>.from(response as Iterable);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [WebTypeUtils] Failed to convert JSArray: $e');
        }
        // Fallback: try to extract as iterable
        try {
          return List<dynamic>.from(response);
        } catch (e2) {
          if (kDebugMode) {
            print('❌ [WebTypeUtils] Complete JSArray conversion failed: $e2');
          }
          return [];
        }
      }
    }

    // Handle regular Dart types
    if (response is List) {
      // Ensure it's List<dynamic> for consistency
      return List<dynamic>.from(response);
    }

    if (response is Map) {
      // Ensure it's Map<String, dynamic> for consistency
      return Map<String, dynamic>.from(response);
    }

    // Return other types as-is
    return response;
  }

  /// Safely casts response to List<dynamic>
  /// Handles both direct arrays and wrapped responses
  static List<dynamic> safeListCast(dynamic response) {
    if (response == null) return [];

    // Convert web types first
    final converted = convertWebResponse(response);

    if (converted is List) {
      return List<dynamic>.from(converted);
    }

    // Handle wrapped response format
    if (converted is Map) {
      final map = converted as Map<String, dynamic>;

      // Check for wrapped success response
      if (map.containsKey('success') && map['success'] == true) {
        final data = map['data'];
        if (data is List) {
          return List<dynamic>.from(convertWebResponse(data));
        }
        // Handle nested data structure
        if (data is Map && (data as Map).containsKey('data')) {
          final nestedData = (data as Map)['data'];
          if (nestedData is List) {
            return List<dynamic>.from(convertWebResponse(nestedData));
          }
        }
      }
    }

    if (kDebugMode) {
      print('⚠️ [WebTypeUtils] Could not cast to List: ${response.runtimeType}');
    }
    return [];
  }

  /// Safely casts response to Map<String, dynamic>
  static Map<String, dynamic> safeMapCast(dynamic response) {
    if (response == null) return {};

    // Convert web types first
    final converted = convertWebResponse(response);

    if (converted is Map) {
      return Map<String, dynamic>.from(converted);
    }

    if (kDebugMode) {
      print('⚠️ [WebTypeUtils] Could not cast to Map: ${response.runtimeType}');
    }
    return {};
  }

  /// Checks if running on Flutter web
  static bool get isWeb => kIsWeb;

  /// Safely extracts array data from various response formats
  static List<dynamic> extractArrayData(dynamic response) {
    final converted = convertWebResponse(response);

    // Direct array response
    if (converted is List) {
      return List<dynamic>.from(converted);
    }

    // Wrapped response patterns
    if (converted is Map) {
      final map = converted as Map<String, dynamic>;

      // Pattern 1: { success: true, data: [...] }
      if (map.containsKey('success') && map['success'] == true) {
        final data = map['data'];
        if (data is List) {
          return List<dynamic>.from(convertWebResponse(data));
        }

        // Pattern 2: { success: true, data: { data: [...] } }
        if (data is Map && (data as Map).containsKey('data')) {
          final nestedData = (data as Map)['data'];
          if (nestedData is List) {
            return List<dynamic>.from(convertWebResponse(nestedData));
          }
        }
      }

      // Pattern 3: Direct data array in map
      if (map.containsKey('data') && map['data'] is List) {
        return List<dynamic>.from(convertWebResponse(map['data']));
      }
    }

    return [];
  }

  /// Safely extracts object data from response
  static Map<String, dynamic> extractObjectData(dynamic response) {
    final converted = convertWebResponse(response);

    // Direct object response
    if (converted is Map) {
      final map = converted as Map<String, dynamic>;

      // Check for error patterns first
      if (map.containsKey('success') && map['success'] == false) {
        // Don't extract data from error responses
        return map;
      }

      // If it has success wrapper, extract data
      if (map.containsKey('success') && map['success'] == true) {
        final data = map['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(convertWebResponse(data));
        }
      }

      // Return as-is if not wrapped
      return map;
    }

    return {};
  }

  /// Validates if response data contains valid collection structure
  static bool isValidCollectionData(dynamic data) {
    if (data == null) return false;

    final converted = convertWebResponse(data);
    if (converted is! Map) return false;

    final map = converted as Map<String, dynamic>;

    // Check for error patterns
    if (map.containsKey('success') && map['success'] == false) return false;
    if (map.containsKey('error')) return false;
    if (map.containsKey('message') && !map.containsKey('kode')) return false;

    // Check for required collection fields
    final requiredFields = ['kode', 'kategori', 'topik', 'judul', 'penulis'];
    for (final field in requiredFields) {
      if (!map.containsKey(field) || map[field] == null) return false;
    }

    return true;
  }

  /// Validates if response data contains valid collection array
  static bool isValidCollectionArray(dynamic data) {
    if (data == null) return false;

    final arrayData = extractArrayData(data);
    if (arrayData.isEmpty) return true; // Empty arrays are valid

    // Check if all items in array are valid collection data
    for (final item in arrayData) {
      if (!isValidCollectionData(item)) return false;
    }

    return true;
  }

  /// Debug helper to log type information
  static void debugLogType(String context, dynamic data) {
    if (!kDebugMode) return;

    print('🔍 [WebTypeUtils] $context:');
    print('  Type: ${data.runtimeType}');
    print('  Is List: ${data is List}');
    print('  Is Map: ${data is Map}');
    print('  Is JSArray: ${data.runtimeType.toString().contains('JSArray')}');

    if (data is List) {
      print('  List length: ${data.length}');
    } else if (data is Map) {
      print('  Map keys: ${(data as Map).keys.toList()}');
    }
  }
}