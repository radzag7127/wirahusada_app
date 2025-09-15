import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Performance utility functions for handling heavy operations
class PerformanceUtils {
  // Threshold for using isolates (1KB)
  static const int _isolateThreshold = 1024;
  
  /// Decode JSON using isolates for large responses to prevent main thread blocking
  static Future<Map<String, dynamic>> decodeJsonAsync(String jsonString) async {
    // For small responses, use main thread to avoid isolate overhead
    if (jsonString.length < _isolateThreshold) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    
    // For large responses, use isolate to prevent UI blocking
    return await compute(_parseJsonInIsolate, jsonString);
  }
  
  /// Decode JSON list using isolates for large responses
  static Future<List<dynamic>> decodeJsonListAsync(String jsonString) async {
    // For small responses, use main thread to avoid isolate overhead
    if (jsonString.length < _isolateThreshold) {
      return jsonDecode(jsonString) as List<dynamic>;
    }
    
    // For large responses, use isolate to prevent UI blocking
    return await compute(_parseJsonListInIsolate, jsonString);
  }
  
  /// Parse JSON in isolate - static function required for compute()
  static Map<String, dynamic> _parseJsonInIsolate(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  
  /// Parse JSON list in isolate - static function required for compute()
  static List<dynamic> _parseJsonListInIsolate(String jsonString) {
    return jsonDecode(jsonString) as List<dynamic>;
  }
  
  /// Check if response is large enough to warrant isolate processing
  static bool shouldUseIsolate(String data) {
    return data.length >= _isolateThreshold;
  }
  
  /// Batch process multiple API calls in parallel
  static Future<List<T>> batchApiCalls<T>(
    List<Future<T> Function()> apiCalls, {
    int maxConcurrency = 3,
  }) async {
    final results = <T>[];
    
    // Process in batches to avoid overwhelming the system
    for (int i = 0; i < apiCalls.length; i += maxConcurrency) {
      final batch = apiCalls
          .skip(i)
          .take(maxConcurrency)
          .map((call) => call())
          .toList();
      
      final batchResults = await Future.wait(batch);
      results.addAll(batchResults);
    }
    
    return results;
  }
  
  /// Execute futures in parallel with error handling
  static Future<Map<String, dynamic>> executeParallel<T>({
    required Map<String, Future<T> Function()> futures,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final results = <String, dynamic>{};
    final errors = <String, dynamic>{};
    
    try {
      // Execute all futures in parallel
      final Map<String, Future<T>> pendingFutures = 
          futures.map((key, futureFunc) => MapEntry(key, futureFunc()));
      
      // Wait for all with timeout
      final completedFutures = await Future.wait(
        pendingFutures.entries.map((entry) async {
          try {
            final result = await entry.value.timeout(timeout);
            return MapEntry(entry.key, {'success': true, 'data': result});
          } catch (e) {
            return MapEntry(entry.key, {'success': false, 'error': e.toString()});
          }
        }),
      );
      
      // Separate successful results from errors
      for (final entry in completedFutures) {
        if (entry.value['success'] == true) {
          results[entry.key] = entry.value['data'];
        } else {
          errors[entry.key] = entry.value['error'];
        }
      }
      
      return {
        'results': results,
        'errors': errors,
        'hasErrors': errors.isNotEmpty,
      };
    } catch (e) {
      throw Exception('Batch execution failed: ${e.toString()}');
    }
  }
  
  /// Debounce function calls to prevent excessive API requests
  static VoidCallback debounce(
    VoidCallback func,
    Duration delay,
  ) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, func);
    };
  }
}